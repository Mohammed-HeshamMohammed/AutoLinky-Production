import 'package:autolinky/app/app.dart';
import 'package:autolinky/core/errors/app_failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers.dart';

void main() {
  late FakeAuth auth;

  setUp(() => auth = FakeAuth());
  tearDown(() => auth.dispose());

  Future<void> pumpApp(WidgetTester tester, {MockAccountRepository? account}) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: await baseOverrides(auth: auth, account: account),
        retry: (_, _) => null,
        child: const AutolinkyApp(),
      ),
    );
    await settle(tester);
  }

  testWidgets('signed out: the welcome screen, nothing else', (tester) async {
    await pumpApp(tester);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('signing in opens the app; signing out comes back', (tester) async {
    await pumpApp(tester);
    auth.signIn(testSession());
    await settle(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Jobs for you'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await settle(tester);
    expect(find.text('Sara Ali'), findsOneWidget);
    expect(find.text('sara@example.com'), findsOneWidget);
    expect(find.text('Signed in with Google'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Sign out'), 300);
    await tester.ensureVisible(find.text('Sign out'));
    await settle(tester);
    await tester.tap(find.text('Sign out').first);
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await settle(tester);
    verify(() => auth.repo.signOut()).called(1);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('signing out and in again, over and over, stays in the app', (tester) async {
    await pumpApp(tester);
    for (var i = 0; i < 3; i++) {
      auth.signIn(testSession());
      await settle(tester);
      expect(find.byType(NavigationBar), findsOneWidget, reason: 'sign-in number ${i + 1}');
      auth.signIn(null); // signing out
      await settle(tester);
      expect(find.text('Continue with Google'), findsOneWidget, reason: 'sign-out number ${i + 1}');
    }
    verifyNever(() => auth.repo.signOut()); // the app never signed the user out by itself
  });

  testWidgets('already signed in: straight to the app', (tester) async {
    auth.session = testSession();
    await pumpApp(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('a blocked account sees why on the profile, with a retry', (tester) async {
    final account = MockAccountRepository();
    when(account.me).thenThrow(const ForbiddenFailure());
    auth.session = testSession();
    await pumpApp(tester, account: account);
    await tester.tap(find.text('Profile'));
    await settle(tester);
    expect(find.textContaining("can't use Autolinky"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('a session the API refuses signs the user out', (tester) async {
    final account = MockAccountRepository();
    when(account.me).thenThrow(const SessionExpiredFailure());
    auth.session = testSession();
    await pumpApp(tester, account: account);
    verify(() => auth.repo.signOut()).called(1);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('settings: theme and language change the app at once', (tester) async {
    auth.session = testSession();
    await pumpApp(tester);
    await tester.tap(find.text('Profile'));
    await settle(tester);
    await tester.tap(find.byTooltip('Settings'));
    await settle(tester);

    await tester.tap(find.text('Dark'));
    await settle(tester);
    expect(Theme.of(tester.element(find.text('Appearance'))).brightness, Brightness.dark);

    await tester.tap(find.text('العربية'));
    await settle(tester);
    expect(find.text('الإعدادات'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('الإعدادات'))), TextDirection.rtl);
  });
}
