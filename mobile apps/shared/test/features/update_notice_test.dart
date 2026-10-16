import 'package:autolinky/app/app.dart';
import 'package:autolinky/core/updates/app_updates.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

void main() {
  late FakeAuth auth;

  setUp(() => auth = FakeAuth()..session = testSession());
  tearDown(() => auth.dispose());

  /// The signed-in app, running over-the-air update [patch] (null: the plain release).
  Future<SharedPreferencesWithCache> openApp(WidgetTester tester, {int? patch, int? lastNoticed}) async {
    final prefs = await testPreferences({lastNoticedPatchKey: ?lastNoticed});
    usePhoneSize(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: await baseOverrides(auth: auth, prefs: prefs, patch: () async => patch),
        retry: (_, _) => null,
        child: const AutolinkyApp(),
      ),
    );
    await settle(tester);
    return prefs;
  }

  testWidgets('a new update: a dialog says so once, and it is remembered', (tester) async {
    final prefs = await openApp(tester, patch: 2);
    expect(find.text('The app was updated'), findsOneWidget);
    expect(find.textContaining('update 2'), findsOneWidget);
    expect(prefs.getInt(lastNoticedPatchKey), 2);

    await tester.tap(find.text('Got it'));
    await settle(tester);
    expect(find.text('The app was updated'), findsNothing);
  });

  testWidgets('the same update is not announced again on the next opening', (tester) async {
    await openApp(tester, patch: 2, lastNoticed: 2);
    expect(find.text('The app was updated'), findsNothing);
  });

  testWidgets('a newer update than the last announced one is announced', (tester) async {
    await openApp(tester, patch: 3, lastNoticed: 2);
    expect(find.text('The app was updated'), findsOneWidget);
    expect(find.textContaining('update 3'), findsOneWidget);
  });

  testWidgets('no update (the plain release): nothing to say', (tester) async {
    final prefs = await openApp(tester);
    expect(find.text('The app was updated'), findsNothing);
    expect(prefs.getInt(lastNoticedPatchKey), isNull);
  });

  testWidgets('a rolled-back update is not announced, only remembered', (tester) async {
    final prefs = await openApp(tester, patch: 2, lastNoticed: 3);
    expect(find.text('The app was updated'), findsNothing);
    expect(prefs.getInt(lastNoticedPatchKey), 2);
  });

  testWidgets('Settings shows which update the app is running', (tester) async {
    await openApp(tester, patch: 2, lastNoticed: 2);
    await tester.tap(find.text('Profile'));
    await settle(tester);
    await tester.tap(find.byTooltip('Settings'));
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Version 1.0.0 (1) · update 2'), 300);
    expect(find.text('Version 1.0.0 (1) · update 2'), findsOneWidget);
  });

  testWidgets('Settings without an update shows the plain version', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('Profile'));
    await settle(tester);
    await tester.tap(find.byTooltip('Settings'));
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Version 1.0.0 (1)'), 300);
    expect(find.text('Version 1.0.0 (1)'), findsOneWidget);
  });
}
