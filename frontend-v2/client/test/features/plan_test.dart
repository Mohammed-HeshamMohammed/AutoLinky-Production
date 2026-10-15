import 'package:autolinky/app/app.dart';
import 'package:autolinky/core/errors/app_failure.dart';
import 'package:autolinky/core/widgets/states.dart';
import 'package:autolinky/features/auto_apply/presentation/pro_celebration.dart';
import 'package:autolinky/features/auto_apply/presentation/upgrade.dart';
import 'package:autolinky/features/settings/application/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

/// Step 8o: 20 free applications by e-mail, then "Upgrade" (a WhatsApp chat); the Auto apply tab locks its jobs.
void main() {
  late FakeAuth auth;
  late FakeLinks links;
  late SharedPreferencesWithCache prefs;
  const userId = 'firebase-opaque-user-1'; // testSession's user

  setUpAll(() => registerFallbackValue(<String, Object?>{}));
  setUp(() {
    auth = FakeAuth()..session = testSession(email: 'sara.ali@gmail.com');
    links = FakeLinks();
  });
  tearDown(() => auth.dispose());

  Future<FakeApplicationsApi> pumpApp(
    WidgetTester tester,
    FakeApplicationsApi apps, {
    String? language,
    Map<String, Object> saved = const {},
  }) async {
    usePhoneSize(tester);
    final matches = FakeMatchesApi();
    for (final m in matches.jobs) {
      apps.jobs[m.job.id] = m.job;
    }
    prefs = await testPreferences({SettingsController.localeKey: ?language, ...saved});
    await tester.pumpWidget(
      ProviderScope(
        overrides: await baseOverrides(auth: auth, applications: apps, matches: matches, links: links, prefs: prefs),
        retry: (_, _) => null,
        child: const AutolinkyApp(),
      ),
    );
    await settle(tester);
    return apps;
  }

  testWidgets('on the free plan the Auto apply tab says how many free applications are left', (tester) async {
    await pumpApp(tester, FakeApplicationsApi(jobs: {})..freeUsed = 8);
    expect(find.text('12 of 20 free applications left'), findsOneWidget);
    expect(find.byType(LockedJob), findsNothing);
    expect(find.text('Unlock unlimited applications'), findsNothing);
  });

  testWidgets('used up: the jobs are locked, and "Upgrade" opens WhatsApp with the message ready', (tester) async {
    final apps = FakeApplicationsApi(jobs: {})
      ..emailConnected = true
      ..freeUsed = 20;
    await pumpApp(tester, apps);
    expect(find.text('Unlock unlimited applications'), findsOneWidget); // the card over the locked jobs
    expect(find.textContaining("You've used your 20 free applications"), findsOneWidget);
    expect(find.text('Turn on'), findsNothing); // in place of the auto apply banner: it cannot send either
    expect(find.byType(LockedJob), findsWidgets); // the jobs, blurred
    // a locked job cannot be applied to: its buttons are not even reachable
    expect(find.widgetWithText(FilledButton, 'Send my CV').hitTestable(), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Upgrade').last);
    await settle(tester);
    expect(
      find.text(
        "You've used your 20 free applications. Upgrade to send your CV to every job that fits you, by "
        'hand and with auto apply.',
      ),
      findsOneWidget,
    );
    expect(find.text('Unlimited applications by e-mail'), findsOneWidget);
    expect(find.textContaining('sara.ali@gmail.com'), findsOneWidget); // the account the plan is for
    await tester.tap(
      find.descendant(of: find.byType(BottomSheet), matching: find.widgetWithText(FilledButton, 'Upgrade')),
    );
    await settle(tester);
    // a promo code first: none here, WhatsApp at once with the message as the API wrote it
    expect(find.text('Do you have a promo code?'), findsOneWidget);
    expect(links.opened, isEmpty);
    await tester.tap(find.text('No, continue to WhatsApp'));
    await settle(tester);
    expect(links.opened.single.toString(), apps.upgradeUrl);
    expect(links.opened.single.host, 'wa.me');
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('a promo code goes with the WhatsApp message, on a line of its own', (tester) async {
    final apps = await pumpApp(tester, FakeApplicationsApi(jobs: {})..freeUsed = 20);
    await tester.tap(find.widgetWithText(FilledButton, 'Upgrade').last);
    await settle(tester);
    await tester.tap(
      find.descendant(of: find.byType(BottomSheet), matching: find.widgetWithText(FilledButton, 'Upgrade')),
    );
    await settle(tester);
    await tester.tap(find.text('Yes, I have a code'));
    await settle(tester);
    expect(find.text('Enter your promo code'), findsOneWidget);
    // nothing typed: nothing to send yet
    final send = find.widgetWithText(FilledButton, 'Continue to WhatsApp');
    expect(tester.widget<FilledButton>(send).onPressed, isNull);
    await tester.enterText(find.widgetWithText(TextField, 'Promo code'), ' Daniel 20 ');
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'Daniel20'); // no spaces in a code
    await tester.tap(send);
    await settle(tester);
    final chat = links.opened.single;
    expect(chat.host, 'wa.me');
    expect(chat.path, Uri.parse(apps.upgradeUrl).path);
    expect(chat.queryParameters['text'], 'Hello, I want to subscribe\nPromo code: Daniel20');
    expect(chat.toString(), contains('%20')); // spaces as %20: WhatsApp would show a "+"
    expect(chat.toString(), isNot(contains('+')));
  });

  testWidgets('"Continue without a code" goes to WhatsApp with the message as it was', (tester) async {
    final apps = await pumpApp(tester, FakeApplicationsApi(jobs: {})..freeUsed = 20);
    await tester.tap(find.widgetWithText(FilledButton, 'Upgrade').last);
    await settle(tester);
    await tester.tap(
      find.descendant(of: find.byType(BottomSheet), matching: find.widgetWithText(FilledButton, 'Upgrade')),
    );
    await settle(tester);
    await tester.tap(find.text('Yes, I have a code'));
    await settle(tester);
    await tester.tap(find.text('Continue without a code'));
    await settle(tester);
    expect(links.opened.single.toString(), apps.upgradeUrl);
  });

  group('the subscribe link', () {
    const base =
        'https://wa.me/201060933358?text=Hello%2C%20I%20want%20to%20subscribe%0AMy%20Autolinky%20account%3A%20'
        'sara.ali%40gmail.com';

    test('no code: the link as the API gave it', () {
      expect(upgradeLink(base).toString(), base);
      expect(upgradeLink(base, promoCode: '  ').toString(), base);
    });

    test('a code: one more line, the rest of the message and the link kept', () {
      final link = upgradeLink(base, promoCode: 'Daniel20')!;
      expect(link.host, 'wa.me');
      expect(link.path, '/201060933358');
      expect(
        link.queryParameters['text'],
        'Hello, I want to subscribe\nMy Autolinky account: sara.ali@gmail.com\nPromo code: Daniel20',
      );
      expect(link.toString(), isNot(contains('+')));
    });

    test('a link without a message gets one; other parameters stay; never anything but a web link', () {
      expect(upgradeLink('https://wa.me/20100', promoCode: 'A1')!.queryParameters['text'], 'Promo code: A1');
      final kept = upgradeLink('https://example.com/pay?plan=pro&text=Hi', promoCode: 'A 1')!;
      expect(kept.queryParameters, {'plan': 'pro', 'text': 'Hi\nPromo code: A1'});
      expect(upgradeLink('javascript:alert(1)', promoCode: 'A1'), isNull);
      expect(upgradeLink(null), isNull);
    });
  });

  testWidgets('used up: the auto apply switch offers the upgrade, never the Gmail setup', (tester) async {
    final apps = await pumpApp(tester, FakeApplicationsApi(jobs: {})..freeUsed = 20);
    expect(find.text('Free applications used up · Upgrade to turn it on'), findsOneWidget);
    expect(find.textContaining('free applications left'), findsNothing);
    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(find.text('Unlimited applications by e-mail'), findsOneWidget);
    expect(find.text('Connect Gmail'), findsNothing);
    expect(apps.autoApplyCalls, isEmpty);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  testWidgets('a tap on a locked job offers the upgrade too', (tester) async {
    await pumpApp(tester, FakeApplicationsApi(jobs: {})..freeUsed = 25);
    await tester.ensureVisible(find.byType(LockedJob).first);
    await settle(tester);
    await tester.tap(find.byType(LockedJob).first);
    await settle(tester);
    expect(find.text('Unlimited applications by e-mail'), findsOneWidget);
  });

  testWidgets('"Send my CV" with none left: the upgrade, never the e-mail', (tester) async {
    final apps = FakeApplicationsApi(jobs: {})
      ..emailConnected = true
      ..freeUsed = 20;
    await pumpApp(tester, apps);
    await tester.tap(find.text('Explore'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Send my CV').first);
    await settle(tester);
    expect(find.text('Unlock unlimited applications'), findsOneWidget);
    expect(find.text('Send your CV?'), findsNothing);
    verifyNever(() => apps.repo.emailPreview(any()));
    expect(apps.recorded, isEmpty);
  });

  testWidgets('the server says the free ones just ran out: the upgrade is offered', (tester) async {
    final apps = FakeApplicationsApi(jobs: {})
      ..emailConnected = true
      ..freeUsed = 19
      ..failRecord = const ApiFailure(statusCode: 402, code: 'free_limit');
    await pumpApp(tester, apps);
    await tester.tap(find.widgetWithText(FilledButton, 'Send my CV').first);
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await settle(tester);
    expect(find.text('Unlock unlimited applications'), findsOneWidget);
  });

  testWidgets('a subscriber: no limit, nothing locked, the plan says Pro', (tester) async {
    final apps = FakeApplicationsApi(jobs: {})
      ..emailConnected = true
      ..pro = true
      ..freeUsed = 140;
    await pumpApp(
      tester,
      apps,
      saved: {
        proCelebratedKey: [userId],
      },
    ); // already welcomed
    expect(find.byType(ProCelebration), findsNothing);
    expect(find.byType(LockedJob), findsNothing);
    expect(find.textContaining('free applications left'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Send my CV'), findsWidgets);
    await tester.tap(find.text('Profile'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined).first);
    await settle(tester);
    expect(find.text('Pro · unlimited applications'), findsOneWidget);
  });

  testWidgets('the auto apply screen: used up, its button is "Upgrade"', (tester) async {
    final apps = FakeApplicationsApi(jobs: {})
      ..emailConnected = true
      ..freeUsed = 20;
    await pumpApp(tester, apps);
    await tester.tap(find.text('Profile'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined).first);
    await settle(tester);
    expect(find.text('Free · No free applications left'), findsOneWidget);
    await tester.tap(find.text('Auto apply'));
    await settle(tester);
    expect(find.widgetWithText(FilledButton, 'Start auto apply'), findsNothing);
    await tester.tap(find.descendant(of: find.byType(BottomActionBar), matching: find.text('Upgrade')));
    await settle(tester);
    expect(find.text('Unlimited applications by e-mail'), findsOneWidget);
    expect(apps.autoApplyCalls, isEmpty); // never turned on
  });

  testWidgets('the first time the app opens as Pro: a celebration and a welcome, once', (tester) async {
    final apps = FakeApplicationsApi(jobs: {})
      ..emailConnected = true
      ..pro = true;
    await pumpApp(tester, apps);
    expect(find.byType(ProCelebration), findsOneWidget);
    expect(find.text('Welcome to Pro!'), findsOneWidget);
    expect(find.text('Unlimited applications by e-mail'), findsOneWidget);
    expect(prefs.getStringList(proCelebratedKey), [userId]); // saved at once: never twice
    await tester.tap(find.widgetWithText(FilledButton, "Let's go"));
    await settle(tester);
    expect(find.byType(ProCelebration), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Send my CV'), findsWidgets); // the app, ready to use
    expect(tester.takeException(), isNull);
  });

  testWidgets('a free user: no celebration; a plan that ended is celebrated again next time', (tester) async {
    await pumpApp(
      tester,
      FakeApplicationsApi(jobs: {})..freeUsed = 3,
      saved: {
        proCelebratedKey: [userId],
      },
    );
    expect(find.byType(ProCelebration), findsNothing);
    expect(prefs.getStringList(proCelebratedKey), isEmpty);
  });

  testWidgets('the celebration in Arabic', (tester) async {
    await pumpApp(tester, FakeApplicationsApi(jobs: {})..pro = true, language: 'ar');
    expect(find.text('أهلاً بك في Pro!'), findsOneWidget);
    expect(find.text('هيا بنا'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('in Arabic', (tester) async {
    await pumpApp(tester, FakeApplicationsApi(jobs: {})..freeUsed = 20, language: 'ar');
    expect(find.text('افتح التقديم بلا حدود'), findsOneWidget);
    expect(find.textContaining('استخدمت طلباتك المجانية الـ 20'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
