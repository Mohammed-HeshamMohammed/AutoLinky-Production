// Renders every screen to PNG with the real fonts, to look at the design (not a regression test):
//
//   set SCREENSHOTS=1 && flutter test test/screenshots --update-goldens      (PowerShell: $env:SCREENSHOTS=1)
//
// Images land in test/screenshots/out/ (not committed). Skipped in a normal `flutter test`.
@Tags(['screenshots'])
library;

import 'dart:async';
import 'dart:io';

import 'package:autolinky/app/app.dart';
import 'package:autolinky/core/theme/app_theme.dart';
import 'package:autolinky/features/applications/data/applications_repository.dart';
import 'package:autolinky/features/auth/application/auth_providers.dart';
import 'package:autolinky/features/auth/presentation/email_link_screen.dart';
import 'package:autolinky/features/auth/presentation/email_screen.dart';
import 'package:autolinky/features/auth/presentation/welcome_screen.dart';
import 'package:autolinky/features/matches/data/models.dart';
import 'package:autolinky/features/matches/presentation/first_jobs_screen.dart';
import 'package:autolinky/features/profile/data/models.dart';
import 'package:autolinky/features/profile/data/profile_repository.dart';
import 'package:autolinky/features/settings/application/settings_controller.dart';
import 'package:autolinky/features/taxonomy/taxonomy.dart';
import 'package:autolinky/l10n/gen/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers.dart';

final _skip = !Platform.environment.containsKey('SCREENSHOTS');

Future<void> _loadFonts() async {
  final plex = FontLoader(AppTheme.fontFamily);
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    plex.addFont(Future.value(ByteData.sublistView(File('assets/fonts/IBMPlexSansArabic-$w.ttf').readAsBytesSync())));
  }
  await plex.load();
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? r'D:\flutter\flutter';
  final icons = FontLoader('MaterialIcons')
    ..addFont(
      Future.value(
        ByteData.sublistView(
          File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytesSync(),
        ),
      ),
    );
  await icons.load();
}

class _PresetEmail extends EmailSignInController {
  @override
  EmailSignInState build() => EmailSignInState(email: 'sara@example.com', sentAt: DateTime.now());
}

void main() {
  setUpAll(_loadFonts);

  void phone(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(786, 1702)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pump(const Duration(seconds: 1));
    await expectLater(find.byType(MaterialApp).first, matchesGoldenFile('out/$name.png'));
  }

  Future<void> screen(
    WidgetTester tester,
    Widget child,
    String name, {
    Locale locale = const Locale('en'),
    bool dark = false,
    List<Override> extra = const [],
  }) async {
    phone(tester);
    final auth = FakeAuth();
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...await baseOverrides(auth: auth),
          ...extra,
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: child,
        ),
      ),
    );
    await shot(tester, name);
  }

  Future<void> app(
    WidgetTester tester,
    String name, {
    Locale? locale,
    ThemeMode theme = ThemeMode.light,
    String? tab,
    bool settings = false,
    FakeProfileApi? api,
    FakeMatchesApi? matches,
    FakeApplicationsApi? applications,
    Future<void> Function()? steps,
  }) async {
    phone(tester);
    final auth = FakeAuth()..session = testSession();
    addTearDown(auth.dispose);
    final prefs = await testPreferences({
      SettingsController.themeKey: theme.name,
      if (locale != null) SettingsController.localeKey: locale.languageCode,
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: await baseOverrides(
          auth: auth,
          prefs: prefs,
          profiles: api,
          matches: matches ?? FakeMatchesApi(jobs: _demoJobs()),
          jobs: FakeJobsApi(jobs: [for (final m in _demoJobs()) m.job], details: _demoDetails()),
          applications: applications ?? FakeApplicationsApi(applied: _demoApplied()),
          links: FakeLinks(),
          taxonomy: _demoTaxonomy,
          picker: () async => PickedCv(name: 'Sara Ali CV.pdf', bytes: Uint8List.fromList([1])),
        ),
        child: const AutolinkyApp(),
      ),
    );
    await tester.pumpAndSettle();
    if (tab != null) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
    }
    if (steps != null) await steps();
    if (settings) {
      await tester.tap(find.byIcon(Icons.settings_outlined).first);
      await tester.pumpAndSettle();
    }
    await shot(tester, name);
  }

  testWidgets('welcome', (t) => screen(t, const WelcomeScreen(), '01_welcome_en'), skip: _skip);
  testWidgets(
    'welcome ar',
    (t) => screen(t, const WelcomeScreen(), '02_welcome_ar', locale: const Locale('ar')),
    skip: _skip,
  );
  testWidgets('welcome dark', (t) => screen(t, const WelcomeScreen(), '03_welcome_dark', dark: true), skip: _skip);
  testWidgets('email', (t) => screen(t, const EmailScreen(), '04_email_en'), skip: _skip);
  testWidgets(
    'verify ar',
    (t) => screen(
      t,
      const EmailLinkScreen(),
      '05_verify_ar',
      locale: const Locale('ar'),
      extra: [emailSignInProvider.overrideWith(_PresetEmail.new)],
    ),
    skip: _skip,
  );
  testWidgets('matches', (t) => app(t, '06_matches_en'), skip: _skip);
  testWidgets('profile', (t) => app(t, '07_profile_en', tab: 'Profile'), skip: _skip);
  testWidgets(
    'profile ar dark',
    (t) => app(t, '08_profile_ar_dark', locale: const Locale('ar'), theme: ThemeMode.dark, tab: 'حسابي'),
    skip: _skip,
  );
  testWidgets('settings', (t) => app(t, '09_settings_en', tab: 'Profile', settings: true), skip: _skip);

  // ── Step 8b: the setup and the profile ──
  setUpAll(() {
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(PickedCv(name: 'x.pdf', bytes: Uint8List.fromList([1])));
  });

  FakeProfileApi newUser({bool finishUpload = true}) {
    final api = FakeProfileApi(profile: null);
    when(() => api.repo.uploadCv(any(), onSent: any(named: 'onSent'))).thenAnswer((call) {
      (call.namedArguments[#onSent] as void Function(double)?)?.call(1);
      if (!finishUpload) return Completer<CvResult>().future; // stays "reading"
      api.cv = testCv();
      return Future.value(
        CvResult(
          cv: api.cv!,
          profile: const Profile(
            headline: 'Network Engineer, 3 years at ISPs',
            targetRoles: ['network_engineer', 'noc_engineer'],
            skills: ['ccna', 'bgp', 'python'],
            extraSkills: ['Packet Tracer'],
            level: 'mid',
            yearsExperience: 3,
            searchTitles: ['Network Engineer', 'NOC Engineer', 'Network Support Engineer'],
          ),
        ),
      );
    });
    return api;
  }

  testWidgets('setup scope ar', (t) async {
    await app(
      t,
      '10_setup_scope_ar',
      locale: const Locale('ar'),
      api: newUser(),
      steps: () async {
        await t.tap(find.text('مصر والخليج'));
        await t.pumpAndSettle();
      },
    );
  }, skip: _skip);

  Future<void> toCvStep(WidgetTester t) async {
    await t.tap(find.text('Egypt and the Gulf'));
    await t.pump();
    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();
  }

  testWidgets('setup cv', (t) async {
    await app(t, '11_setup_cv_en', api: newUser(), steps: () => toCvStep(t));
  }, skip: _skip);

  testWidgets('setup reading', (t) async {
    await app(
      t,
      '12_setup_reading_en',
      api: newUser(finishUpload: false),
      steps: () async {
        await toCvStep(t);
        await t.tap(find.text('Choose a file'));
        await t.pump(const Duration(milliseconds: 600));
      },
    );
  }, skip: _skip);

  testWidgets('setup review', (t) async {
    await app(
      t,
      '13_setup_review_en',
      api: newUser(),
      steps: () async {
        await toCvStep(t);
        await t.tap(find.text('Choose a file'));
        await t.pumpAndSettle();
      },
    );
  }, skip: _skip);

  testWidgets('setup review ar dark', (t) async {
    await app(
      t,
      '14_setup_review_ar_dark',
      locale: const Locale('ar'),
      theme: ThemeMode.dark,
      api: newUser(),
      steps: () async {
        await t.tap(find.text('مصر والخليج'));
        await t.pump();
        await t.tap(find.text('متابعة'));
        await t.pumpAndSettle();
        await t.tap(find.text('اختر ملفًا'));
        await t.pumpAndSettle();
      },
    );
  }, skip: _skip);

  testWidgets('profile with cv', (t) async {
    await app(
      t,
      '15_profile_full_en',
      tab: 'Profile',
      api: FakeProfileApi(cv: testCv(analysis: 'partial')),
    );
  }, skip: _skip);

  // ── Step 8c / 8d: the matched jobs, a tab per way to apply, Applied, Explore ──
  Future<void> openTab(WidgetTester t, String name) async {
    final tab = find.descendant(of: find.byType(TabBar), matching: find.text(name));
    await t.ensureVisible(tab);
    await t.pumpAndSettle();
    await t.tap(tab);
    await t.pumpAndSettle();
  }

  testWidgets('matches ar dark', (t) async {
    await app(t, '16_matches_ar_dark', locale: const Locale('ar'), theme: ThemeMode.dark);
  }, skip: _skip);

  testWidgets('whatsapp tab', (t) async {
    await app(t, '17_tab_whatsapp_en', steps: () => openTab(t, 'WhatsApp'));
  }, skip: _skip);

  testWidgets('matches loading', (t) async {
    final api = FakeMatchesApi();
    when(() => api.repo.matched(any(), cursor: any(named: 'cursor')))
        .thenAnswer((_) => Completer<MatchedPage>().future);
    phone(t);
    final auth = FakeAuth()..session = testSession();
    addTearDown(auth.dispose);
    await t.pumpWidget(
      ProviderScope(
        overrides: await baseOverrides(auth: auth, matches: api),
        child: const AutolinkyApp(),
      ),
    );
    await t.pump();
    await t.pump();
    await shot(t, '18_matches_loading_en');
  }, skip: _skip);

  testWidgets('empty tab', (t) async {
    await app(t, '19_tab_empty_en', steps: () => openTab(t, 'Comment'));
  }, skip: _skip);

  testWidgets('details', (t) async {
    await app(
      t,
      '20_details_en',
      steps: () async {
        await openTab(t, 'WhatsApp');
        await t.tap(find.text('Show details').first);
        await t.pumpAndSettle();
      },
    );
  }, skip: _skip);

  testWidgets('did you apply', (t) async {
    await app(
      t,
      '21_did_you_apply_en',
      steps: () async {
        await openTab(t, 'WhatsApp');
        await t.tap(find.widgetWithText(FilledButton, 'WhatsApp').first);
        await t.pumpAndSettle();
      },
    );
  }, skip: _skip);

  testWidgets('connect gmail', (t) async {
    await app(
      t,
      '22_connect_gmail_en',
      steps: () async {
        await t.tap(find.widgetWithText(FilledButton, 'Send my CV').first);
        await t.pumpAndSettle();
      },
    );
  }, skip: _skip);

  testWidgets('applied', (t) async {
    await app(t, '23_applied_en', steps: () => openTab(t, 'Applied'));
  }, skip: _skip);

  testWidgets('explore', (t) async {
    await app(t, '24_explore_en', tab: 'Explore');
  }, skip: _skip);

  testWidgets('explore ar dark', (t) async {
    await app(t, '25_explore_ar_dark', tab: 'استكشاف', locale: const Locale('ar'), theme: ThemeMode.dark);
  }, skip: _skip);

  // ── a new user's first jobs, live ──
  Future<void> firstJobs(
    WidgetTester t,
    String name, {
    required List<MatchedJob> jobs,
    bool done = false,
    Locale locale = const Locale('en'),
    bool dark = false,
  }) async {
    phone(t);
    final auth = FakeAuth()..session = testSession();
    addTearDown(auth.dispose);
    const titles = ['network engineer', 'noc engineer', 'network support engineer'];
    final api =
        FakeProfileApi(
            profile: const Profile(
              targetRoles: ['network_engineer'],
              searchTitles: ['Network Engineer', 'NOC Engineer', 'Network Support Engineer'],
            ),
          )
          ..status = SearchStatus(
            searching: !done,
            titles: [
              for (final (i, title) in titles.indexed)
                TitleSearch(
                  title: title,
                  state: done || i == 1 ? TitleSearchState.searched : TitleSearchState.searching,
                ),
            ],
          );
    await t.pumpWidget(
      ProviderScope(
        overrides: await baseOverrides(
          auth: auth,
          profiles: api,
          matches: FakeMatchesApi(jobs: jobs),
          taxonomy: _demoTaxonomy,
        ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: const FirstJobsScreen(),
        ),
      ),
    );
    await t.pump(); // the answers arrive, then the jobs slide in
    await t.pump(const Duration(seconds: 1));
    await shot(t, name);
    await t.pumpWidget(const SizedBox()); // its timers stop with it
  }

  testWidgets('first jobs searching', (t) => firstJobs(t, '27_first_jobs_waiting_en', jobs: []), skip: _skip);
  testWidgets(
    'first jobs coming ar dark',
    (t) => firstJobs(
      t,
      '28_first_jobs_coming_ar_dark',
      jobs: _demoJobs().take(3).toList(),
      locale: const Locale('ar'),
      dark: true,
    ),
    skip: _skip,
  );
  testWidgets(
    'first jobs done',
    (t) => firstJobs(t, '29_first_jobs_done_en', jobs: _demoJobs(), done: true),
    skip: _skip,
  );

  // ── the plan: 20 free applications, then "Upgrade" ──
  FakeApplicationsApi usedUp() => FakeApplicationsApi(applied: _demoApplied())
    ..emailConnected = true
    ..freeUsed = 20;

  testWidgets('locked tab', (t) => app(t, '30_locked_tab_en', applications: usedUp()), skip: _skip);
  testWidgets('upgrade sheet', (t) async {
    await app(
      t,
      '31_upgrade_sheet_en',
      applications: usedUp(),
      steps: () async {
        await t.tap(find.widgetWithText(FilledButton, 'Upgrade').last);
        await t.pumpAndSettle();
      },
    );
  }, skip: _skip);
  testWidgets(
    'locked tab ar dark',
    (t) => app(t, '32_locked_tab_ar_dark', applications: usedUp(), locale: const Locale('ar'), theme: ThemeMode.dark),
    skip: _skip,
  );
  testWidgets(
    'free left',
    (t) => app(t, '33_free_left_en', applications: FakeApplicationsApi(applied: _demoApplied())..freeUsed = 8),
    skip: _skip,
  );

  // ── "Upgrade": the promo code before WhatsApp ──
  Future<void> promoSteps(WidgetTester t, {required bool typeCode, String upgrade = 'Upgrade'}) async {
    await t.tap(find.widgetWithText(FilledButton, upgrade).last);
    await t.pumpAndSettle();
    await t.tap(find.descendant(of: find.byType(BottomSheet), matching: find.widgetWithText(FilledButton, upgrade)));
    await t.pumpAndSettle();
    if (!typeCode) return;
    await t.tap(find.byIcon(Icons.confirmation_number_outlined).first);
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'Daniel20');
    await t.pumpAndSettle();
  }

  testWidgets('promo code ask', (t) async {
    await app(t, '41_promo_ask_en', applications: usedUp(), steps: () => promoSteps(t, typeCode: false));
  }, skip: _skip);
  testWidgets('promo code typed', (t) async {
    await app(t, '42_promo_code_en', applications: usedUp(), steps: () => promoSteps(t, typeCode: true));
  }, skip: _skip);
  testWidgets('promo code typed ar dark', (t) async {
    await app(
      t,
      '43_promo_code_ar_dark',
      applications: usedUp(),
      locale: const Locale('ar'),
      theme: ThemeMode.dark,
      steps: () => promoSteps(t, typeCode: true, upgrade: 'اشترك'),
    );
  }, skip: _skip);

  // ── auto apply's switch on "For you", and connecting Gmail step by step ──
  FakeApplicationsApi switchedOn() => FakeApplicationsApi(applied: _demoApplied())
    ..emailConnected = true
    ..autoApplyOn = true
    ..sentToday = 3;

  Future<void> setupSteps(WidgetTester t, {required int step}) async {
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    if (step < 2) return;
    await t.tap(find.text("It's already on"));
    await t.pumpAndSettle();
    if (step < 3) return;
    await t.tap(find.text('I already have one'));
    await t.pumpAndSettle();
    await t.enterText(find.widgetWithText(TextField, 'App password'), 'abcd efgh ijkl mnop');
    await t.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle();
  }

  testWidgets('home switch on', (t) => app(t, '34_home_switch_on_en', applications: switchedOn()), skip: _skip);
  testWidgets('gmail setup 1', (t) => app(t, '35_gmail_setup_1_en', steps: () => setupSteps(t, step: 1)), skip: _skip);
  testWidgets('gmail setup 2', (t) => app(t, '36_gmail_setup_2_en', steps: () => setupSteps(t, step: 2)), skip: _skip);
  testWidgets('gmail setup 3', (t) => app(t, '37_gmail_setup_3_en', steps: () => setupSteps(t, step: 3)), skip: _skip);
  testWidgets('auto apply ready', (t) async {
    await app(
      t,
      '38_auto_apply_ready_en',
      steps: () async {
        await setupSteps(t, step: 3);
        await t.tap(find.widgetWithText(FilledButton, 'Connect and turn on'));
        await t.pumpAndSettle();
      },
    );
  }, skip: _skip);
  testWidgets(
    'gmail setup 2 ar dark',
    (t) => app(
      t,
      '39_gmail_setup_2_ar_dark',
      locale: const Locale('ar'),
      theme: ThemeMode.dark,
      steps: () async {
        await t.tap(find.byType(Switch));
        await t.pumpAndSettle();
        await t.tap(find.text('مفعّل بالفعل'));
        await t.pumpAndSettle();
      },
    ),
    skip: _skip,
  );
  testWidgets(
    'home switch problem',
    (t) => app(
      t,
      '40_home_switch_problem_en',
      applications: switchedOn()
        ..emailConnected = false
        ..email = const MailAccount(address: 'sara@example.com', status: MailStatus.invalid, error: 'auth')
        ..problem = AutoApplyProblem.emailInvalid,
    ),
    skip: _skip,
  );

  testWidgets('details ar dark', (t) async {
    await app(
      t,
      '26_details_ar_dark',
      locale: const Locale('ar'),
      theme: ThemeMode.dark,
      steps: () async {
        await openTab(t, 'واتساب');
        await t.tap(find.text('عرض التفاصيل').first);
        await t.pumpAndSettle();
      },
    );
  }, skip: _skip);
}

final _demoTaxonomy = Taxonomy(
  roles: testTaxonomy.roles.values.toList(),
  skills: const [
    TaxonomySkill(slug: 'ccna', name: 'CCNA', group: 'networking'),
    TaxonomySkill(slug: 'bgp', name: 'BGP', group: 'networking'),
    TaxonomySkill(slug: 'ospf', name: 'OSPF', group: 'networking'),
    TaxonomySkill(slug: 'mpls', name: 'MPLS', group: 'networking'),
    TaxonomySkill(slug: 'fortinet', name: 'Fortinet', group: 'security'),
    TaxonomySkill(slug: 'linux', name: 'Linux', group: 'software'),
    TaxonomySkill(slug: 'python', name: 'Python', group: 'software'),
    TaxonomySkill(slug: 'aws', name: 'AWS', group: 'cloud'),
    TaxonomySkill(slug: 'vlan', name: 'VLAN', group: 'networking'),
  ],
  fieldNames: testTaxonomy.fieldNames,
);

MatchedJob _job(
  String id,
  String title,
  String? company,
  String? city,
  String? country,
  WorkMode? mode,
  EmploymentType? type,
  Duration age,
  int percent,
  RoleFit role,
  LevelFit level,
  List<String> skills,
  List<String> missing,
  Set<ApplyMethod> methods, {
  JobSource source = JobSource.post,
}) => MatchedJob(
  job: Job(
    id: id,
    source: source,
    title: title,
    company: company,
    city: city,
    country: country,
    workMode: mode,
    employmentType: type,
    skills: [...skills, ...missing],
    applyMethods: methods,
    url: source == JobSource.post
        ? 'https://www.linkedin.com/feed/update/urn:li:activity:$id/'
        : 'https://www.linkedin.com/jobs/view/$id/',
    postedAt: DateTime.now().subtract(age),
  ),
  match: Match(
    percent: percent,
    reasons: MatchReasons(role: role, skills: skills, missing: missing, level: level),
  ),
);

List<MatchedJob> _demoJobs() => [
  _job(
    '1',
    'Network Engineer',
    'Vodafone Egypt',
    'Cairo',
    'Egypt',
    WorkMode.hybrid,
    EmploymentType.fullTime,
    const Duration(minutes: 40),
    92,
    RoleFit.sameRole,
    LevelFit.match,
    ['ccna', 'bgp', 'ospf', 'mpls', 'vlan', 'linux'],
    ['fortinet'],
    {ApplyMethod.email, ApplyMethod.whatsapp},
  ),
  _job(
    '2',
    'Senior Network Engineer (CCNP)',
    'Orange Business Services',
    'Dubai',
    'United Arab Emirates',
    WorkMode.onsite,
    EmploymentType.fullTime,
    const Duration(hours: 20),
    78,
    RoleFit.sameRole,
    LevelFit.close,
    ['ccna', 'bgp', 'ospf'],
    ['mpls', 'fortinet', 'python'],
    {ApplyMethod.email},
  ),
  _job(
    '3',
    'مهندس مركز عمليات الشبكة NOC',
    'شركة الاتصالات السعودية',
    'الرياض',
    'Saudi Arabia',
    WorkMode.onsite,
    EmploymentType.contract,
    const Duration(days: 3),
    64,
    RoleFit.similarRole,
    LevelFit.match,
    ['ccna', 'linux'],
    ['python'],
    {ApplyMethod.whatsapp},
  ),
  _job(
    '4',
    'Cloud Network Engineer',
    'Instabug',
    null,
    null,
    WorkMode.remote,
    EmploymentType.fullTime,
    const Duration(days: 9),
    81,
    RoleFit.sameField,
    LevelFit.unknown,
    ['bgp', 'linux'],
    ['aws', 'python'],
    {ApplyMethod.easyApply},
    source: JobSource.linkedinJob,
  ),
  _job(
    '5',
    'Network Security Engineer',
    'Raya IT',
    'Giza',
    'Egypt',
    WorkMode.onsite,
    EmploymentType.fullTime,
    const Duration(days: 2),
    73,
    RoleFit.sameField,
    LevelFit.match,
    ['ccna', 'fortinet'],
    ['python'],
    {ApplyMethod.external},
    source: JobSource.linkedinJob,
  ),
  _job(
    '6',
    'IT Support Specialist',
    null,
    'Alexandria',
    'Egypt',
    null,
    null,
    const Duration(days: 40),
    38,
    RoleFit.skillsOnly,
    LevelFit.far,
    ['linux'],
    const [],
    {ApplyMethod.link},
  ),
];

Map<String, JobDetail> _demoDetails() => {
  for (final m in _demoJobs())
    m.job.id: testDetail(
      m.job,
      description:
          'We are hiring a ${m.job.title} to join our team.\n\n'
          'Requirements:\n• 2+ years with routing and switching (CCNA, BGP, OSPF)\n'
          '• Hands-on with firewalls (Fortinet)\n• Good English\n\n'
          'Send your CV to hr@vodafone.example or on WhatsApp: +20 100 123 4567',
    ),
};

List<Application> _demoApplied() {
  ApplicationState state(ApplyMethod method, Duration ago, [ApplicationStatus status = ApplicationStatus.applied]) =>
      ApplicationState(method: method, status: status, appliedAt: DateTime.now().subtract(ago));
  final jobs = _demoJobs();
  return [
    Application(job: jobs[3].job, state: state(ApplyMethod.easyApply, const Duration(hours: 2))),
    Application(job: jobs[2].job, state: state(ApplyMethod.whatsapp, const Duration(days: 1))),
    Application(job: jobs[5].job, state: state(ApplyMethod.link, const Duration(days: 4))),
  ];
}
