import 'package:autolinky/core/config/env.dart';
import 'package:autolinky/core/errors/app_failure.dart';
import 'package:autolinky/core/widgets/bidi_text.dart';
import 'package:autolinky/features/auth/application/auth_providers.dart';
import 'package:autolinky/features/auth/presentation/email_link_screen.dart';
import 'package:autolinky/features/auth/presentation/email_screen.dart';
import 'package:autolinky/features/auth/presentation/welcome_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers.dart';

void main() {
  late FakeAuth auth;

  setUp(() => auth = FakeAuth());
  tearDown(() => auth.dispose());

  testWidgets('welcome: Google first, email as the other way', (tester) async {
    await pumpScreen(tester, const WelcomeScreen(), overrides: await baseOverrides(auth: auth));
    expect(find.text('Jobs that fit you, found for you'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with email'), findsOneWidget);
    expect(find.textContaining('Terms of Service', findRichText: true), findsOneWidget);
  });

  testWidgets('welcome speaks Arabic, right to left', (tester) async {
    await pumpScreen(
      tester,
      const WelcomeScreen(),
      overrides: await baseOverrides(auth: auth),
      locale: const Locale('ar'),
    );
    expect(find.text('المتابعة باستخدام Google'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(WelcomeScreen))), TextDirection.rtl);
  });

  testWidgets('tapping Google signs in; a failure is shown, a cancel is not', (tester) async {
    when(() => auth.repo.signInWithGoogle()).thenThrow(const NotConfiguredFailure('google'));
    await pumpScreen(tester, const WelcomeScreen(), overrides: await baseOverrides(auth: auth));
    await tester.tap(find.text('Continue with Google'));
    await settle(tester);
    verify(() => auth.repo.signInWithGoogle()).called(1);
    expect(find.text("This sign-in option isn't available yet. Please use another one."), findsOneWidget);

    ScaffoldMessenger.of(tester.element(find.byType(WelcomeScreen))).clearSnackBars();
    await settle(tester);
    when(() => auth.repo.signInWithGoogle()).thenThrow(const CancelledFailure());
    await tester.tap(find.text('Continue with Google'));
    await settle(tester);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('email sign-in can be turned off per build', (tester) async {
    const noEmail = Env(
      apiBaseUrl: 'https://api.test',
      firebaseApiKey: 'public-key',
      firebaseAppId: 'app-id',
      googleWebClientId: 'g',
      emailSignIn: false,
    );
    await pumpScreen(
      tester,
      const WelcomeScreen(),
      overrides: await baseOverrides(auth: auth, env: noEmail),
    );
    expect(find.text('Continue with email'), findsNothing);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('the email screen checks the address before sending', (tester) async {
    when(() => auth.repo.sendEmailLink(any())).thenAnswer((_) async {});
    await pumpScreen(tester, const EmailScreen(), overrides: await baseOverrides(auth: auth));
    await tester.enterText(find.byType(TextFormField), 'not-an-email');
    await tester.tap(find.text('Send sign-in link'));
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    verifyNever(() => auth.repo.sendEmailLink(any()));
  });

  testWidgets('email waiting screen shows the requested address and rate-limits resending', (tester) async {
    await pumpScreen(
      tester,
      const EmailLinkScreen(),
      overrides: [
        ...await baseOverrides(auth: auth),
        emailSignInProvider.overrideWith(_SentTo.new),
      ],
    );
    expect(find.textContaining('sara@example.com'), findsOneWidget);
    expect(find.textContaining('Resend link in'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    await tester.pump(const Duration(seconds: 61));
    expect(find.text('Resend link'), findsOneWidget);
  });

  testWidgets('a received link asks for its matching email on another device', (tester) async {
    when(
      () => auth.repo.completeEmailLink(
        email: any(named: 'email'),
        link: any(named: 'link'),
      ),
    ).thenThrow(const InvalidCodeFailure());
    await pumpScreen(
      tester,
      const EmailLinkScreen(),
      overrides: [
        ...await baseOverrides(auth: auth),
        emailSignInProvider.overrideWith(_ReceivedLink.new),
      ],
    );
    expect(find.text('Finish signing in'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'sara@example.com');
    await tester.tap(find.text('Sign in'));
    await settle(tester);
    verify(
      () =>
          auth.repo.completeEmailLink(email: 'sara@example.com', link: 'https://auto-linky.firebaseapp.com/test-link'),
    ).called(1);
    expect(find.textContaining('This sign-in link is invalid'), findsOneWidget);
  });

  testWidgets('English text keeps its own direction inside the Arabic app', (tester) async {
    expect(directionOf('Senior Network Engineer'), TextDirection.ltr);
    expect(directionOf('مهندس شبكات'), TextDirection.rtl);
    expect(directionOf('2026 - 42%'), isNull);
    await pumpScreen(
      tester,
      const Scaffold(body: BidiText('Senior Network Engineer')),
      overrides: await baseOverrides(auth: auth),
      locale: const Locale('ar'),
    );
    final text = tester.widget<Text>(find.text('Senior Network Engineer'));
    expect(text.textDirection, TextDirection.ltr);
    expect(text.textAlign, TextAlign.right); // still aligned with the Arabic page
  });

  test('email addresses', () {
    expect(isValidEmail('sara@example.com'), isTrue);
    expect(isValidEmail('  sara.ali+jobs@mail.example.eg '), isTrue);
    for (final bad in ['', 'sara', 'sara@', '@example.com', 'sara@example', 'sa ra@example.com']) {
      expect(isValidEmail(bad), isFalse, reason: bad);
    }
  });
}

class _SentTo extends EmailSignInController {
  @override
  EmailSignInState build() => EmailSignInState(email: 'sara@example.com', sentAt: DateTime.now());
}

class _ReceivedLink extends EmailSignInController {
  @override
  EmailSignInState build() => const EmailSignInState(link: 'https://auto-linky.firebaseapp.com/test-link');
}
