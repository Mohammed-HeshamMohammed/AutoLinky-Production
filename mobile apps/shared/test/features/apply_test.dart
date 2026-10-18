import 'package:autolinky/app/app.dart';
import 'package:autolinky/core/config/providers.dart';
import 'package:autolinky/core/errors/app_failure.dart';
import 'package:autolinky/core/widgets/states.dart';
import 'package:autolinky/features/applications/data/applications_repository.dart';
import 'package:autolinky/features/explore/presentation/explore_screen.dart';
import 'package:autolinky/features/jobs/application/external_apps.dart';
import 'package:autolinky/features/jobs/application/jobs_providers.dart';
import 'package:autolinky/features/jobs/data/apply_channel.dart';
import 'package:autolinky/features/matches/data/models.dart';
import 'package:autolinky/features/settings/application/settings_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers.dart';

void main() {
  late FakeAuth auth;
  late FakeLinks links;

  setUpAll(() => registerFallbackValue(<String, Object?>{}));
  setUp(() {
    auth = FakeAuth()..session = testSession();
    links = FakeLinks();
  });
  tearDown(() => auth.dispose());

  /// The app on "For you", with every job of [matches] / [explore] known to the applications API.
  Future<FakeApplicationsApi> pumpApp(
    WidgetTester tester, {
    FakeMatchesApi? matches,
    FakeJobsApi? jobs,
    FakeApplicationsApi? applications,
    FakeProfileApi? profiles,
    String? language,
    Map<String, Object> saved = const {},
  }) async {
    usePhoneSize(tester);
    final matched = matches ?? FakeMatchesApi();
    final listed = jobs ?? FakeJobsApi();
    final apps =
        applications ??
        FakeApplicationsApi(
          jobs: {for (final m in matched.jobs) m.job.id: m.job, for (final j in listed.jobs) j.id: j},
        );
    await tester.pumpWidget(
      ProviderScope(
        overrides: await baseOverrides(
          auth: auth,
          matches: matched,
          jobs: listed,
          applications: apps,
          links: links,
          profiles: profiles,
          prefs: await testPreferences({SettingsController.localeKey: ?language, ...saved}),
        ),
        retry: (_, _) => null,
        child: const AutolinkyApp(),
      ),
    );
    await settle(tester);
    return apps;
  }

  Finder tab(String name) => find.descendant(of: find.byType(TabBar), matching: find.text(name));

  /// Scroll actions into their real hit region before tapping, as a phone user does.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await settle(tester);
    expect(finder.hitTestable(), findsOneWidget, reason: 'The action must be visible and tappable.');
    await tester.tap(finder);
  }

  /// The tab bar scrolls sideways on a phone: brought into view first, as a user does.
  Future<void> openTab(WidgetTester tester, String name) async {
    await tester.ensureVisible(tab(name));
    await settle(tester);
    await tapVisible(tester, tab(name));
    await settle(tester);
  }

  /// A job for every way to apply.
  List<MatchedJob> everyWay() => [
    testJob(0, title: 'Email job', methods: {ApplyMethod.email}),
    testJob(1, title: 'WhatsApp job', methods: {ApplyMethod.whatsapp, ApplyMethod.email}),
    testJob(2, title: 'Phone job', methods: {ApplyMethod.phone}),
    testJob(3, title: 'Link job', methods: {ApplyMethod.link}),
    testJob(4, title: 'Easy job', methods: {ApplyMethod.easyApply}, source: JobSource.linkedinJob),
    testJob(5, title: 'Site job', methods: {ApplyMethod.external}, source: JobSource.linkedinJob),
    testJob(6, title: 'DM job', methods: {ApplyMethod.dm}),
    testJob(7, title: 'Comment job', methods: {ApplyMethod.comment}),
  ];

  group('the tabs of "For you"', () {
    testWidgets('a tab per way to apply, then Applied; each asks the API for its own jobs', (tester) async {
      final api = FakeMatchesApi(jobs: everyWay());
      await pumpApp(tester, matches: api);
      for (final name in ['Auto apply', 'Easy Apply', 'WhatsApp', 'Apply link', 'Company site', 'Message', 'Comment']) {
        expect(tab(name), findsOneWidget, reason: name);
      }
      expect(tab('Applied'), findsOneWidget);
      // Auto apply first: the e-mail jobs only
      expect(find.text('Email job'), findsOneWidget);
      expect(find.text('Easy job'), findsNothing);

      await openTab(tester, 'WhatsApp');
      expect(api.channels.last, ApplyChannel.whatsapp);
      expect(find.text('WhatsApp job'), findsOneWidget);
      // The second lazy card may be below the first viewport.
      await tester.scrollUntilVisible(
        find.text('Phone job'),
        240,
        scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first,
      );
      expect(find.text('Phone job'), findsOneWidget); // a plain number: WhatsApp too
      expect(find.text('Email job'), findsNothing);

      await openTab(tester, 'Easy Apply');
      expect(find.text('Easy job'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Easy Apply'), findsOneWidget);
    });

    testWidgets('the Applied tab counts and lists the jobs applied to, with how', (tester) async {
      final applied = [
        Application(
          job: testListJob(0, title: 'Sent by WhatsApp'),
          state: ApplicationState(
            method: ApplyMethod.whatsapp,
            status: ApplicationStatus.applied,
            appliedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ),
        Application(
          job: testListJob(1, title: 'Easy one', source: JobSource.linkedinJob),
          state: ApplicationState(
            method: ApplyMethod.easyApply,
            status: ApplicationStatus.applied,
            appliedAt: DateTime.now(),
          ),
        ),
      ];
      final apps = await pumpApp(tester, applications: FakeApplicationsApi(applied: applied));
      expect(find.descendant(of: find.byType(TabBar), matching: find.text('2')), findsOneWidget); // the count
      await openTab(tester, 'Applied');
      expect(find.text('2 applications'), findsOneWidget);
      expect(find.text('Sent by WhatsApp'), findsOneWidget);
      expect(find.text('Via WhatsApp'), findsOneWidget);
      expect(find.text('Applied · 2 days ago'), findsOneWidget);
      expect(find.text('Via Easy Apply'), findsOneWidget);

      // "I did not apply after all"
      await tapVisible(tester, find.byTooltip('More options').first);
      await settle(tester);
      await tapVisible(tester, find.text('Remove from Applied'));
      await settle(tester);
      expect(apps.withdrawn, ['job-0']);
      expect(find.text('Sent by WhatsApp'), findsNothing);
      expect(find.text('1 application'), findsOneWidget);
    });

    testWidgets('an e-mail already sent stays in Applied, and says why', (tester) async {
      final apps = FakeApplicationsApi(
        applied: [
          Application(
            job: testListJob(0),
            state: ApplicationState(
              method: ApplyMethod.email,
              status: ApplicationStatus.sent,
              appliedAt: DateTime.now(),
            ),
          ),
        ],
      )..failWithdraw = const ApiFailure(statusCode: 409, code: 'already_sent');
      await pumpApp(tester, applications: apps);
      await openTab(tester, 'Applied');
      expect(find.text('CV sent · Just now'), findsOneWidget);
      await tapVisible(tester, find.byTooltip('More options'));
      await settle(tester);
      await tapVisible(tester, find.text('Remove from Applied'));
      await settle(tester);
      expect(find.textContaining('already emailed'), findsOneWidget);
      expect(find.text('Network Engineer 0'), findsOneWidget);
    });

    testWidgets('nothing applied yet: the Applied tab says what it is for', (tester) async {
      await pumpApp(tester);
      await openTab(tester, 'Applied');
      expect(find.text('No applications yet'), findsOneWidget);
    });
  });

  group('applying', () {
    testWidgets('WhatsApp: a chat with the number and an English message ready; then "Did you apply?"', (tester) async {
      final apps = await pumpApp(tester, matches: FakeMatchesApi(jobs: everyWay()));
      await openTab(tester, 'WhatsApp');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'WhatsApp').first);
      await settle(tester);

      final chat = links.opened.single;
      expect(chat.host, 'wa.me');
      expect(chat.path, '/201001234567');
      expect(chat.queryParameters['text'], 'Kindly find my attached CV for the position of WhatsApp job.');
      expect(chat.toString(), contains('%20')); // spaces as %20: WhatsApp would show a "+"
      expect(find.text('Did you apply?'), findsOneWidget);

      await tapVisible(tester, find.text('Yes, I applied'));
      await settle(tester);
      expect(apps.recorded, [('job-1', ApplyMethod.whatsapp)]);
      expect(find.text('Added to Applied'), findsOneWidget);
      expect(find.text('WhatsApp job'), findsNothing); // gone from its tab at once: it is in Applied now
      expect(find.descendant(of: find.byType(TabBar), matching: find.text('1')), findsOneWidget);
      await openTab(tester, 'Applied');
      expect(find.text('Network Engineer 1'), findsOneWidget); // the fake API names it by its id
      expect(find.text('Applied · Just now'), findsOneWidget);
    });

    testWidgets('a job applied to leaves its tabs; taken out of Applied, it comes back', (tester) async {
      await pumpApp(tester, matches: FakeMatchesApi(jobs: everyWay()));
      await openTab(tester, 'WhatsApp');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'WhatsApp').first);
      await settle(tester);
      await tapVisible(tester, find.text('Yes, I applied'));
      await settle(tester);
      expect(find.text('WhatsApp job'), findsNothing);

      // the same job is in the Auto apply tab too (it offers e-mail): applied is applied, wherever it was
      await openTab(tester, 'Auto apply');
      expect(find.text('WhatsApp job'), findsNothing);

      await openTab(tester, 'Applied');
      await tapVisible(tester, find.byTooltip('More options').first);
      await settle(tester);
      await tapVisible(tester, find.text('Remove from Applied'));
      await settle(tester);
      await openTab(tester, 'WhatsApp');
      expect(find.text('WhatsApp job'), findsOneWidget);
    });

    testWidgets('an e-mail Gmail refused stays in its tab, to be sent again', (tester) async {
      final failed = ApplicationState(
        method: ApplyMethod.email,
        status: ApplicationStatus.failed,
        appliedAt: DateTime.now(),
      );
      await pumpApp(
        tester,
        matches: FakeMatchesApi(jobs: [testJob(0, application: failed)]),
      );
      expect(find.text('Network Engineer 0'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Send again'), findsOneWidget);
    });

    testWidgets('the details are not loaded yet and the network is slow: the button still works', (tester) async {
      final jobs = FakeJobsApi()..detailDelay = const Duration(milliseconds: 800);
      final apps = await pumpApp(
        tester,
        matches: FakeMatchesApi(jobs: everyWay()),
        jobs: jobs,
      );
      await openTab(tester, 'WhatsApp');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'WhatsApp').first);
      await tester.pump(const Duration(seconds: 2));
      await settle(tester);
      expect(find.textContaining('Something went wrong'), findsNothing);
      expect(links.opened.single.host, 'wa.me');
      expect(find.text('Did you apply?'), findsOneWidget);
      await tapVisible(tester, find.text('Not yet'));
      await settle(tester);

      // a second time: the details are kept, no new call
      await tapVisible(tester, find.widgetWithText(FilledButton, 'WhatsApp').first);
      await settle(tester);
      expect(jobs.detailCalls, ['job-1']);
      expect(apps.recorded, isEmpty);
    });

    testWidgets('a failed load of the details can be tried again by the button', (tester) async {
      final jobs = FakeJobsApi()..failDetail = const NetworkFailure();
      await pumpApp(
        tester,
        matches: FakeMatchesApi(jobs: everyWay()),
        jobs: jobs,
      );
      await openTab(tester, 'Apply link');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Open the link'));
      await settle(tester);
      expect(find.textContaining('No internet connection'), findsOneWidget);
      expect(links.opened, isEmpty);
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Open the link'));
      await settle(tester);
      expect(links.opened.single.toString(), 'https://forms.gle/apply123');
    });

    testWidgets('"Not yet" saves nothing', (tester) async {
      final apps = await pumpApp(tester, matches: FakeMatchesApi(jobs: everyWay()));
      await openTab(tester, 'Apply link');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Open the link'));
      await settle(tester);
      expect(links.opened.single.toString(), 'https://forms.gle/apply123');
      await tapVisible(tester, find.text('Not yet'));
      await settle(tester);
      expect(apps.recorded, isEmpty);
      expect(find.widgetWithText(FilledButton, 'Open the link'), findsOneWidget);
    });

    testWidgets('LinkedIn: Easy Apply and the company site open the job on LinkedIn', (tester) async {
      final jobs = FakeJobsApi();
      final apps = await pumpApp(
        tester,
        matches: FakeMatchesApi(jobs: everyWay()),
        jobs: jobs,
      );
      await openTab(tester, 'Easy Apply');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Easy Apply'));
      await settle(tester);
      expect(links.opened.last.toString(), 'https://www.linkedin.com/jobs/view/4/');
      await tapVisible(tester, find.text('Yes, I applied'));
      await settle(tester);

      await openTab(tester, 'Company site');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Apply on their site'));
      await settle(tester);
      expect(links.opened.last.toString(), 'https://www.linkedin.com/jobs/view/5/');
      await tapVisible(tester, find.text('Yes, I applied'));
      await settle(tester);
      expect(apps.recorded, [('job-4', ApplyMethod.easyApply), ('job-5', ApplyMethod.external)]);
      expect(jobs.detailCalls, isEmpty); // the link is in the list: no extra call
    });

    testWidgets('a message opens the profile of who posted; a comment opens the post', (tester) async {
      await pumpApp(tester, matches: FakeMatchesApi(jobs: everyWay()));
      await openTab(tester, 'Message');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Send a message'));
      await settle(tester);
      expect(links.opened.last.toString(), 'https://www.linkedin.com/in/sara-hr');
      await tapVisible(tester, find.text('Not yet'));
      await settle(tester);

      await openTab(tester, 'Comment');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Comment'));
      await settle(tester);
      expect(links.opened.last.toString(), 'https://www.linkedin.com/feed/update/urn:li:activity:1/');
    });

    testWidgets('nothing could open it, or the user never left: no question', (tester) async {
      final apps = await pumpApp(tester, matches: FakeMatchesApi(jobs: everyWay()));
      await openTab(tester, 'Apply link');
      links.opens = false;
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Open the link'));
      await settle(tester);
      expect(find.text("Couldn't open it on this phone."), findsOneWidget);
      expect(find.text('Did you apply?'), findsNothing);

      links
        ..opens = true
        ..comesBack = false;
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Open the link'));
      await settle(tester);
      expect(find.text('Did you apply?'), findsNothing);
      expect(apps.recorded, isEmpty);
    });

    testWidgets('a way the job no longer gives says so, and opens nothing', (tester) async {
      final job = testJob(3, title: 'Link job', methods: {ApplyMethod.link});
      final jobs = FakeJobsApi(
        details: {'job-3': JobDetail(job: job.job, description: 'No link any more')},
      );
      await pumpApp(
        tester,
        matches: FakeMatchesApi(jobs: [job]),
        jobs: jobs,
      );
      await openTab(tester, 'Apply link');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Open the link'));
      await settle(tester);
      expect(find.text("This way to apply isn't in the job any more."), findsOneWidget);
      expect(links.opened, isEmpty);
    });

    testWidgets('"Send my CV" the first time: the Gmail setup, then what is sent, then sent', (tester) async {
      auth.session = testSession(email: 'sara.ali@gmail.com'); // signed in with the Gmail that sends
      final matches = FakeMatchesApi();
      final apps = FakeApplicationsApi(jobs: {for (final m in matches.jobs) m.job.id: m.job});
      await pumpApp(tester, matches: matches, applications: apps);
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Send my CV').first);
      await settle(tester);

      // the setup, step by step, with the way to Google's pages
      expect(find.text('Connect Gmail'), findsOneWidget);
      expect(find.text('Step 1 of 3'), findsOneWidget);
      await tapVisible(tester, find.text("It's already on"));
      await settle(tester);
      // back from App passwords with something else copied: left alone, the user goes on
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => call.method == 'Clipboard.getData' ? <String, Object?>{'text': 'https://example.com'} : null,
      );
      addTearDown(() => messenger.setMockMethodCallHandler(SystemChannels.platform, null));
      await tapVisible(tester, find.text('Open App passwords'));
      await settle(tester);
      expect(links.opened.last.toString(), 'https://myaccount.google.com/apppasswords');
      expect(find.text('Step 2 of 3'), findsOneWidget);
      await tapVisible(tester, find.text('I copied it'));
      await settle(tester);
      expect(find.text('Step 3 of 3'), findsOneWidget);
      // the address is the account's own Gmail: shown, not typed
      expect(find.text('Sends from'), findsOneWidget);
      expect(find.text('sara.ali@gmail.com'), findsOneWidget);
      final password = find.widgetWithText(TextField, 'App password');
      expect(tester.widget<TextField>(password).controller!.text, isEmpty);
      await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Sara Ali');

      // not an app password: said before asking anyone
      await tester.enterText(password, 'mypassword');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Check and connect'));
      await settle(tester);
      expect(find.textContaining('An app password is 16 letters'), findsOneWidget);
      expect(apps.gmailCalls, isEmpty);

      // Gmail refuses it: said under the field, the screen stays, with the way to a new one
      apps.refuseGmail = 'wrong_app_password';
      await tester.enterText(password, 'abcd efgh ijkl mnop');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Check and connect'));
      await settle(tester);
      expect(find.textContaining("Gmail didn't accept this app password"), findsOneWidget);
      expect(find.text('Make a new one'), findsOneWidget);

      // accepted: back to the job, and what is about to go
      apps.refuseGmail = null;
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Check and connect'));
      await settle(tester);
      expect(apps.gmailCalls.last, ('sara.ali@gmail.com', 'Sara Ali', 'abcdefghijklmnop'));
      expect(find.text('Send your CV?'), findsOneWidget);
      expect(find.text('sara.ali@gmail.com'), findsOneWidget);
      expect(find.text('hr@vodafone.example'), findsOneWidget);
      expect(find.text('Application for Network Engineer 0 – Sara Ali'), findsOneWidget);
      expect(find.text('Sara Ali - CV.pdf'), findsOneWidget);
      expect(find.textContaining('Dear Vodafone Egypt Hiring Team'), findsOneWidget);
      expect(find.text('Written for this job from your CV. You can change it before sending.'), findsOneWidget);
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Send'));
      await settle(tester);
      expect(apps.recorded, [('job-0', ApplyMethod.email)]);
      expect(apps.letters.single, startsWith('Dear Vodafone Egypt Hiring Team,'));
      expect(apps.letters.single, endsWith('📞 +201001234567')); // signed with the CV's contacts
      expect(find.text('CV sent to hr@vodafone.example'), findsOneWidget);
      expect(links.opened.where((u) => u.host != 'myaccount.google.com'), isEmpty); // nothing else opened

      // the next time: straight to what is sent (the setup only once)
      tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).clearSnackBars();
      await settle(tester);
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Send my CV').first);
      await settle(tester);
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Send my CV').first);
      await settle(tester);
      expect(find.text('Connect Gmail'), findsNothing);
      expect(find.text('Send your CV?'), findsOneWidget);
    });

    testWidgets('the letter can be changed before it goes; an empty one cannot go', (tester) async {
      final apps = FakeApplicationsApi()..emailConnected = true;
      await pumpApp(tester, applications: apps);
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Send my CV').first);
      await settle(tester);
      final letter = find.widgetWithText(TextField, 'Letter');
      await tester.enterText(letter, '   ');
      await tester.pump();
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Send')).onPressed, isNull);
      await tester.enterText(letter, 'Dear team,\n\nMy own words.\n\nSara');
      await tester.pump();
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Send'));
      await settle(tester);
      expect(apps.letters, ['Dear team,\n\nMy own words.\n\nSara']);
    });

    testWidgets('a CV Gmail refused to deliver says why and can be sent again', (tester) async {
      final matches = FakeMatchesApi();
      final apps = FakeApplicationsApi(jobs: {for (final m in matches.jobs) m.job.id: m.job})
        ..emailConnected = true
        ..sendFails = 'address_refused';
      await pumpApp(tester, matches: matches, applications: apps);
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Send my CV').first);
      await settle(tester);
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Send'));
      await settle(tester);
      expect(find.text("Not sent: the job's address refused it."), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Send again'), findsOneWidget);
    });

    testWidgets('Gmail saying "wait" is said in words, and nothing is recorded as applied', (tester) async {
      final apps = FakeApplicationsApi()
        ..emailConnected = true
        ..failRecord = const ApiFailure(statusCode: 429, code: 'gmail_limit');
      await pumpApp(tester, applications: apps);
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Send my CV').first);
      await settle(tester);
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Send'));
      await settle(tester);
      expect(find.text("Gmail's daily sending limit is reached. Try again tomorrow."), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Send my CV'), findsWidgets);
    });

    testWidgets('without a CV nothing can be sent', (tester) async {
      final apps = FakeApplicationsApi()
        ..emailConnected = true
        ..hasCv = false;
      await pumpApp(tester, applications: apps);
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Send my CV').first);
      await settle(tester);
      expect(find.text("Upload your CV first: it's what gets attached."), findsOneWidget);
      final send = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Send'));
      expect(send.onPressed, isNull);
    });
  });

  group('the details', () {
    testWidgets('"Show details": the post, every way to apply with where it goes, and Apply', (tester) async {
      final apps = await pumpApp(tester, matches: FakeMatchesApi(jobs: everyWay()));
      await openTab(tester, 'WhatsApp');
      await tapVisible(tester, find.text('Show details').first);
      await settle(tester);
      expect(find.text('The post'), findsOneWidget);
      expect(find.textContaining('We are hiring a Network Engineer.'), findsOneWidget);
      expect(find.text('Ways to apply'), findsOneWidget);
      expect(find.text('+201001234567'), findsOneWidget); // where WhatsApp goes
      expect(find.text('hr@vodafone.example'), findsOneWidget); // the job's e-mail way too

      // the sheet's Apply: the tab's way
      await tapVisible(tester, find.descendant(of: find.byType(BottomActionBar), matching: find.text('WhatsApp')));
      await settle(tester);
      expect(links.opened.single.host, 'wa.me');
      await tapVisible(tester, find.text('Yes, I applied'));
      await settle(tester);
      expect(apps.recorded.single.$2, ApplyMethod.whatsapp);
    });

    testWidgets('a LinkedIn job: its description; a failed load says why and tries again', (tester) async {
      final jobs = FakeJobsApi()..failDetail = const NetworkFailure();
      await pumpApp(
        tester,
        matches: FakeMatchesApi(jobs: everyWay()),
        jobs: jobs,
      );
      await openTab(tester, 'Easy Apply');
      await tapVisible(tester, find.text('Show details'));
      await settle(tester);
      expect(find.text('Job description'), findsOneWidget);
      expect(find.textContaining('No internet connection'), findsOneWidget);
      await tapVisible(tester, find.widgetWithText(TextButton, 'Try again'));
      await settle(tester);
      expect(find.textContaining('We are hiring a Network Engineer.'), findsOneWidget);
    });

    testWidgets('a job already applied to is not in the tabs (it is in Applied)', (tester) async {
      final applied = ApplicationState(
        method: ApplyMethod.email,
        status: ApplicationStatus.applied,
        appliedAt: DateTime.now().subtract(const Duration(hours: 5)),
      );
      await pumpApp(
        tester,
        matches: FakeMatchesApi(jobs: [testJob(0, application: applied)]),
      );
      expect(find.text('Network Engineer 0'), findsNothing);
      expect(find.text('Applied · 5 hours ago'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Send my CV'), findsNothing);
    });
  });

  group('Explore', () {
    Future<void> openExplore(WidgetTester tester) async {
      await tapVisible(tester, find.text('Explore'));
      await settle(tester);
    }

    testWidgets('every job; search by words; keep one way to apply', (tester) async {
      final jobs = FakeJobsApi(
        jobs: [
          testListJob(0, title: 'Network Engineer'),
          testListJob(1, title: 'Data Analyst', methods: {ApplyMethod.whatsapp}),
          testListJob(
            2,
            title: 'Cloud Network Engineer',
            methods: {ApplyMethod.easyApply},
            source: JobSource.linkedinJob,
          ),
        ],
      );
      await pumpApp(tester, jobs: jobs);
      await openExplore(tester);
      expect(find.text('Newest first, from the last 30 days'), findsOneWidget);
      expect(find.text('Data Analyst'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'network');
      await tester.pump(const Duration(milliseconds: 100));
      expect(jobs.searches.last.$1, ''); // not at every letter: once the user pauses
      await tester.pump(const Duration(milliseconds: 400));
      await settle(tester);
      expect(jobs.searches.last.$1, 'network');
      expect(find.text('Data Analyst'), findsNothing);
      expect(find.text('Network Engineer'), findsOneWidget);
      expect(find.text('Cloud Network Engineer'), findsOneWidget);

      // the chips scroll sideways ("Not applied" first): brought into view, as a user does
      final chips = find.ancestor(of: find.byType(FilterChip), matching: find.byType(Scrollable)).first;
      await tester.scrollUntilVisible(find.widgetWithText(ChoiceChip, 'Easy Apply'), 120, scrollable: chips);
      await settle(tester);
      await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Easy Apply'));
      await settle(tester);
      expect(jobs.searches.last, ('network', ApplyChannel.easyApply));
      expect(find.text('Network Engineer'), findsNothing);
      expect(find.text('Cloud Network Engineer'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'pilot');
      await tester.testTextInput.receiveAction(TextInputAction.search); // the keyboard's search key: at once
      await settle(tester);
      expect(find.text('No jobs found'), findsOneWidget);
    });

    testWidgets('a job with several ways to apply: the user picks one', (tester) async {
      final jobs = FakeJobsApi(
        jobs: [
          testListJob(0, title: 'Two ways', methods: {ApplyMethod.email, ApplyMethod.whatsapp}),
        ],
      );
      final apps = await pumpApp(tester, jobs: jobs);
      await openExplore(tester);
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Apply'));
      await settle(tester);
      expect(find.text('How do you want to apply?'), findsOneWidget);
      await tapVisible(tester, find.widgetWithText(ListTile, 'WhatsApp'));
      await settle(tester);
      expect(links.opened.single.host, 'wa.me');
      await tapVisible(tester, find.text('Yes, I applied'));
      await settle(tester);
      expect(apps.recorded, [('job-0', ApplyMethod.whatsapp)]);
    });

    testWidgets('a job applied to says so on its card; "Not applied" leaves those out, and is kept', (tester) async {
      final applied = ApplicationState(
        method: ApplyMethod.whatsapp,
        status: ApplicationStatus.applied,
        appliedAt: DateTime.now().subtract(const Duration(days: 2)),
      );
      final jobs = FakeJobsApi(
        jobs: [
          testListJob(0, title: 'Applied one', methods: {ApplyMethod.whatsapp}, application: applied),
          testListJob(1, title: 'Fresh one', methods: {ApplyMethod.whatsapp}),
        ],
      );
      final apps = await pumpApp(tester, jobs: jobs);
      await openExplore(tester);
      expect(find.text('Applied one'), findsOneWidget);
      expect(find.text('Applied · 2 days ago'), findsOneWidget); // on top of its card
      expect(find.widgetWithText(FilledButton, 'WhatsApp'), findsOneWidget); // only the other one has a button
      expect(tester.widget<FilterChip>(find.byType(FilterChip)).selected, isFalse);
      final loads = jobs.searches.length;

      await tapVisible(tester, find.widgetWithText(FilterChip, 'Not applied'));
      await settle(tester);
      expect(find.text('Applied one'), findsNothing);
      expect(find.text('Fresh one'), findsOneWidget);
      expect(jobs.searches, hasLength(loads)); // the same list, nothing loaded again
      final container = ProviderScope.containerOf(tester.element(find.byType(ExploreScreen)));
      expect(container.read(preferencesProvider).getBool(hideAppliedKey), isTrue); // kept for the next time

      // applied to now: it leaves at once; nothing left is said so, with the way back
      await tapVisible(tester, find.widgetWithText(FilledButton, 'WhatsApp'));
      await settle(tester);
      await tapVisible(tester, find.text('Yes, I applied'));
      await settle(tester);
      expect(apps.recorded, [('job-1', ApplyMethod.whatsapp)]);
      expect(find.text('Fresh one'), findsNothing);
      expect(find.text("You've applied to all of these"), findsOneWidget);
      expect(find.text('No jobs found'), findsNothing);
      await tapVisible(tester, find.text('Show all'));
      await settle(tester);
      expect(find.text('Applied one'), findsOneWidget);
      expect(find.text('Fresh one'), findsOneWidget);
      expect(find.text('Applied · Just now'), findsOneWidget);
      expect(container.read(preferencesProvider).getBool(hideAppliedKey), isFalse);
    });

    testWidgets('"Not applied" is kept; a search that finds nothing still says "No jobs found"', (tester) async {
      final jobs = FakeJobsApi(jobs: [testListJob(0, title: 'Data Analyst')]);
      await pumpApp(tester, jobs: jobs, saved: {hideAppliedKey: true});
      await openExplore(tester);
      expect(tester.widget<FilterChip>(find.byType(FilterChip)).selected, isTrue);
      expect(find.text('Data Analyst'), findsOneWidget); // not applied to: shown
      await tester.enterText(find.byType(TextField), 'pilot');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await settle(tester);
      expect(find.text('No jobs found'), findsOneWidget);
      expect(find.text("You've applied to all of these"), findsNothing);
    });
  });

  testWidgets('in Arabic: the tabs, the buttons, the question; the number reads left to right', (tester) async {
    await pumpApp(
      tester,
      matches: FakeMatchesApi(jobs: everyWay()),
      language: 'ar',
    );
    expect(tab('تقديم تلقائي'), findsOneWidget);
    expect(tab('واتساب'), findsOneWidget);
    await openTab(tester, 'واتساب');
    await tapVisible(tester, find.text('عرض التفاصيل').first);
    await settle(tester);
    expect(find.text('طرق التقديم'), findsOneWidget);
    expect(tester.widget<Text>(find.text('+201001234567')).textDirection, TextDirection.ltr);
    await tapVisible(tester, find.descendant(of: find.byType(BottomActionBar), matching: find.text('واتساب')));
    await settle(tester);
    expect(find.text('هل قدّمت؟'), findsOneWidget);
    // the message to the recruiter is in English, whatever the app's language
    expect(links.opened.single.queryParameters['text'], 'Kindly find my attached CV for the position of WhatsApp job.');
  });

  group('rules', () {
    final job = testListJob(0, methods: {ApplyMethod.phone});
    final detail = testDetail(job);

    test('only web links are ever opened', () {
      expect(webUri('https://forms.gle/x'), isNotNull);
      expect(webUri('http://example.com/apply'), isNotNull);
      expect(webUri('javascript:alert(1)'), isNull);
      expect(webUri('intent://scan/#Intent;scheme=zxing;end'), isNull);
      expect(webUri('file:///etc/passwd'), isNull);
      expect(webUri('not a link'), isNull);
      expect(webUri(null), isNull);
    });

    test('where each way goes', () {
      expect(applyTarget(ApplyChannel.whatsapp, job, detail: detail)?.toString(), 'https://wa.me/201001234567');
      expect(applyTarget(ApplyChannel.whatsapp, job)?.toString(), isNull); // no details: no number
      expect(applyTarget(ApplyChannel.email, job, detail: detail), isNull); // sent by Autolinky
      final plainPhone = JobDetail(
        job: job,
        contacts: const [Contact(type: ApplyMethod.phone, value: '+966 50 123 4567')],
      );
      expect(applyTarget(ApplyChannel.whatsapp, job, detail: plainPhone)?.path, '/966501234567');
      final hostile = JobDetail(
        job: job,
        contacts: const [Contact(type: ApplyMethod.link, value: 'javascript:x')],
      );
      expect(applyTarget(ApplyChannel.link, job, detail: hostile), isNull);
    });

    test('the ways of a job, and the method saved', () {
      expect(ApplyChannel.of(testListJob(0, methods: {ApplyMethod.whatsapp, ApplyMethod.email})), [
        ApplyChannel.email,
        ApplyChannel.whatsapp,
      ]);
      // a LinkedIn job not read yet still has its page
      expect(ApplyChannel.of(testListJob(0, methods: {}, source: JobSource.linkedinJob)), [ApplyChannel.companySite]);
      expect(ApplyChannel.whatsapp.methodFor(job), ApplyMethod.phone);
      expect(ApplyChannel.whatsapp.apiFilter, ['whatsapp', 'phone']);
    });
  });

  group('coming back to the app', () {
    testWidgets('leaving and coming back answers true', (tester) async {
      final back = waitForReturn();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(await back, isTrue);
    });

    testWidgets('never leaving answers false (no question out of the blue later)', (tester) async {
      await tester.runAsync(() async {
        expect(await waitForReturn(leaveWithin: const Duration(milliseconds: 50)), isFalse);
      });
    });
  });
}
