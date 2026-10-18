import 'package:autolinky/app/app.dart';
import 'package:autolinky/features/applications/data/applications_repository.dart';
import 'package:autolinky/features/settings/application/settings_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

/// Step 8e: auto apply's switch on "For you", connecting Gmail step by step, turning auto apply on and off, what
/// the auto apply screen and Settings say.
void main() {
  late FakeAuth auth;
  late FakeLinks links;
  late FakeBackground background;
  late FakeNotifications notifications;

  const twoStep = 'https://myaccount.google.com/signinoptions/twosv';
  const appPasswords = 'https://myaccount.google.com/apppasswords';

  setUp(() {
    auth = FakeAuth()..session = testSession(email: 'sara.ali@gmail.com');
    links = FakeLinks();
    background = FakeBackground();
    notifications = FakeNotifications();
  });
  tearDown(() => auth.dispose());

  Future<FakeApplicationsApi> pumpApp(
    WidgetTester tester, {
    FakeApplicationsApi? applications,
    String? language,
  }) async {
    usePhoneSize(tester);
    final apps = applications ?? FakeApplicationsApi();
    await tester.pumpWidget(
      ProviderScope(
        overrides: await baseOverrides(
          auth: auth,
          applications: apps,
          links: links,
          background: background,
          notifications: notifications,
          prefs: await testPreferences({SettingsController.localeKey: ?language}),
        ),
        retry: (_, _) => null,
        child: const AutolinkyApp(),
      ),
    );
    await settle(tester);
    return apps;
  }

  /// What the user copied (at Google's App passwords page, or anything else); null: nothing.
  void clipboardHolds(WidgetTester tester, String? text) {
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.getData' && text != null ? <String, Object?>{'text': text} : null,
    );
    addTearDown(() => messenger.setMockMethodCallHandler(SystemChannels.platform, null));
  }

  bool switchedOn(WidgetTester tester) => tester.widget<Switch>(find.byType(Switch)).value;

  String fieldText(WidgetTester tester, String label) =>
      tester.widget<TextField>(find.widgetWithText(TextField, label)).controller!.text;

  testWidgets('the home switch, the first time: Gmail step by step, then on, and what it does', (tester) async {
    final apps = await pumpApp(tester);
    // off, and why the switch first takes a moment
    expect(find.text('Off · One-time Gmail setup, about 2 minutes'), findsOneWidget);
    expect(find.text('20 of 20 free applications left'), findsOneWidget);
    expect(switchedOn(tester), isFalse);
    await tester.tap(find.byType(Switch));
    await settle(tester);

    // 1. 2-Step Verification, at Google
    expect(find.text('Connect Gmail'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.text('3 quick steps · about 2 minutes'), findsOneWidget);
    expect(find.text('Turn on 2-Step Verification'), findsOneWidget);
    await tester.tap(find.text('Open 2-Step Verification'));
    await settle(tester);
    expect(links.opened.last.toString(), twoStep);
    expect(find.textContaining('Welcome back!'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await settle(tester);

    // 2. an app password: what to type and tap there, then back with it copied
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text('Create an app password'), findsOneWidget);
    expect(find.text('Type Autolinky as the app name, then tap Create'), findsOneWidget);
    clipboardHolds(tester, 'abcd efgh ijkl mnop');
    await tester.tap(find.text('Open App passwords'));
    await settle(tester);
    expect(links.opened.last.toString(), appPasswords);

    // 3. pasted for the user; the address is the account's own Gmail, the name already there
    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(find.text('Pasted the app password you copied.'), findsOneWidget);
    expect(fieldText(tester, 'App password'), 'abcd efgh ijkl mnop');
    expect(find.text('16 of 16 letters'), findsOneWidget);
    expect(find.text('Sends from'), findsOneWidget);
    expect(find.text('sara.ali@gmail.com'), findsOneWidget);
    expect(fieldText(tester, 'Your name'), 'Sara Ali');
    expect(apps.gmailCalls, isEmpty);
    await tester.tap(find.widgetWithText(FilledButton, 'Connect and turn on'));
    await settle(tester);

    // connected, then on at once, with the saved choices
    expect(apps.gmailCalls, [('sara.ali@gmail.com', 'Sara Ali', 'abcdefghijklmnop')]);
    expect(apps.signatures, [null]); // the CV's signature, as it is
    expect(apps.autoApplyCalls, [
      {'enabled': true},
    ]);
    expect(notifications.asked, 1);
    expect(background.starts, greaterThan(0));
    expect(find.text('Gmail connected'), findsNothing); // said by what follows

    // what it does now, and the way to change it
    expect(find.text("You're all set!"), findsOneWidget);
    expect(find.text('sara.ali@gmail.com'), findsOneWidget);
    expect(find.text('Jobs that fit you 70% or more'), findsOneWidget);
    expect(find.text('Up to 20 CVs a day, at least 5 min apart'), findsOneWidget);
    expect(find.textContaining('You can close Autolinky'), findsOneWidget);
    expect(find.text('Adjust settings'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(find.text("You're all set!"), findsNothing);
    expect(find.text('On · 0 sent today · 4 jobs waiting'), findsOneWidget);
    expect(switchedOn(tester), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the setup: skipped steps, a refused app password, a new one; closed: still off', (tester) async {
    final apps = await pumpApp(tester);
    await tester.tap(find.byType(Switch));
    await settle(tester);
    await tester.tap(find.text("It's already on"));
    await settle(tester);
    expect(find.text('Step 2 of 3'), findsOneWidget);
    await tester.tap(find.text('I already have one'));
    await settle(tester);
    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(find.text('Pasted the app password you copied.'), findsNothing);
    expect(links.opened, isEmpty);

    // typed by hand: not an app password, said before asking anyone
    await tester.enterText(find.widgetWithText(TextField, 'App password'), 'mypassword');
    await tester.pump();
    expect(find.text('10 of 16 letters'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Connect and turn on'));
    await settle(tester);
    expect(find.text('An app password is 16 letters, like abcd efgh ijkl mnop.'), findsOneWidget);
    expect(apps.gmailCalls, isEmpty);

    // Gmail refuses it: said under the field, and a new one is one tap away (step 2 again)
    apps.refuseGmail = 'wrong_app_password';
    await tester.enterText(find.widgetWithText(TextField, 'App password'), 'ABCD-EFGH-IJKL-MNOP');
    await tester.tap(find.widgetWithText(FilledButton, 'Connect and turn on'));
    await settle(tester);
    expect(apps.gmailCalls.single.$3, 'abcdefghijklmnop');
    expect(find.textContaining("Gmail didn't accept this app password"), findsOneWidget);
    await tester.tap(find.text('Make a new one'));
    await settle(tester);
    expect(find.text('Step 2 of 3'), findsOneWidget);
    await tester.tap(find.text('I already have one'));
    await settle(tester);
    expect(fieldText(tester, 'App password'), isEmpty); // the refused one is gone

    // back, step by step, then closed: nothing turned on
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    await tester.tap(find.byType(CloseButton));
    await settle(tester);
    expect(find.text('Connect Gmail'), findsNothing);
    expect(apps.autoApplyCalls, isEmpty);
    expect(switchedOn(tester), isFalse);
    expect(find.text('Off · One-time Gmail setup, about 2 minutes'), findsOneWidget);
  });

  testWidgets('Gmail connected: the switch turns it on and off at once; off can be undone', (tester) async {
    final apps = FakeApplicationsApi()
      ..emailConnected = true
      ..autoApplyOn = true
      ..sentToday = 3;
    await pumpApp(tester, applications: apps);
    expect(find.text('On · 3 sent today · 4 jobs waiting'), findsOneWidget);
    expect(switchedOn(tester), isTrue);
    final starts = background.starts; // started with the app: auto apply is on

    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(apps.autoApplyCalls.last, {'enabled': false});
    expect(background.stops, greaterThan(0));
    expect(switchedOn(tester), isFalse);
    expect(find.text('Off · Sends your CV to new jobs that fit you'), findsOneWidget);
    expect(find.text('Auto apply is off'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(apps.autoApplyCalls.last, {'enabled': true});
    expect(find.text('Connect Gmail'), findsNothing); // no setup: Gmail is there
    expect(notifications.asked, 1);
    expect(background.starts, greaterThan(starts));
    expect(switchedOn(tester), isTrue);
    expect(find.text('On · 3 sent today · 4 jobs waiting'), findsOneWidget);
    expect(find.text('Auto apply is on'), findsOneWidget);

    // the way to its choices
    await tester.tap(find.text('Manage'));
    await settle(tester);
    expect(find.text('3 of 20 CVs sent today'), findsOneWidget);
  });

  testWidgets('the auto apply screen: "Start" with the choices made, the Gmail setup first', (tester) async {
    final apps = await pumpApp(tester);
    await tester.tap(find.text('Off · One-time Gmail setup, about 2 minutes')); // the card
    await settle(tester);

    // off: the choices, how it sends, and the Gmail it needs
    expect(find.text('Auto apply is off'), findsOneWidget);
    expect(find.text('Connect your Gmail'), findsOneWidget);
    expect(find.textContaining('at least the minutes you chose apart'), findsOneWidget);
    expect(find.textContaining('up to 500 e-mails a day'), findsOneWidget); // what is safe for Gmail
    await tester.ensureVisible(find.text('80%'));
    await settle(tester);
    await tester.tap(find.text('80%'));
    await tester.ensureVisible(find.text('10').first);
    await settle(tester);
    await tester.tap(find.text('10').first); // CVs a day (the minutes' choices come after)
    await tester.ensureVisible(find.text('Minutes between two CVs, at least'));
    await settle(tester);
    await tester.tap(find.text('3').last);
    await settle(tester);
    expect(apps.autoApplyCalls, isEmpty); // kept for "Start"

    await tester.tap(find.widgetWithText(FilledButton, 'Start auto apply'));
    await settle(tester);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    await tester.tap(find.text("It's already on"));
    await settle(tester);
    await tester.tap(find.text('I already have one'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'App password'), 'abcd efgh ijkl mnop');
    await tester.tap(find.widgetWithText(FilledButton, 'Connect and turn on'));
    await settle(tester);
    expect(apps.gmailCalls, [('sara.ali@gmail.com', 'Sara Ali', 'abcdefghijklmnop')]);
    expect(apps.autoApplyCalls, [
      {'enabled': true, 'min_match': 80, 'daily_limit': 10, 'gap_minutes': 3},
    ]);
    expect(notifications.asked, 1);
    expect(background.starts, greaterThan(0));

    // on: how it goes, and the way out
    expect(find.text('Auto apply is on'), findsWidgets);
    expect(find.text('0 of 10 CVs sent today'), findsOneWidget);
    expect(find.text('4 jobs waiting'), findsOneWidget);
    expect(find.textContaining('You can close Autolinky'), findsOneWidget);
    expect(find.text('Connect your Gmail'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue in background'));
    await settle(tester);
    expect(find.text('On · 0 sent today · 4 jobs waiting'), findsOneWidget);
    expect(switchedOn(tester), isTrue);
  });

  testWidgets("while on: choices change at once; turning it off stops the phone's background check", (tester) async {
    final apps = FakeApplicationsApi()
      ..emailConnected = true
      ..autoApplyOn = true
      ..sentToday = 3;
    await pumpApp(tester, applications: apps);
    await tester.tap(find.text('On · 3 sent today · 4 jobs waiting'));
    await settle(tester);
    expect(find.text('3 of 20 CVs sent today'), findsOneWidget);
    // A choice changes at once while it is on, after scrolling it above the fixed action bar.
    await tester.ensureVisible(find.text('60%'));
    await settle(tester);
    await tester.tap(find.text('60%'));
    await settle(tester);
    expect(apps.autoApplyCalls.last, {'min_match': 60});
    // the lowest choices: 40% and 50%
    expect(find.text('40%'), findsOneWidget);
    await tester.tap(find.text('40%'));
    await settle(tester);
    expect(apps.autoApplyCalls.last, {'min_match': 40});
    expect(find.text('50%'), findsOneWidget);
    // ... the minutes between two CVs too (5 by default)
    await tester.ensureVisible(find.text('Minutes between two CVs, at least'));
    await settle(tester);
    await tester.tap(find.text('20').last);
    await settle(tester);
    expect(apps.autoApplyCalls.last, {'gap_minutes': 20});
    await tester.ensureVisible(find.text('Turn off auto apply'));
    await settle(tester);
    await tester.tap(find.text('Turn off auto apply'));
    await settle(tester);
    expect(apps.autoApplyCalls.last, {'enabled': false});
    expect(background.stops, greaterThan(0));
    expect(find.widgetWithText(FilledButton, 'Start auto apply'), findsOneWidget);
  });

  testWidgets('a Gmail that stopped working: the card says so; "Fix Gmail" starts at step 2', (tester) async {
    final apps = FakeApplicationsApi()
      ..emailConnected = false
      ..email = const MailAccount(address: 'sara.ali@gmail.com', status: MailStatus.invalid, error: 'auth')
      ..autoApplyOn = true
      ..problem = AutoApplyProblem.emailInvalid;
    await pumpApp(tester, applications: apps);
    expect(find.text('Needs your attention'), findsOneWidget);
    expect(find.textContaining('Gmail stopped accepting your app password'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Fix Gmail'));
    await settle(tester);

    // step 2 at once, saying why
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text('Gmail stopped accepting your app password. Make a new one: it takes 2 minutes.'), findsOneWidget);
    clipboardHolds(tester, 'wxyz wxyz wxyz wxyz');
    await tester.tap(find.text('Open App passwords'));
    await settle(tester);
    expect(find.text('Pasted the app password you copied.'), findsOneWidget);
    apps.problem = null; // what the API says once the new one works
    await tester.tap(find.widgetWithText(FilledButton, 'Check and connect'));
    await settle(tester);
    expect(apps.gmailCalls.single, ('sara.ali@gmail.com', 'Sara Ali', 'wxyzwxyzwxyzwxyz'));
    expect(find.text('Gmail connected'), findsOneWidget);
    expect(find.text('Needs your attention'), findsNothing);
    expect(find.text('On · 0 sent today · 4 jobs waiting'), findsOneWidget);
  });

  testWidgets('Settings: the Gmail and auto apply; disconnecting asks first', (tester) async {
    final apps = FakeApplicationsApi()
      ..emailConnected = true
      ..email = const MailAccount(address: 'sara.ali@gmail.com', senderName: 'Sara Ali');
    await pumpApp(tester, applications: apps);
    await tester.tap(find.text('Profile'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined).first);
    await settle(tester);
    expect(find.text('Applying'), findsOneWidget);
    expect(find.text('sara.ali@gmail.com · Connected'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget);

    await tester.tap(find.text('Gmail'));
    await settle(tester);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Leave it empty to keep the saved one.'), findsOneWidget);
    await tester.ensureVisible(find.text('Disconnect Gmail'));
    await settle(tester);
    await tester.tap(find.text('Disconnect Gmail'));
    await settle(tester);
    expect(find.text('Disconnect Gmail?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Disconnect Gmail').last);
    await settle(tester);
    expect(apps.emailConnected, isFalse);
    expect(find.text('Not connected'), findsOneWidget);

    // none any more: the tile opens the step by step setup
    await tester.tap(find.text('Gmail'));
    await settle(tester);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    await tester.tap(find.byType(CloseButton));
    await settle(tester);
    expect(find.text('Applying'), findsOneWidget);
  });

  testWidgets("the signature can be the user's own, or the CV's again", (tester) async {
    final apps = FakeApplicationsApi()
      ..emailConnected = true
      ..email = const MailAccount(address: 'sara.ali@gmail.com', senderName: 'Sara Ali', signature: '📞 0100');
    await pumpApp(tester, applications: apps);
    await tester.tap(find.text('Profile'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined).first);
    await settle(tester);
    await tester.tap(find.text('Gmail'));
    await settle(tester);
    final field = find.widgetWithText(TextFormField, 'Signature');
    expect(find.text('📞 0100'), findsOneWidget); // the saved one, not the CV's
    await tester.enterText(field, '📞 +20 100 000 0000\n🔗 linkedin.com/in/sara');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);
    expect(apps.gmailCalls.last.$3, isNull); // no new app password needed
    expect(apps.signatures.last, '📞 +20 100 000 0000\n🔗 linkedin.com/in/sara');

    await tester.tap(find.text('Gmail'));
    await settle(tester);
    await tester.ensureVisible(find.text('Use the one from my CV'));
    await settle(tester);
    await tester.tap(find.text('Use the one from my CV'));
    await settle(tester);
    expect(find.text('📧 sara.ali@gmail.com\n📞 +201001234567'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(tester);
    expect(apps.signatures.last, '');
  });

  testWidgets('in Arabic', (tester) async {
    await pumpApp(tester, language: 'ar');
    expect(find.text('متوقف · إعداد Gmail لمرة واحدة، نحو دقيقتين'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await settle(tester);
    expect(find.text('ربط Gmail'), findsOneWidget);
    expect(find.text('الخطوة 1 من 3'), findsOneWidget);
    expect(find.text('فعّل التحقق بخطوتين'), findsOneWidget);
    await tester.tap(find.text('مفعّل بالفعل'));
    await settle(tester);
    expect(find.text('أنشئ كلمة مرور تطبيق'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
