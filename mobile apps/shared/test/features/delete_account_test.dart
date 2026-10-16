import 'package:autolinky/core/errors/app_failure.dart';
import 'package:autolinky/features/profile/presentation/delete_account_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers.dart';

void main() {
  testWidgets('deletion requires the signed-in email and signs out only after API success', (tester) async {
    final auth = FakeAuth()..session = testSession();
    addTearDown(auth.dispose);
    final account = MockAccountRepository();
    final background = FakeBackground();
    when(account.delete).thenAnswer((_) async {});
    await pumpScreen(
      tester,
      const DeleteAccountScreen(),
      overrides: await baseOverrides(auth: auth, account: account, background: background),
    );
    await tester.enterText(find.byType(TextField), 'different@example.com');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    verifyNever(account.delete);
    await tester.enterText(find.byType(TextField), 'sara@example.com');
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
    await tester.tap(find.byType(FilledButton));
    await settle(tester);
    verify(account.delete).called(1);
    expect(background.stops, 1);
    verify(auth.repo.signOut).called(1);
  });

  testWidgets('unresolved delivery refuses deletion and retains the session and notifications', (tester) async {
    final auth = FakeAuth()..session = testSession();
    addTearDown(auth.dispose);
    final account = MockAccountRepository();
    final background = FakeBackground();
    when(account.delete).thenThrow(const ApiFailure(statusCode: 409, code: 'deletion_blocked'));
    await pumpScreen(
      tester,
      const DeleteAccountScreen(),
      overrides: await baseOverrides(auth: auth, account: account, background: background),
    );
    await tester.enterText(find.byType(TextField), 'sara@example.com');
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
    await tester.tap(find.byType(FilledButton));
    await settle(tester);
    expect(find.textContaining('An email is still being processed'), findsOneWidget);
    expect(background.stops, 0);
    verifyNever(auth.repo.signOut);
  });
}
