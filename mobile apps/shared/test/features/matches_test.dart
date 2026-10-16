import 'dart:async';

import 'package:autolinky/app/app.dart';
import 'package:autolinky/core/errors/app_failure.dart';
import 'package:autolinky/core/utils/time_ago.dart';
import 'package:autolinky/features/jobs/data/apply_channel.dart';
import 'package:autolinky/features/matches/application/matches_providers.dart';
import 'package:autolinky/features/matches/data/models.dart';
import 'package:autolinky/features/matches/presentation/widgets/match_card.dart';
import 'package:autolinky/features/profile/application/profile_providers.dart';
import 'package:autolinky/features/settings/application/settings_controller.dart';
import 'package:autolinky/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers.dart';

void main() {
  late FakeAuth auth;

  setUpAll(() => registerFallbackValue(<String, Object?>{}));
  setUp(() => auth = FakeAuth()..session = testSession());
  tearDown(() => auth.dispose());

  Future<void> pumpApp(WidgetTester tester, FakeMatchesApi api, {String? language}) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: await baseOverrides(
          auth: auth,
          matches: api,
          prefs: await testPreferences({SettingsController.localeKey: ?language}),
        ),
        retry: (_, _) => null,
        child: const AutolinkyApp(),
      ),
    );
    await settle(tester);
  }

  final end = find.text("That's all for now. New jobs arrive all the time.");
  // the list of the open tab (the tabs and the pages between them scroll sideways)
  final list = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;
  final email = matchesProvider(ApplyChannel.email);

  testWidgets('new jobs arriving show as a bar on top; a tap loads them, the list does not move by itself', (
    tester,
  ) async {
    final api = FakeMatchesApi();
    await pumpApp(tester, api);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
    final loads = api.calls.length;

    api.newCount = 3;
    await tester.pump(const Duration(minutes: 2)); // asked every two minutes
    await settle(tester);
    expect(api.newChecks, isNotEmpty);
    expect(find.text('3 new jobs'), findsOneWidget);
    expect(api.calls.length, loads); // nothing reloaded under the user's finger

    api.newCount = 0;
    await tester.tap(find.text('3 new jobs'));
    await settle(tester);
    expect(find.text('3 new jobs'), findsNothing);
    expect(api.calls.length, greaterThan(loads)); // the lists loaded again, with what arrived
  });

  testWidgets('each card: the percent, where, how, how long ago, why, the skills you have and lack', (tester) async {
    await pumpApp(
      tester,
      FakeMatchesApi(
        jobs: [
          testJob(0, skills: ['ccna', 'bgp', 'ospf', 'mpls', 'vlan', 'qos']),
        ],
      ),
    );
    expect(find.textContaining('Autolinky sends yours for you. Best fit first.'), findsOneWidget);
    expect(find.text('Network Engineer 0'), findsOneWidget);
    expect(find.text('Vodafone Egypt'), findsOneWidget);
    expect(find.text('92%'), findsOneWidget);
    expect(find.bySemanticsLabel('92% match'), findsOneWidget);
    expect(find.text('Cairo, Egypt'), findsOneWidget);
    expect(find.text('Hybrid · Full-time'), findsOneWidget);
    expect(find.text('3 hours ago'), findsOneWidget);
    expect(find.text('Your job · Your level'), findsOneWidget);
    // skills by their names from the dictionary; the 4 that weigh most, then how many more
    expect(find.text('Your skills'), findsOneWidget);
    expect(find.text('CCNA'), findsOneWidget);
    expect(find.text('BGP'), findsOneWidget);
    expect(find.text('ospf'), findsOneWidget); // not in the test dictionary: the slug as words
    expect(find.text('vlan'), findsNothing);
    expect(find.text('+2'), findsOneWidget);
    expect(find.text('Missing'), findsOneWidget);
    expect(find.text('Python'), findsOneWidget);
    // and its two actions
    expect(find.text('Show details'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Send my CV'), findsOneWidget);
    await tester.scrollUntilVisible(end, 300, scrollable: list);
    expect(end, findsOneWidget);
  });

  testWidgets('the next jobs load while scrolling, once each, until the end', (tester) async {
    final api = FakeMatchesApi(jobs: [for (var i = 0; i < 45; i++) testJob(i, percent: 90 - i)]);
    await pumpApp(tester, api);
    expect(api.calls, [null]);
    expect(find.byType(MatchCard), findsWidgets);

    await tester.scrollUntilVisible(end, 600, scrollable: list);
    await settle(tester);
    expect(api.calls, [null, '20', '40']);
    expect(find.text('Network Engineer 44'), findsOneWidget);
  });

  testWidgets('pages too short to fill the screen bring the next ones by themselves, then it waits', (tester) async {
    final api = FakeMatchesApi(
      jobs: [for (var i = 0; i < 30; i++) testJob(i, skills: const [], missing: const [])],
      pageSize: 1,
    );
    await pumpApp(tester, api);
    // the screen and the next stretch of scrolling filled, one page after the other: not all 30
    expect(api.calls.take(3), [null, '1', '2']);
    expect(api.calls.length, inInclusiveRange(4, 15));
    final loaded = api.calls.length;
    await tester.pump(const Duration(seconds: 2));
    expect(api.calls, hasLength(loaded));
  });

  testWidgets('pull down to refresh; a failed refresh keeps the jobs and says why', (tester) async {
    final api = FakeMatchesApi();
    await pumpApp(tester, api);

    api.jobs = [testJob(7, title: 'Cloud Engineer')];
    await tester.fling(find.text('Network Engineer 0'), const Offset(0, 400), 1000);
    await settle(tester);
    expect(api.calls, [null, null]);
    expect(find.text('Cloud Engineer'), findsOneWidget);
    expect(find.text('Network Engineer 0'), findsNothing);

    api.fail = const NetworkFailure();
    await tester.fling(find.text('Cloud Engineer'), const Offset(0, 400), 1000);
    await settle(tester);
    expect(find.text('Cloud Engineer'), findsOneWidget);
    expect(find.textContaining('No internet connection'), findsOneWidget);
  });

  testWidgets('nothing in a tab yet: says so; pulling down checks again; the profile is one tap away', (tester) async {
    final api = FakeMatchesApi(jobs: []);
    await pumpApp(tester, api);
    expect(find.text('Nothing here yet'), findsOneWidget);

    api.jobs = [testJob(0)];
    await tester.fling(find.text('Nothing here yet'), const Offset(0, 400), 1000);
    await settle(tester);
    expect(api.calls, [null, null]);
    expect(find.text('Network Engineer 0'), findsOneWidget);

    api.jobs = [];
    await tester.fling(find.text('Network Engineer 0'), const Offset(0, 400), 1000);
    await settle(tester);
    await tester.tap(find.text('Edit profile'));
    await settle(tester);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('the first page fails: why, and a retry', (tester) async {
    final api = FakeMatchesApi()..fail = const ServerFailure();
    await pumpApp(tester, api);
    expect(find.textContaining('Something went wrong'), findsOneWidget);
    expect(find.textContaining('Error code: E-500'), findsOneWidget); // a code to quote, nothing internal
    await tester.tap(find.text('Try again'));
    await settle(tester);
    expect(find.text('Network Engineer 0'), findsOneWidget);
  });

  testWidgets('a next page that fails waits for "Try again" under the list', (tester) async {
    final api = FakeMatchesApi(jobs: [for (var i = 0; i < 25; i++) testJob(i)]);
    api.failOn['20'] = const TimeoutFailure();
    await pumpApp(tester, api);
    final failed = find.text("Couldn't load more jobs.");
    await tester.scrollUntilVisible(failed, 600, scrollable: list);
    await settle(tester);
    await tester.drag(list, const Offset(0, -300)); // scrolling does not ask again
    await settle(tester);
    expect(api.calls, [null, '20']);

    api.failOn.clear();
    await tester.tap(find.text('Try again'));
    await settle(tester);
    await tester.scrollUntilVisible(end, 600, scrollable: list);
    expect(api.calls, [null, '20', '20']);
    expect(find.text('Network Engineer 24'), findsOneWidget);
  });

  testWidgets('a changed profile builds the list again', (tester) async {
    final api = FakeMatchesApi();
    await pumpApp(tester, api);
    final container = ProviderScope.containerOf(tester.element(find.byType(MatchCard).first));
    await container.read(profileProvider.notifier).save({'search_scope': 'remote'});
    await settle(tester);
    expect(api.calls, [null, null]);
  });

  testWidgets('choosing where to work loads every tab the user opened again', (tester) async {
    final api = FakeMatchesApi(
      jobs: [
        testJob(0),
        testJob(1, methods: {ApplyMethod.whatsapp}),
        testJob(2, methods: {ApplyMethod.easyApply}, source: JobSource.linkedinJob),
      ],
    );
    await pumpApp(tester, api);
    for (final name in ['WhatsApp', 'Easy Apply']) {
      final tab = find.descendant(of: find.byType(TabBar), matching: find.text(name));
      await tester.ensureVisible(tab);
      await settle(tester);
      await tester.tap(tab);
      await settle(tester);
    }
    expect(api.channels, [ApplyChannel.email, ApplyChannel.whatsapp, ApplyChannel.easyApply]);

    final container = ProviderScope.containerOf(tester.element(find.byType(MatchCard).first));
    await container.read(profileProvider.notifier).save({'search_scope': 'egypt_remote'});
    await settle(tester);
    // each of the three asked the API again, with the new choice (the server applies it), at once
    expect(api.channels.skip(3).toSet(), {ApplyChannel.email, ApplyChannel.whatsapp, ApplyChannel.easyApply});
    expect(api.channels.length, 6);
  });

  testWidgets('a job that never says where says so; a remote one needs no place', (tester) async {
    MatchedJob placeless(int i, WorkMode mode) => MatchedJob(
      job: Job(
        id: 'job-$i',
        title: 'Placeless $i',
        workMode: mode,
        postedAt: DateTime.now(),
        applyMethods: {ApplyMethod.email},
      ),
      match: testJob(i).match,
    );
    await pumpApp(tester, FakeMatchesApi(jobs: [placeless(0, WorkMode.onsite), placeless(1, WorkMode.remote)]));
    expect(find.text('Placeless 0'), findsOneWidget);
    expect(find.text('Placeless 1'), findsOneWidget);
    expect(find.text('Place not given'), findsOneWidget); // the on-site one only
  });

  testWidgets('the API has no profile for the user: the way to the setup', (tester) async {
    final api = FakeMatchesApi()..fail = const ApiFailure(statusCode: 409, code: 'Profile needed');
    await pumpApp(tester, api);
    expect(find.text('Set up your profile'), findsWidgets);
  });

  testWidgets('in Arabic: right to left, with Arabic plurals', (tester) async {
    final skills = ['ccna', 'bgp', 'ospf', 'mpls', 'vlan', 'qos'];
    await pumpApp(
      tester,
      FakeMatchesApi(
        jobs: [
          testJob(0, skills: skills),
          testJob(1),
        ],
      ),
      language: 'ar',
    );
    expect(find.text('لك'), findsOneWidget);
    expect(find.text('تقديم تلقائي'), findsOneWidget); // the tabs
    expect(find.text('قدّمت عليها'), findsOneWidget);
    expect(find.text('منذ 3 ساعات'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'أرسل سيرتي'), findsWidgets);
    expect(find.text('عرض التفاصيل'), findsWidgets);
    expect(find.text('هجين · دوام كامل'), findsWidgets);
    expect(find.text('نفس وظيفتك · تناسب مستواك'), findsWidgets);
    expect(find.text('مهاراتك'), findsWidgets);
    expect(find.text('ينقصك'), findsWidgets);
    // no letters to take a direction from: left to right on purpose, so they read 92% and +2
    expect(tester.widget<Text>(find.text('92%')).textDirection, TextDirection.ltr);
    expect(tester.widget<Text>(find.text('+2')).textDirection, TextDirection.ltr);
    expect(Directionality.of(tester.element(find.text('مهاراتك').first)), TextDirection.rtl);
    await tester.scrollUntilVisible(find.text('منذ 4 ساعات'), 300, scrollable: list);
  });

  group('the list', () {
    Future<ProviderContainer> container(FakeMatchesApi api) async {
      final container = ProviderContainer(
        overrides: await baseOverrides(auth: auth, matches: api),
        retry: (_, _) => null,
      );
      addTearDown(container.dispose);
      await container.read(email.future);
      return container;
    }

    test('one next page at a time', () async {
      final api = FakeMatchesApi(jobs: [for (var i = 0; i < 30; i++) testJob(i)]);
      final c = await container(api);
      await Future.wait([c.read(email.notifier).loadMore(), c.read(email.notifier).loadMore()]);
      expect(api.calls, [null, '20']);
      expect(c.read(email).value!.items, hasLength(30));
      expect(c.read(email).value!.hasMore, isFalse);
    });

    test('a job already shown is not shown twice', () async {
      final api = FakeMatchesApi(jobs: [for (var i = 0; i < 25; i++) testJob(i)]);
      final c = await container(api);
      api.jobs = [...api.jobs.take(19), testJob(5), ...api.jobs.skip(19)]; // job 5 moved down a place
      await c.read(email.notifier).loadMore();
      final ids = c.read(email).value!.items.map((m) => m.job.id).toList();
      expect(ids, hasLength(25));
      expect(ids.toSet(), hasLength(25));
    });

    test('a next page that arrives after a refresh belongs to the old list: dropped', () async {
      final api = FakeMatchesApi(jobs: [for (var i = 0; i < 30; i++) testJob(i)]);
      final c = await container(api);
      final slow = Completer<MatchedPage>();
      when(() => api.repo.matched(any(), cursor: '20')).thenAnswer((_) => slow.future);
      final more = c.read(email.notifier).loadMore();
      expect(c.read(email).value!.loadingMore, isTrue);

      api.jobs = [testJob(100)];
      await c.refresh(email.future);
      slow.complete(MatchedPage(items: [testJob(20)]));
      await more;
      expect(c.read(email).value!.items.map((m) => m.job.id), ['job-100']);
    });

    test('no API call before the setup is finished', () async {
      final api = FakeMatchesApi();
      final container = ProviderContainer(
        overrides: await baseOverrides(auth: auth, matches: api, profiles: FakeProfileApi(profile: null)),
        retry: (_, _) => null,
      );
      addTearDown(container.dispose);
      expect((await container.read(email.future)).items, isEmpty);
      expect(api.calls, isEmpty);
    });
  });

  group('data', () {
    test('a page of the API', () {
      final page = MatchedPage.fromJson({
        'items': [
          {
            'id': '5b0e8a52-6f8e-4b8a-9d61-2f1c7c3f0a11',
            'source': 'linkedin_job',
            'title': ' Senior Network Engineer ',
            'company': 'Orange',
            'city': 'Dubai',
            'country': 'United Arab Emirates',
            'country_code': 'AE',
            'work_mode': 'remote',
            'level': 'senior',
            'employment_type': 'unknown',
            'field': 'networking',
            'role': 'network_engineer',
            'skills': ['bgp', 'mpls'],
            'apply_methods': ['easy_apply'],
            'language': 'en',
            'snippet': null,
            'url': null,
            'posted_at': '2026-10-04T08:00:00+00:00',
            'match_percent': 81,
            'match_reasons': {
              'role': 'similar_role',
              'skills': ['bgp'],
              'missing': ['mpls'],
              'level': 'close',
              'location': 'remote',
            },
          },
        ],
        'next_cursor': 'eyJvIjoyMH0',
      });
      final MatchedJob(:job, :match) = page.items.single;
      expect(page.nextCursor, 'eyJvIjoyMH0');
      expect(job.title, 'Senior Network Engineer');
      expect(job.source, JobSource.linkedinJob);
      expect(job.place, 'Dubai, United Arab Emirates');
      expect(job.workMode, WorkMode.remote);
      expect(job.employmentType, isNull); // "unknown": not shown
      expect(job.applyMethods, {ApplyMethod.easyApply});
      expect(job.skills, ['bgp', 'mpls']);
      expect(job.application, isNull);
      expect(job.postedAt.toUtc(), DateTime.utc(2026, 10, 4, 8));
      expect(match.percent, 81);
      expect(match.tier, MatchTier.high);
      expect(match.reasons.role, RoleFit.similarRole);
      expect(match.reasons.skills, ['bgp']);
      expect(match.reasons.missing, ['mpls']);
      expect(match.reasons.level, LevelFit.close);
    });

    test('missing or new values do not break a card', () {
      final MatchedJob(:job, :match) = MatchedJob.fromJson({
        'id': 'x',
        'title': 'Accountant',
        'company': ' ',
        'city': 'Egypt',
        'country': 'Egypt',
        'work_mode': 'on the moon',
        'apply_methods': ['email', 'carrier_pigeon'],
        'posted_at': '2026-10-04T08:00:00Z',
        'match_percent': 140,
        'match_reasons': {'role': 'some_new_reason', 'level': null},
        'application': {'method': 'whatsapp', 'status': 'applied', 'applied_at': '2026-10-05T09:00:00Z'},
      });
      expect(job.company, isNull);
      expect(job.place, 'Egypt');
      expect(job.workMode, isNull);
      expect(job.applyMethods, {ApplyMethod.email}); // a method the app does not know is left out
      expect(job.application?.method, ApplyMethod.whatsapp);
      expect(match.percent, 100);
      expect(match.reasons.role, RoleFit.skillsOnly);
      expect(match.reasons.level, LevelFit.unknown);
      expect(MatchedPage.fromJson({'items': <Object?>[], 'next_cursor': null}).nextCursor, isNull);
    });

    test('the color of a percent', () {
      expect([95, 70, 69, 50, 49, 0].map(MatchTier.of), [
        MatchTier.high,
        MatchTier.high,
        MatchTier.medium,
        MatchTier.medium,
        MatchTier.low,
        MatchTier.low,
      ]);
    });
  });

  group('how long ago', () {
    final now = DateTime(2026, 10, 5, 12);
    String ago(AppLocalizations l10n, Duration age) => timeAgo(l10n, now.subtract(age), now: now);

    test('in English', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(ago(l10n, const Duration(seconds: 30)), 'Just now');
      expect(ago(l10n, const Duration(minutes: -5)), 'Just now'); // a phone clock behind the server
      expect(ago(l10n, const Duration(minutes: 1)), '1 minute ago');
      expect(ago(l10n, const Duration(minutes: 59)), '59 minutes ago');
      expect(ago(l10n, const Duration(hours: 1)), '1 hour ago');
      expect(ago(l10n, const Duration(hours: 26)), '1 day ago');
      expect(ago(l10n, const Duration(days: 6)), '6 days ago');
      expect(ago(l10n, const Duration(days: 13)), '1 week ago');
      expect(ago(l10n, const Duration(days: 29)), '4 weeks ago');
      expect(ago(l10n, const Duration(days: 75)), '2 months ago');
    });

    test('in Arabic, with its plural forms', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
      expect(ago(l10n, const Duration(seconds: 30)), 'الآن');
      expect(ago(l10n, const Duration(minutes: 1)), 'منذ دقيقة');
      expect(ago(l10n, const Duration(minutes: 2)), 'منذ دقيقتين');
      expect(ago(l10n, const Duration(minutes: 5)), 'منذ 5 دقائق');
      expect(ago(l10n, const Duration(minutes: 11)), 'منذ 11 دقيقة');
      expect(ago(l10n, const Duration(hours: 2)), 'منذ ساعتين');
      expect(ago(l10n, const Duration(hours: 3)), 'منذ 3 ساعات');
      expect(ago(l10n, const Duration(days: 1)), 'منذ يوم');
      expect(ago(l10n, const Duration(days: 3)), 'منذ 3 أيام');
      expect(ago(l10n, const Duration(days: 14)), 'منذ أسبوعين');
      expect(ago(l10n, const Duration(days: 60)), 'منذ شهرين');
    });
  });
}
