import 'package:autolinky/core/config/env.dart';
import 'package:autolinky/core/errors/app_failure.dart';
import 'package:autolinky/core/storage/email_link_store.dart';
import 'package:autolinky/features/auth/data/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockGoogle extends Mock implements GoogleSignIn {}

class MockGoogleAccount extends Mock implements GoogleSignInAccount {}

class MockUserCredential extends Mock implements UserCredential {}

class MockEmailStore extends Mock implements EmailLinkStore {}

void main() {
  late MockFirebaseAuth auth;
  late MockGoogle google;
  late MockEmailStore store;
  late AuthRepository repo;
  const link = 'https://auto-linky.firebaseapp.com/__/auth/links?oobCode=test';
  setUpAll(() {
    registerFallbackValue(GoogleAuthProvider.credential(idToken: 'fallback'));
    registerFallbackValue(ActionCodeSettings(url: 'https://app.test/continue'));
  });
  setUp(() {
    auth = MockFirebaseAuth();
    google = MockGoogle();
    store = MockEmailStore();
    repo = AuthRepository(auth: auth, env: testEnv, google: google, emailStore: store);
    when(() => auth.currentUser).thenReturn(null);
    when(() => store.save(any())).thenAnswer((_) async {});
    when(store.clear).thenAnswer((_) async {});
    when(
      () => google.initialize(
        serverClientId: any(named: 'serverClientId'),
        clientId: any(named: 'clientId'),
      ),
    ).thenAnswer((_) async {});
  });

  test('native Google credential is exchanged with Firebase and uses the registered web audience', () async {
    final account = MockGoogleAccount();
    when(() => account.authentication).thenReturn(const GoogleSignInAuthentication(idToken: 'google-id-token'));
    when(() => google.authenticate(scopeHint: any(named: 'scopeHint'))).thenAnswer((_) async => account);
    when(() => auth.signInWithCredential(any())).thenAnswer((_) async => MockUserCredential());
    await repo.signInWithGoogle();
    verify(() => google.initialize(serverClientId: testEnv.googleWebClientId)).called(1);
    final credential = verify(() => auth.signInWithCredential(captureAny())).captured.single as OAuthCredential;
    expect(credential.providerId, 'google.com');
    expect(credential.idToken, 'google-id-token');
  });

  test('Google cancellation and configuration failure stay distinct', () async {
    when(() => google.authenticate(scopeHint: any(named: 'scopeHint')))
        .thenThrow(const GoogleSignInException(code: GoogleSignInExceptionCode.canceled));
    await expectLater(repo.signInWithGoogle(), throwsA(isA<CancelledFailure>()));
    when(() => google.authenticate(scopeHint: any(named: 'scopeHint')))
        .thenThrow(const GoogleSignInException(code: GoogleSignInExceptionCode.clientConfigurationError));
    await expectLater(repo.signInWithGoogle(), throwsA(isA<NotConfiguredFailure>()));
    const missing = Env(apiBaseUrl: 'https://api.test', firebaseApiKey: 'a', firebaseAppId: 'b');
    await expectLater(
      AuthRepository(auth: auth, env: missing, emailStore: store).signInWithGoogle(),
      throwsA(isA<NotConfiguredFailure>()),
    );
  });

  test('email links use the approved continuation URL without an email in it or a default linkDomain', () async {
    when(
      () => auth.sendSignInLinkToEmail(
        email: any(named: 'email'),
        actionCodeSettings: any(named: 'actionCodeSettings'),
      ),
    ).thenAnswer((_) async {});
    await repo.sendEmailLink(' sara@example.com ');
    final settings =
        verify(
              () => auth.sendSignInLinkToEmail(
                email: 'sara@example.com',
                actionCodeSettings: captureAny(named: 'actionCodeSettings'),
              ),
            ).captured.single
            as ActionCodeSettings;
    expect(settings.url, testEnv.emailLinkContinueUrl);
    expect(settings.url, isNot(contains('sara')));
    expect(settings.linkDomain, isNull);
    expect(settings.androidPackageName, 'com.autolinky.app');
    verify(() => store.save('sara@example.com')).called(1);
  });

  test('unknown link domains cannot reach Firebase; cross-device email must match Firebase verification', () async {
    await expectLater(
      repo.completeEmailLink(email: 'sara@example.com', link: 'https://attacker.test/?oobCode=x'),
      throwsA(isA<InvalidCodeFailure>()),
    );
    verifyNever(
      () => auth.signInWithEmailLink(
        email: any(named: 'email'),
        emailLink: any(named: 'emailLink'),
      ),
    );
    when(() => auth.isSignInWithEmailLink(link)).thenReturn(true);
    when(() => auth.signInWithEmailLink(email: 'sara@example.com', emailLink: link))
        .thenThrow(FirebaseAuthException(code: 'invalid-action-code'));
    await expectLater(
      repo.completeEmailLink(email: 'sara@example.com', link: link),
      throwsA(isA<InvalidCodeFailure>()),
    );
    verifyNever(store.clear);
    when(() => auth.signInWithEmailLink(email: 'sara@example.com', emailLink: link))
        .thenAnswer((_) async => MockUserCredential());
    await repo.completeEmailLink(email: 'sara@example.com', link: link);
    verify(store.clear).called(1);
  });

  test('a link cannot replace a signed-in different account', () async {
    final existingUser = testSession(email: 'other@example.com').user;
    when(() => auth.currentUser).thenReturn(existingUser);
    when(() => auth.isSignInWithEmailLink(link)).thenReturn(true);
    await expectLater(repo.completeEmailLink(email: 'sara@example.com', link: link), throwsA(isA<ApiFailure>()));
    verifyNever(
      () => auth.signInWithEmailLink(
        email: any(named: 'email'),
        emailLink: any(named: 'emailLink'),
      ),
    );
  });

  test('token refresh uses Firebase SDK; network failure does not become a signed-out session', () async {
    final user = testSession().user;
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.getIdToken(true)).thenAnswer((_) async => 'fresh-firebase-token');
    expect(await repo.accessToken(forceRefresh: true), 'fresh-firebase-token');
    when(() => user.getIdToken()).thenThrow(FirebaseAuthException(code: 'network-request-failed'));
    await expectLater(repo.accessToken(), throwsA(isA<NetworkFailure>()));
    verifyNever(auth.signOut);
  });

  test('sign-out clears pending email and leaves the Google account picker intact', () async {
    when(auth.signOut).thenAnswer((_) async {});
    await repo.signOut();
    verify(auth.signOut).called(1);
    verify(store.clear).called(1);
    verifyNever(google.signOut);
  });
}
