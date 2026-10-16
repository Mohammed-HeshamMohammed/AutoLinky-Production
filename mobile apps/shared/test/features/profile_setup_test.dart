import 'dart:typed_data';

import 'package:autolinky/app/app.dart';
import 'package:autolinky/core/errors/app_failure.dart';
import 'package:autolinky/features/matches/presentation/first_jobs_screen.dart';
import 'package:autolinky/features/profile/application/profile_providers.dart';
import 'package:autolinky/features/profile/data/models.dart';
import 'package:autolinky/features/profile/data/profile_repository.dart';
import 'package:autolinky/features/profile/presentation/cv_messages.dart';
import 'package:autolinky/features/profile/presentation/profile_form.dart';
import 'package:autolinky/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers.dart';

PickedCv pdf([String name = 'Sara Ali CV.pdf']) => PickedCv(name: name, bytes: Uint8List.fromList([37, 80, 68, 70]));

void main() {
  late FakeAuth auth;

  setUpAll(() {
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(pdf());
  });
  setUp(() => auth = FakeAuth()..session = testSession());
  tearDown(() => auth.dispose());

  Future<void> pumpApp(WidgetTester tester, FakeProfileApi api, {CvPicker? picker, FakeMatchesApi? matches}) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: await baseOverrides(auth: auth, profiles: api, picker: picker, matches: matches),
        retry: (_, _) => null,
        child: const AutolinkyApp(),
      ),
    );
    await settle(tester);
  }

  /// The "where to work" cards are a list: the lower ones may be below the phone's screen, so it scrolls first,
  /// as a user does.
  Future<void> chooseScope(WidgetTester tester, String name) async {
    final card = find.text(name).last;
    await tester.ensureVisible(card);
    await tester.pump();
    await tester.tap(card);
  }

  testWidgets('a new user goes through the setup: where, CV, check; then their jobs', (tester) async {
    final api = FakeProfileApi(profile: null);
    when(() => api.repo.uploadCv(any(), onSent: any(named: 'onSent'))).thenAnswer((call) async {
      (call.namedArguments[#onSent] as void Function(double)?)?.call(1);
      api.cv = testCv();
      return CvResult(
        cv: api.cv!,
        profile: const Profile(
          targetRoles: ['network_engineer'],
          skills: ['ccna'],
          level: 'mid',
          searchTitles: ['Network Engineer'],
        ),
      );
    });
    await pumpApp(tester, api, picker: () async => pdf());

    // 1. where to work (straight there: no profile yet)
    expect(find.text('Where do you want to work?'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    final next = find.widgetWithText(FilledButton, 'Continue');
    expect(tester.widget<FilledButton>(next).onPressed, isNull); // nothing chosen yet
    await chooseScope(tester, 'Egypt and the Gulf');
    await tester.pump();
    await tester.tap(next);
    await settle(tester);

    // 2. the CV
    expect(find.text('Upload your CV'), findsOneWidget);
    await tester.tap(find.text('Choose a file'));
    await settle(tester);

    // 3. what we found, to check
    expect(find.text("Here's what we found"), findsOneWidget);
    expect(find.text('Network Engineer'), findsWidgets); // the role, named from the dictionary, and the title
    expect(find.text('CCNA'), findsOneWidget);
    await tester.tap(find.text('Show my jobs'));
    await settle(tester);

    expect(api.saved, hasLength(1));
    expect(api.saved.single['search_scope'], 'egypt_gulf');
    expect(api.saved.single['target_roles'], ['network_engineer']);
    expect(api.saved.single['search_titles'], ['Network Engineer']);
    expect(find.text('Network Engineer 0'), findsOneWidget); // the jobs matched to it, on the jobs tab
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('a CV the API refuses says why, and another one can be picked', (tester) async {
    final api = FakeProfileApi(profile: null);
    when(() => api.repo.uploadCv(any(), onSent: any(named: 'onSent')))
        .thenThrow(const ApiFailure(statusCode: 422, code: 'cv_no_text'));
    await pumpApp(tester, api, picker: () async => pdf('scan.pdf'));
    await chooseScope(tester, 'Remote');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await settle(tester);
    await tester.tap(find.text('Choose a file'));
    await settle(tester);
    expect(find.textContaining('scanned picture with no text'), findsOneWidget);
    expect(find.text('Choose a file'), findsOneWidget); // ready for another try
  });

  testWidgets('a profile from before "where to work" goes through the setup and keeps its CV', (tester) async {
    final api = FakeProfileApi(
      profile: const Profile(targetRoles: ['network_engineer'], searchTitles: ['Network Engineer']),
      cv: testCv(),
    );
    await pumpApp(tester, api);
    expect(find.text('Where do you want to work?'), findsOneWidget);
    await chooseScope(tester, 'Egypt only');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await settle(tester);
    expect(find.text('Sara Ali CV.pdf'), findsOneWidget);
    await tester.tap(find.text('Continue with this CV'));
    await settle(tester);
    await tester.tap(find.text('Show my jobs'));
    await settle(tester);
    expect(api.saved.single['search_scope'], 'egypt');
    verifyNever(() => api.repo.uploadCv(any(), onSent: any(named: 'onSent')));
  });

  /// The setup of a user with a CV already: where to work, keep the CV, confirm.
  Future<void> setUp3Steps(WidgetTester tester) async {
    await chooseScope(tester, 'Egypt only');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await settle(tester);
    await tester.tap(find.text('Continue with this CV'));
    await settle(tester);
    await tester.tap(find.text('Show my jobs'));
  }

  testWidgets('after the setup the titles are searched live: the jobs come in as they are found', (tester) async {
    final api =
        FakeProfileApi(
            profile: const Profile(
              targetRoles: ['network_engineer'],
              searchTitles: ['Network Engineer', 'NOC Engineer'],
            ),
            cv: testCv(),
          )
          ..status = const SearchStatus(
            searching: true,
            titles: [
              TitleSearch(title: 'network engineer', state: TitleSearchState.searching),
              TitleSearch(title: 'noc engineer', state: TitleSearchState.searched),
              TitleSearch(title: 'switched off', state: TitleSearchState.skipped),
            ],
          );
    final matches = FakeMatchesApi(jobs: []);
    await pumpApp(tester, api, matches: matches);
    await setUp3Steps(tester);
    // (no settle from here: the radar turns as long as it searches)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(api.liveAsks, 1); // searched for this user, even titles Autolinky searched before
    expect(find.text('Finding your first jobs'), findsOneWidget);
    expect(find.text('Network Engineer'), findsOneWidget); // the titles as the user wrote them
    expect(find.text('NOC Engineer'), findsOneWidget);
    expect(find.text('switched off'), findsNothing);
    expect(find.text('No jobs yet'), findsOneWidget);
    expect(find.text('See my jobs now'), findsOneWidget);

    matches.jobs = [testJob(0)];
    await tester.pump(FirstJobsScreen.checkEvery);
    await tester.pump(const Duration(seconds: 1)); // it slides in, the count rolls up
    expect(find.text('Network Engineer 0'), findsOneWidget);
    expect(find.text('1 job found so far'), findsOneWidget);

    // the last title is searched: done, with the jobs found meanwhile on top
    matches.jobs = [testJob(1), testJob(0)];
    api.status = const SearchStatus(
      titles: [
        TitleSearch(title: 'network engineer', state: TitleSearchState.searched),
        TitleSearch(title: 'noc engineer', state: TitleSearchState.searched),
      ],
    );
    await tester.pump(FirstJobsScreen.checkEvery);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Your jobs are ready'), findsOneWidget);
    expect(find.text('2 jobs found'), findsOneWidget);
    final cards = [
      tester.getTopLeft(find.text('Network Engineer 1')).dy,
      tester.getTopLeft(find.text('Network Engineer 0')).dy,
    ];
    expect(cards.first, lessThan(cards.last)); // the newest on top

    final checks = api.statusChecks;
    await tester.pump(FirstJobsScreen.afterDone + FirstJobsScreen.checkEvery);
    expect(api.statusChecks, checks); // done: the status is not asked again
    final best = matches.bestCalls;
    await tester.pump(FirstJobsScreen.checkEvery * 3);
    expect(matches.bestCalls, best); // and after a little while, the jobs neither

    await tester.tap(find.text('See all my jobs'));
    await settle(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Network Engineer 1'), findsOneWidget); // in For you, the best fit first
  });

  testWidgets('no answer about the live search, or nothing to search: straight to the jobs', (tester) async {
    final api =
        FakeProfileApi(
            profile: const Profile(targetRoles: ['network_engineer']),
            cv: testCv(),
          )
          ..status = const SearchStatus(searching: true)
          ..failStatus = true;
    await pumpApp(tester, api);
    await setUp3Steps(tester);
    await settle(tester);
    expect(find.text('Finding your first jobs'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(api.liveAsks, 1);
  });

  testWidgets('a new CV on the profile tab: once checked, its titles are searched live too', (tester) async {
    final api = FakeProfileApi(cv: testCv())
      ..status = const SearchStatus(
        searching: true,
        titles: [TitleSearch(title: 'data analyst', state: TitleSearchState.searching)],
      );
    when(() => api.repo.uploadCv(any(), onSent: any(named: 'onSent'))).thenAnswer((_) async {
      api.cv = testCv();
      return CvResult(
        cv: api.cv!,
        profile: const Profile(
          targetRoles: ['data_analyst'],
          searchTitles: ['Data Analyst'],
          searchScope: SearchScope.egypt,
        ),
      );
    });
    await pumpApp(
      tester,
      api,
      picker: () async => pdf('New CV.pdf'),
      matches: FakeMatchesApi(jobs: []),
    );
    await tester.tap(find.text('Profile'));
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Replace'), 200);
    await tester.tap(find.text('Replace'));
    await settle(tester);
    await tester.tap(find.text('Choose a file'));
    await settle(tester);
    expect(find.text('Edit profile'), findsOneWidget); // what the new CV filled, to check first
    expect(api.liveAsks, 0);

    await tester.tap(find.text('Save'));
    // (no settle from here: the radar turns as long as it searches)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(api.liveAsks, 1);
    expect(find.text('Finding your first jobs'), findsOneWidget);
    expect(find.text('Data Analyst'), findsWidgets);

    await tester.tap(find.text('See my jobs now'));
    await settle(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('the setup asks for at least one job; a job of the list is also searched for', (tester) async {
    final api = FakeProfileApi(profile: const Profile(), cv: testCv());
    await pumpApp(tester, api);
    await chooseScope(tester, 'Anywhere in the world');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await settle(tester);
    await tester.tap(find.text('Continue with this CV'));
    await settle(tester);
    await tester.tap(find.text('Show my jobs'));
    await tester.pump();
    expect(find.text('Add at least one job you want.'), findsOneWidget);
    expect(api.saved, isEmpty);

    await tester.tap(find.widgetWithText(ActionChip, 'Add').first);
    await settle(tester);
    await tester.tap(find.text('Data Analyst'));
    await settle(tester);
    expect(find.widgetWithText(InputChip, 'Data Analyst'), findsOneWidget);
    await tester.tap(find.text('Show my jobs'));
    await settle(tester);
    expect(api.saved.single['target_roles'], ['data_analyst']);
    expect(api.saved.single['search_titles'], ['Data Analyst']); // searched for too
  });

  testWidgets('a job not in the list shows with the others; 5 at most', (tester) async {
    final api = FakeProfileApi(cv: testCv()); // Network Engineer (a job of the list) + NOC Engineer (a title)
    await pumpApp(tester, api);
    await tester.tap(find.text('Profile'));
    await settle(tester);
    await tester.tap(find.text('Edit profile'));
    await settle(tester);

    Future<void> add(String text, {bool typed = true}) async {
      await tester.tap(find.widgetWithText(ActionChip, 'Add').first); // under "The jobs you want"
      await settle(tester);
      await tester.enterText(find.byType(TextField).last, text);
      await tester.pump();
      await tester.tap(typed ? find.text('Add “$text”') : find.widgetWithText(ListTile, text));
      await settle(tester);
    }

    await add('Prompt Engineer');
    expect(find.widgetWithText(InputChip, 'Prompt Engineer'), findsOneWidget); // with the other jobs
    await add('Data Analyst', typed: false);
    await add('Cloud Engineer');
    expect(find.byType(InputChip).evaluate().length, greaterThanOrEqualTo(5));

    await tester.tap(find.widgetWithText(ActionChip, 'Add').first);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('You can choose up to 5 jobs. Remove one to add another.'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(api.saved.single['target_roles'], ['network_engineer', 'data_analyst']);
    expect(api.saved.single['search_titles'], [
      'Network Engineer',
      'NOC Engineer',
      'Prompt Engineer',
      'Data Analyst',
      'Cloud Engineer',
    ]);
    expect(api.liveAsks, 0); // no new CV: saved, not searched live
  });

  testWidgets('the profile tab: change where to work, delete the CV', (tester) async {
    final api = FakeProfileApi(cv: testCv());
    await pumpApp(tester, api);
    await tester.tap(find.text('Profile'));
    await settle(tester);
    expect(find.text('Egypt only'), findsOneWidget);
    expect(find.text('Network Engineer, NOC Engineer'), findsOneWidget); // the titles searched

    await tester.tap(find.text('Where you want to work'));
    await settle(tester);
    await chooseScope(tester, 'Remote');
    await settle(tester);
    expect(api.saved.single, {'search_scope': 'remote'});

    // the "Saved" note floats over the bottom of the screen: out of the way first
    ScaffoldMessenger.of(tester.element(find.byType(NavigationBar))).removeCurrentSnackBar();
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Delete CV'), 200);
    await tester.tap(find.text('Delete CV'));
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settle(tester);
    verify(() => api.repo.deleteCv()).called(1);
    expect(find.text('Choose a file'), findsOneWidget); // no CV: the upload area
  });

  group('rules', () {
    test('a file the API would refuse is caught before the upload', () {
      expect(PickedCv(name: 'cv.png', bytes: Uint8List(10)).problem?.code, 'cv_bad_type');
      expect(PickedCv(name: 'cv.pdf', bytes: Uint8List(0)).problem?.code, 'cv_empty');
      expect(PickedCv(name: 'cv.PDF', bytes: Uint8List(0), size: 5 * 1024 * 1024).problem?.code, 'cv_too_large');
      expect(PickedCv(name: 'My CV.docx', bytes: Uint8List(10)).problem, isNull);
      expect(PickedCv(name: 'My CV.docx', bytes: Uint8List(10)).contentType, contains('wordprocessingml'));
    });

    test('roles and titles show as one list of jobs', () {
      const draft = ProfileDraft(
        roles: ['network_engineer', 'data_analyst'],
        titles: ['Senior Network Engineer (CCNP)', 'Prompt Engineer'],
      );
      final jobs = draft.jobs(testTaxonomy);
      expect(
        [for (final j in jobs) j.label(testTaxonomy, 'en')],
        ['Network Engineer', 'Data Analyst', 'Prompt Engineer'],
      );
      expect(jobs.first.title, 'Senior Network Engineer (CCNP)'); // the same search as the role
      expect(jobs[1].title, isNull);
      expect(draft.without(jobs.first).titles, ['Prompt Engineer']);
      // a role without its own title is searched for by its English name
      expect(draft.toFields(taxonomy: testTaxonomy)['search_titles'], [
        'Senior Network Engineer (CCNP)',
        'Prompt Engineer',
        'Data Analyst',
      ]);
      expect(const ProfileDraft().problem(lookupAppLocalizations(const Locale('en'))), isNotNull);
    });

    test('the draft saves what the API expects', () {
      final draft = ProfileDraft.from(testProfile).copyWith(headline: '  ', scope: SearchScope.worldwide);
      expect(draft.toFields(), {
        'headline': null,
        'target_roles': ['network_engineer'],
        'level': 'mid',
        'years_experience': 3,
        'skills': ['ccna', 'bgp'],
        'extra_skills': <String>[],
        'search_titles': ['Network Engineer', 'NOC Engineer'],
        'search_scope': 'worldwide',
      });
    });

    for (final locale in AppLocalizations.supportedLocales) {
      test('every CV error has its own sentence in ${locale.languageCode}', () async {
        final l10n = await AppLocalizations.delegate.load(locale);
        final codes = [
          'cv_too_large',
          'cv_bad_type',
          'cv_empty',
          'cv_unreadable',
          'cv_encrypted',
          'cv_no_text',
          'not_a_cv',
          'ai_unavailable',
        ];
        final sentences = {for (final c in codes) cvFailureMessage(l10n, ApiFailure(statusCode: 422, code: c))};
        expect(sentences, hasLength(codes.length));
        expect(sentences, isNot(contains(l10n.errorUnknown)));
        expect(cvFailureMessage(l10n, const RateLimitedFailure()), l10n.cvErrTooMany);
      });
    }
  });
}
