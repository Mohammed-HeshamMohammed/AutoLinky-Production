import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/env.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/storage/email_link_store.dart';

enum SignInMethod { google, email, apple, other }

class AuthRepository {
  AuthRepository({required this._auth, required this._env, GoogleSignIn? google, EmailLinkStore? emailStore})
    : _google = google ?? GoogleSignIn.instance,
      emailStore = emailStore ?? EmailLinkStore();
  final FirebaseAuth _auth;
  final Env _env;
  final GoogleSignIn _google;
  final EmailLinkStore emailStore;
  Future<void>? _googleReady;
  Stream<User?> get authStateChanges => _auth.idTokenChanges();
  User? get currentUser => _auth.currentUser;
  SignInMethod get signInMethod {
    final providers = currentUser?.providerData.map((provider) => provider.providerId).toSet() ?? {};
    if (providers.contains('google.com')) return SignInMethod.google;
    if (providers.contains('apple.com')) return SignInMethod.apple;
    if (providers.contains('password')) return SignInMethod.email;
    return SignInMethod.other;
  }

  Future<String?> accessToken({bool forceRefresh = false}) async {
    try {
      return await currentUser?.getIdToken(forceRefresh);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'network-request-failed') throw const NetworkFailure();
      return null;
    }
  }

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _guard(() => _auth.signInWithPopup(GoogleAuthProvider()));
      return;
    }
    if (!_env.googleSignInConfigured) throw const NotConfiguredFailure('google');
    try {
      _googleReady ??= _google.initialize(
        serverClientId: _env.googleWebClientId,
        clientId: _env.googleIosClientId.isEmpty ? null : _env.googleIosClientId,
      );
      await _googleReady;
      final account = await _google.authenticate(scopeHint: const ['email', 'profile']);
      final token = account.authentication.idToken;
      if (token == null) throw const UnknownFailure();
      await _guard(() => _auth.signInWithCredential(GoogleAuthProvider.credential(idToken: token)));
    } on GoogleSignInException catch (error) {
      _googleReady = null;
      throw switch (error.code) {
        GoogleSignInExceptionCode.canceled => const CancelledFailure(),
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError => const NotConfiguredFailure('google'),
        _ => const UnknownFailure(),
      };
    }
  }

  Future<void> signInWithApple() async {
    if (!_env.appleSignIn) throw const NotConfiguredFailure('apple');
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    await _guard(() => kIsWeb ? _auth.signInWithPopup(provider) : _auth.signInWithProvider(provider));
  }

  bool acceptsEmailLink(String link) {
    final uri = Uri.tryParse(link);
    return uri != null &&
        uri.scheme == 'https' &&
        {_env.firebaseLinkHost, Uri.tryParse(_env.emailLinkContinueUrl)?.host}.contains(uri.host) &&
        _auth.isSignInWithEmailLink(link);
  }

  Future<void> sendEmailLink(String email) async {
    if (!_env.emailSignIn || _env.emailLinkContinueUrl.isEmpty) throw const NotConfiguredFailure('email');
    final address = email.trim();
    await _guard(
      () => _auth.sendSignInLinkToEmail(
        email: address,
        actionCodeSettings: ActionCodeSettings(
          url: _env.emailLinkContinueUrl,
          handleCodeInApp: true,
          androidPackageName: 'com.autolinky.app',
          iOSBundleId: 'com.autolinky.ios',
          linkDomain: _env.emailLinkDomain.isEmpty ? null : _env.emailLinkDomain,
        ),
      ),
    );
    await emailStore.save(address);
  }

  Future<void> completeEmailLink({required String email, required String link}) async {
    if (!acceptsEmailLink(link)) throw const InvalidCodeFailure();
    if (currentUser != null && currentUser!.email?.toLowerCase() != email.trim().toLowerCase()) {
      throw const ApiFailure(statusCode: 409, code: 'different_account');
    }
    await _guard(() => _auth.signInWithEmailLink(email: email.trim(), emailLink: link));
    await emailStore.clear();
  }

  /// Explicit linking requires an existing session and a new provider credential.
  /// It never selects or merges an account using a supplied email address.
  Future<void> linkCredential(AuthCredential credential) async {
    final user = currentUser;
    if (user == null) throw const SessionExpiredFailure();
    await _guard(() => user.linkWithCredential(credential));
  }

  Future<void> signOut() async {
    await _guard(_auth.signOut);
    await emailStore.clear();
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on FirebaseAuthException catch (error) {
      throw switch (error.code) {
        'network-request-failed' => const NetworkFailure(),
        'too-many-requests' || 'quota-exceeded' => const RateLimitedFailure(),
        'expired-action-code' ||
        'invalid-action-code' ||
        'invalid-email' ||
        'invalid-credential' => const InvalidCodeFailure(),
        'popup-closed-by-user' || 'cancelled-popup-request' || 'web-context-cancelled' => const CancelledFailure(),
        'operation-not-allowed' || 'unauthorized-domain' || 'invalid-api-key' => const NotConfiguredFailure('provider'),
        'user-disabled' => const ForbiddenFailure(),
        'user-token-expired' || 'user-not-found' || 'requires-recent-login' => const SessionExpiredFailure(),
        _ => const UnknownFailure(),
      };
    }
  }
}
