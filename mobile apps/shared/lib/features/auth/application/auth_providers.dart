import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(auth: ref.watch(firebaseAuthProvider), env: ref.watch(envProvider)),
);
final authStateProvider = StreamProvider<User?>((ref) => ref.watch(authRepositoryProvider).authStateChanges);
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).currentUser;
});

/// AppLinks includes both cold-start and subsequent links. Instantiate at bootstrap.
final incomingAuthLinksProvider = StreamProvider<Uri>((ref) => AppLinks().uriLinkStream);

class GoogleSignInController extends AsyncNotifier<void> {
  @override
  void build() {}
  Future<void> signIn() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).signInWithGoogle());
  }
}

final googleSignInProvider = AsyncNotifierProvider<GoogleSignInController, void>(GoogleSignInController.new);

class AppleSignInController extends AsyncNotifier<void> {
  @override
  void build() {}
  Future<void> signIn() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).signInWithApple());
  }
}

final appleSignInProvider = AsyncNotifierProvider<AppleSignInController, void>(AppleSignInController.new);

@immutable
class EmailSignInState {
  const EmailSignInState({this.email = '', this.sentAt, this.busy = false, this.link = ''});
  final String email;
  final DateTime? sentAt;
  final bool busy;

  /// In memory only. Never store, log, or place the credential into navigation URLs.
  final String link;
  EmailSignInState copyWith({String? email, DateTime? sentAt, bool? busy, String? link}) => EmailSignInState(
    email: email ?? this.email,
    sentAt: sentAt ?? this.sentAt,
    busy: busy ?? this.busy,
    link: link ?? this.link,
  );
}

class EmailSignInController extends Notifier<EmailSignInState> {
  static const resendAfter = Duration(seconds: 60);
  @override
  EmailSignInState build() => const EmailSignInState();
  Future<void> sendLink(String email) => _run(() async {
    await ref.read(authRepositoryProvider).sendEmailLink(email);
    if (ref.mounted) state = state.copyWith(email: email.trim(), sentAt: DateTime.now());
  });
  Future<void> resend() => sendLink(state.email);
  Future<void> receiveLink(Uri uri) async {
    final repo = ref.read(authRepositoryProvider);
    final link = uri.toString();
    if (!repo.acceptsEmailLink(link) || state.link == link) return;
    final email = await repo.emailStore.read() ?? '';
    if (ref.mounted) state = state.copyWith(link: link, email: email);
  }

  Future<void> complete(String email) => _run(() async {
    await ref.read(authRepositoryProvider).completeEmailLink(email: email, link: state.link);
    if (ref.mounted) state = const EmailSignInState();
  });
  void discardLink() => state = const EmailSignInState();
  Future<void> _run(Future<void> Function() action) async {
    if (state.busy) return;
    state = state.copyWith(busy: true);
    try {
      await action();
    } finally {
      if (ref.mounted) state = state.copyWith(busy: false);
    }
  }
}

final emailSignInProvider = NotifierProvider<EmailSignInController, EmailSignInState>(EmailSignInController.new);
