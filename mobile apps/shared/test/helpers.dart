import 'dart:async';

import 'package:autolinky/app/app.dart';
import 'package:autolinky/core/config/env.dart';
import 'package:autolinky/core/config/providers.dart';
import 'package:autolinky/core/errors/app_failure.dart';
import 'package:autolinky/core/notice/service_notice.dart';
import 'package:autolinky/core/theme/app_theme.dart';
import 'package:autolinky/core/updates/app_updates.dart';
import 'package:autolinky/features/applications/data/applications_repository.dart';
import 'package:autolinky/features/auth/application/auth_providers.dart';
import 'package:autolinky/features/auth/data/auth_repository.dart';
import 'package:autolinky/features/auto_apply/application/background_check.dart';
import 'package:autolinky/features/auto_apply/application/notifications.dart';
import 'package:autolinky/features/auto_apply/presentation/pro_celebration.dart';
import 'package:autolinky/features/jobs/application/external_apps.dart';
import 'package:autolinky/features/jobs/application/jobs_providers.dart';
import 'package:autolinky/features/jobs/data/apply_channel.dart';
import 'package:autolinky/features/jobs/data/jobs_repository.dart';
import 'package:autolinky/features/matches/data/matches_repository.dart';
import 'package:autolinky/features/matches/data/models.dart';
import 'package:autolinky/features/profile/application/profile_providers.dart';
import 'package:autolinky/features/profile/data/account_repository.dart';
import 'package:autolinky/features/profile/data/models.dart';
import 'package:autolinky/features/profile/data/profile_repository.dart';
import 'package:autolinky/features/settings/application/settings_controller.dart';
import 'package:autolinky/features/taxonomy/taxonomy.dart';
import 'package:autolinky/l10n/gen/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const testEnv = Env(
  apiBaseUrl: 'https://api.test',
  firebaseApiKey: 'public-test-key',
  firebaseAppId: '1:test:web:test',
  emailLinkContinueUrl: 'https://app.test/welcome/email/verify',
  googleWebClientId: 'web-client.apps.googleusercontent.com',
);

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockMatchesRepository extends Mock implements MatchesRepository {}

class MockJobsRepository extends Mock implements JobsRepository {}

class MockApplicationsRepository extends Mock implements ApplicationsRepository {}

/// What mocktail's any() needs for these types.
void _fallbacks() {
  registerFallbackValue(ApplyChannel.email);
  registerFallbackValue(ApplyMethod.email);
  registerFallbackValue(DateTime(2026));
}

/// A finished profile (the user already went through the setup).
const testProfile = Profile(
  headline: 'Network Engineer',
  targetRoles: ['network_engineer'],
  skills: ['ccna', 'bgp'],
  level: 'mid',
  yearsExperience: 3,
  searchTitles: ['Network Engineer', 'NOC Engineer'],
  searchScope: SearchScope.egypt,
);

final testTaxonomy = Taxonomy(
  roles: const [
    TaxonomyRole(slug: 'network_engineer', field: 'networking', nameEn: 'Network Engineer', nameAr: 'مهندس شبكات'),
    TaxonomyRole(slug: 'noc_engineer', field: 'networking', nameEn: 'NOC Engineer', nameAr: 'مهندس مركز عمليات'),
    TaxonomyRole(slug: 'data_analyst', field: 'data_ai', nameEn: 'Data Analyst', nameAr: 'محلل بيانات'),
  ],
  skills: const [
    TaxonomySkill(slug: 'ccna', name: 'CCNA', group: 'networking'),
    TaxonomySkill(slug: 'bgp', name: 'BGP', group: 'networking'),
    TaxonomySkill(slug: 'python', name: 'Python', group: 'software'),
  ],
  fieldNames: const {'networking': (en: 'Networking', ar: 'الشبكات'), 'data_ai': (en: 'Data & AI', ar: 'البيانات')},
);

/// Profile + CV on a fake API: [profile] / [cv] are what GET answers; saves are recorded and answered.
class FakeProfileApi {
  FakeProfileApi({this.profile = testProfile, this.cv}) {
    when(() => repo.profile()).thenAnswer((_) async => profile);
    when(() => repo.cv()).thenAnswer((_) async => cv);
    when(() => repo.save(any())).thenAnswer((call) async {
      final fields = call.positionalArguments.first as Map<String, Object?>;
      saved.add(fields);
      profile = Profile(
        headline: fields['headline'] as String?,
        targetRoles: (fields['target_roles'] as List<String>?) ?? profile?.targetRoles ?? const [],
        skills: (fields['skills'] as List<String>?) ?? profile?.skills ?? const [],
        searchTitles: (fields['search_titles'] as List<String>?) ?? profile?.searchTitles ?? const [],
        level: fields.containsKey('level') ? fields['level'] as String? : profile?.level,
        searchScope: fields.containsKey('search_scope')
            ? SearchScope.fromApi(fields['search_scope'])
            : profile?.searchScope,
      );
      return profile!;
    });
    when(() => repo.deleteCv()).thenAnswer((_) async {});
    when(() => repo.searchStatus()).thenAnswer((_) async {
      statusChecks++;
      if (failStatus) throw const ApiFailure(statusCode: 503, code: 'unavailable');
      return status;
    });
    when(() => repo.searchNow()).thenAnswer((_) async {
      liveAsks++;
      if (failStatus) throw const ApiFailure(statusCode: 503, code: 'unavailable');
      return status;
    });
  }

  final repo = MockProfileRepository();
  Profile? profile;
  CvInfo? cv;
  final saved = <Map<String, Object?>>[];

  /// What GET /v1/profile/search-status and POST /v1/profile/search-now answer (the default: nothing searched now).
  SearchStatus status = const SearchStatus();
  bool failStatus = false;
  int statusChecks = 0;

  /// POST /v1/profile/search-now calls (a live search of the user's titles asked for).
  int liveAsks = 0;
}

/// A job as the API lists it: the [i]-th, posted 3 + [i] hours ago, applied to by e-mail unless [methods] says.
Job testListJob(
  int i, {
  String? title,
  Set<ApplyMethod> methods = const {ApplyMethod.email},
  JobSource source = JobSource.post,
  List<String> skills = const ['ccna', 'bgp'],
  ApplicationState? application,
}) => Job(
  id: 'job-$i',
  source: source,
  title: title ?? 'Network Engineer $i',
  company: 'Vodafone Egypt',
  city: 'Cairo',
  country: 'Egypt',
  workMode: WorkMode.hybrid,
  employmentType: EmploymentType.fullTime,
  skills: skills,
  applyMethods: methods,
  url: source == JobSource.post
      ? 'https://www.linkedin.com/feed/update/urn:li:activity:$i/'
      : 'https://www.linkedin.com/jobs/view/$i/',
  postedAt: DateTime.now().subtract(Duration(hours: 3 + i)),
  application: application,
);

/// A matched job as the API sends it: the [i]-th best ([percent] 92 - i).
MatchedJob testJob(
  int i, {
  String? title,
  int? percent,
  List<String> skills = const ['ccna', 'bgp'],
  List<String> missing = const ['python'],
  Set<ApplyMethod> methods = const {ApplyMethod.email},
  JobSource source = JobSource.post,
  ApplicationState? application,
}) => MatchedJob(
  job: testListJob(i, title: title, methods: methods, source: source, application: application),
  match: Match(
    percent: percent ?? 92 - i,
    reasons: MatchReasons(role: RoleFit.sameRole, skills: skills, missing: missing, level: LevelFit.match),
  ),
);

/// GET /v1/jobs/matched on a fake API: the [jobs] of the channel asked for, in pages of [pageSize] (the cursor is
/// the next offset). Records the cursors and channels asked for; [fail] makes the next call fail, [failOn] every
/// call for that cursor.
class FakeMatchesApi {
  FakeMatchesApi({List<MatchedJob>? jobs, this.pageSize = 20})
    : jobs = jobs ?? [for (var i = 0; i < 3; i++) testJob(i)] {
    _fallbacks();
    when(() => repo.matched(any(), cursor: any(named: 'cursor'))).thenAnswer((call) async {
      final channel = call.positionalArguments.first as ApplyChannel;
      final cursor = call.namedArguments[#cursor] as String?;
      calls.add(cursor);
      channels.add(channel);
      if (fail case final failure?) {
        fail = null;
        throw failure;
      }
      if (failOn.containsKey(cursor)) throw failOn[cursor]!;
      final mine = this.jobs.where((m) => channel.offeredBy(m.job)).toList();
      final start = cursor == null ? 0 : int.parse(cursor);
      final end = (start + pageSize).clamp(0, mine.length);
      return MatchedPage(items: mine.sublist(start, end), nextCursor: end < mine.length ? '$end' : null);
    });
    when(() => repo.newMatches(any())).thenAnswer((call) async {
      newChecks.add(call.positionalArguments.first as DateTime);
      return (count: newCount, now: DateTime.now().toUtc());
    });
    when(() => repo.best(limit: any(named: 'limit'))).thenAnswer((_) async {
      bestCalls++;
      return MatchedPage(items: List.of(this.jobs));
    });
  }

  /// GET /v1/jobs/matched without a channel (the first jobs of a new user): every job, best first.
  int bestCalls = 0;

  final repo = MockMatchesRepository();
  List<MatchedJob> jobs;

  /// What GET /v1/jobs/matched/new answers.
  int newCount = 0;
  final newChecks = <DateTime>[];
  final int pageSize;
  final calls = <String?>[];
  final channels = <ApplyChannel>[];
  Object? fail;
  final failOn = <String?, Object>{};
}

/// Everything the details of a job give: its text and every way to apply.
JobDetail testDetail(Job job, {String? description}) => JobDetail(
  job: job,
  description: description ?? 'We are hiring a ${job.title}.\nSend your CV to hr@vodafone.example',
  contacts: const [
    Contact(type: ApplyMethod.email, value: 'hr@vodafone.example'),
    Contact(type: ApplyMethod.whatsapp, value: '+201001234567', label: 'EG'),
    Contact(type: ApplyMethod.link, value: 'https://forms.gle/apply123'),
    Contact(type: ApplyMethod.dm, value: 'https://www.linkedin.com/in/sara-hr'),
    Contact(type: ApplyMethod.comment, value: 'https://www.linkedin.com/feed/update/urn:li:activity:1/'),
  ],
  authorUrl: 'https://www.linkedin.com/in/sara-hr',
);

/// GET /v1/jobs and /v1/jobs/{id} on a fake API: [jobs] filtered by the words (in the title) and the channel, in
/// pages of [pageSize]; a job's details from [details], else [testDetail].
class FakeJobsApi {
  FakeJobsApi({List<Job>? jobs, this.pageSize = 20, Map<String, JobDetail>? details})
    : jobs = jobs ?? [for (var i = 0; i < 3; i++) testListJob(i)],
      details = details ?? {} {
    _fallbacks();
    when(
      () => repo.jobs(
        query: any(named: 'query'),
        channel: any(named: 'channel'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((call) async {
      final query = (call.namedArguments[#query] as String?)?.trim().toLowerCase() ?? '';
      final channel = call.namedArguments[#channel] as ApplyChannel?;
      final cursor = call.namedArguments[#cursor] as String?;
      searches.add((query, channel));
      final found = this.jobs
          .where((j) => j.title.toLowerCase().contains(query) && (channel == null || channel.offeredBy(j)))
          .toList();
      final start = cursor == null ? 0 : int.parse(cursor);
      final end = (start + pageSize).clamp(0, found.length);
      return JobPage(items: found.sublist(start, end), nextCursor: end < found.length ? '$end' : null);
    });
    when(() => repo.detail(any())).thenAnswer((call) async {
      final id = call.positionalArguments.first as String;
      detailCalls.add(id);
      if (detailDelay > Duration.zero) await Future<void>.delayed(detailDelay); // a real network is not instant
      if (failDetail case final failure?) {
        failDetail = null;
        throw failure;
      }
      return this.details[id] ?? testDetail(Job(id: id, title: 'Network Engineer', postedAt: DateTime.now()));
    });
  }

  final repo = MockJobsRepository();
  List<Job> jobs;
  final int pageSize;
  final Map<String, JobDetail> details;
  final searches = <(String, ApplyChannel?)>[];
  final detailCalls = <String>[];
  Object? failDetail;

  /// How long GET /v1/jobs/{id} takes.
  Duration detailDelay = Duration.zero;
}

/// /v1/applications and /v1/auto-apply on a fake API. [jobs] names the jobs the user applies to (else a plain one).
class FakeApplicationsApi {
  FakeApplicationsApi({List<Application>? applied, this.jobs = const {}}) : applied = applied ?? [] {
    _fallbacks();
    when(() => repo.list(cursor: any(named: 'cursor')))
        .thenAnswer((_) async => ApplicationPage(items: List.of(this.applied), total: this.applied.length));
    when(() => repo.record(any(), any(), letter: any(named: 'letter'))).thenAnswer((call) async {
      final id = call.positionalArguments[0] as String;
      final method = call.positionalArguments[1] as ApplyMethod;
      recorded.add((id, method));
      if (call.namedArguments[#letter] case final String letter) letters.add(letter);
      if (failRecord case final failure?) throw failure;
      final status = method != ApplyMethod.email
          ? ApplicationStatus.applied
          : (sendFails == null ? ApplicationStatus.sent : ApplicationStatus.failed);
      final state = ApplicationState(method: method, status: status, appliedAt: DateTime.now());
      final job = jobs[id] ?? Job(id: id, title: 'Job $id', postedAt: DateTime.now());
      final saved = Application(job: job, state: state, error: method == ApplyMethod.email ? sendFails : null);
      this.applied
        ..removeWhere((a) => a.job.id == id)
        ..insert(0, saved);
      return saved;
    });
    when(() => repo.withdraw(any())).thenAnswer((call) async {
      final id = call.positionalArguments.first as String;
      withdrawn.add(id);
      if (failWithdraw case final failure?) throw failure;
      this.applied.removeWhere((a) => a.job.id == id);
    });
    when(repo.autoApply).thenAnswer((_) async => state);
    when(
      () => repo.setAutoApply(
        enabled: any(named: 'enabled'),
        minMatch: any(named: 'minMatch'),
        dailyLimit: any(named: 'dailyLimit'),
        gapMinutes: any(named: 'gapMinutes'),
      ),
    ).thenAnswer((call) async {
      final enabled = call.namedArguments[#enabled] as bool?;
      autoApplyCalls.add({
        'enabled': ?enabled,
        'min_match': ?call.namedArguments[#minMatch] as int?,
        'daily_limit': ?call.namedArguments[#dailyLimit] as int?,
        'gap_minutes': ?call.namedArguments[#gapMinutes] as int?,
      });
      if ((enabled ?? false) && !emailConnected) throw const ApiFailure(statusCode: 409, code: 'email_not_connected');
      autoApplyOn = enabled ?? autoApplyOn;
      minMatch = call.namedArguments[#minMatch] as int? ?? minMatch;
      dailyLimit = call.namedArguments[#dailyLimit] as int? ?? dailyLimit;
      gapMinutes = call.namedArguments[#gapMinutes] as int? ?? gapMinutes;
      return state;
    });
    when(
      () => repo.connectGmail(
        address: any(named: 'address'),
        senderName: any(named: 'senderName'),
        appPassword: any(named: 'appPassword'),
        signature: any(named: 'signature'),
      ),
    ).thenAnswer((call) async {
      final password = call.namedArguments[#appPassword] as String?;
      gmailCalls.add((call.namedArguments[#address] as String, call.namedArguments[#senderName] as String, password));
      signatures.add(call.namedArguments[#signature] as String?);
      if (refuseGmail case final code?) throw ApiFailure(statusCode: 422, code: code);
      emailConnected = true;
      final signature = call.namedArguments[#signature] as String?;
      email = MailAccount(
        address: call.namedArguments[#address] as String,
        signature: signature == null ? email?.signature : (signature.isEmpty ? null : signature),
      );
      return state;
    });
    when(repo.suggestedSignature).thenAnswer((_) async => cvSignature);
    when(repo.disconnectGmail).thenAnswer((_) async {
      emailConnected = false;
      email = null;
      autoApplyOn = false;
    });
    when(() => repo.emailPreview(any())).thenAnswer((call) async {
      final id = call.positionalArguments.first as String;
      return EmailPreview(
        from: email?.address,
        to: 'hr@vodafone.example',
        subject: 'Application for ${jobs[id]?.title ?? 'Network Engineer'} – Sara Ali',
        body:
            'Dear Vodafone Egypt Hiring Team,\n\nMy NOC work at Orange fits this role.\n\nSincerely,\nSara Ali\n'
            '$cvSignature\n',
        attachment: hasCv ? 'Sara Ali - CV.pdf' : null,
        writtenByAi: true,
      );
    });
    when(() => repo.activity(any()))
        .thenAnswer((_) async => AutoApplyActivity(items: const [], enabled: autoApplyOn, now: DateTime.now().toUtc()));
  }

  final repo = MockApplicationsRepository();
  final List<Application> applied;
  final Map<String, Job> jobs;
  final recorded = <(String, ApplyMethod)>[];
  final withdrawn = <String>[];
  final autoApplyCalls = <Map<String, Object>>[];

  /// The letters "Send my CV" sent, as the user left them.
  final letters = <String>[];

  /// The signature each PUT /v1/mail-account saved (null: unchanged, "": the CV's again).
  final signatures = <String?>[];

  /// What GET /v1/mail-account/signature answers.
  String cvSignature = '📧 sara.ali@gmail.com\n📞 +201001234567';

  /// PUT /v1/mail-account calls: (address, name, app password).
  final gmailCalls = <(String, String, String?)>[];
  bool emailConnected = false;
  MailAccount? email;
  bool autoApplyOn = false;
  int minMatch = 70;
  int dailyLimit = 20;
  int gapMinutes = 5;
  int sentToday = 0;
  AutoApplyProblem? problem;
  bool hasCv = true;

  /// The next PUT /v1/mail-account answers 422 with this code (wrong_app_password...).
  String? refuseGmail;

  /// How the next e-mail goes: sent, or failed with this error code.
  String? sendFails;
  Object? failRecord;
  Object? failWithdraw;

  AutoApplyState get state => AutoApplyState(
    emailConnected: emailConnected,
    enabled: autoApplyOn,
    email: email ?? (emailConnected ? const MailAccount(address: 'sara.ali@gmail.com') : null),
    minMatch: minMatch,
    dailyLimit: dailyLimit,
    gapMinutes: gapMinutes,
    sentToday: sentToday,
    problem: problem,
    waiting: 4,
    nextSendAt: autoApplyOn ? DateTime.now().add(const Duration(minutes: 5)) : null,
    pro: pro,
    freeUsed: freeUsed,
    freeLeft: pro ? null : (20 - freeUsed).clamp(0, 20),
    proUntil: proUntil,
    upgradeUrl: upgradeUrl,
  );

  /// The plan: a subscriber, or a free user with this many of their 20 free e-mails used.
  bool pro = false;
  int freeUsed = 0;
  DateTime? proUntil;
  String upgradeUrl = 'https://wa.me/201060933358?text=Hello%2C%20I%20want%20to%20subscribe';
}

/// The phone's background check, recorded instead of scheduled.
class FakeBackground implements BackgroundActivity {
  int starts = 0;
  int stops = 0;

  @override
  Future<void> start() async => starts++;

  @override
  Future<void> stop() async => stops++;
}

/// Notifications, recorded instead of shown; [allowed]: the answer to the permission question.
class FakeNotifications implements AutoApplyNotifications {
  bool allowed = true;
  int asked = 0;

  @override
  Future<bool> requestPermission() async {
    asked++;
    return allowed;
  }

  @override
  Future<void> showSent(AppLocalizations l10n, List<ActivityItem> sent) async {}

  @override
  Future<void> showProblem(AppLocalizations l10n, AutoApplyProblem problem) async {}

  @override
  Future<void> showNewMatches(AppLocalizations l10n, int count) async {}
}

/// Instead of WhatsApp / LinkedIn / the browser: records what would open; [opens] = false, nothing can;
/// [comesBack] = false, the user never left the app.
class FakeLinks {
  final opened = <Uri>[];
  bool opens = true;
  bool comesBack = true;

  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return opens;
  }

  Future<bool> back() async => comesBack;
}

CvInfo testCv({String analysis = 'full'}) => CvInfo(
  fileName: 'Sara Ali CV.pdf',
  fileType: 'pdf',
  fileSize: 120000,
  pages: 2,
  analysis: analysis,
  uploadedAt: DateTime(2026, 10, 5),
);

/// An auth repository whose session the test sets, with a working change stream.
class FakeAuth {
  FakeAuth() {
    when(() => repo.authStateChanges).thenAnswer((_) => _changes.stream);
    when(() => repo.currentUser).thenAnswer((_) => session?.user);
    when(() => repo.signInMethod).thenReturn(SignInMethod.google);
    when(() => repo.accessToken(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => session?.accessToken);
    when(() => repo.signOut()).thenAnswer((_) async => signIn(null));
  }

  final repo = MockAuthRepository();
  final _changes = StreamController<User?>.broadcast();
  TestSession? session;

  void signIn(TestSession? value) {
    session = value;
    _changes.add(value?.user);
  }

  Future<void> dispose() => _changes.close();
}

class TestSession {
  const TestSession(this.user);
  final User user;
  String get accessToken => 'token-1';
}

class MockFirebaseUser extends Mock implements User {}

TestSession testSession({String email = 'sara@example.com', String? name = 'Sara Ali'}) {
  final user = MockFirebaseUser();
  when(() => user.uid).thenReturn('firebase-opaque-user-1');
  when(() => user.email).thenReturn(email);
  when(() => user.displayName).thenReturn(name);
  when(() => user.photoURL).thenReturn(null);
  when(() => user.providerData).thenReturn([]);
  return TestSession(user);
}

Future<SharedPreferencesWithCache> testPreferences([Map<String, Object> values = const {}]) async {
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData(values);
  return SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: {...SettingsController.keys, lastNoticedPatchKey, proCelebratedKey, hideAppliedKey},
    ),
  );
}

Future<List<Override>> baseOverrides({
  required FakeAuth auth,
  AccountRepository? account,
  Env env = testEnv,
  SharedPreferencesWithCache? prefs,
  FakeProfileApi? profiles,
  FakeMatchesApi? matches,
  FakeJobsApi? jobs,
  FakeApplicationsApi? applications,
  FakeLinks? links,
  Taxonomy? taxonomy,
  CvPicker? picker,
  FakeBackground? background,
  FakeNotifications? notifications,
  PatchReader? patch,
  NoticeReader? notice,
}) async {
  final accounts = account ?? MockAccountRepository();
  if (account == null) {
    when((accounts as MockAccountRepository).me)
        .thenAnswer((_) async => const Account(userId: 'u1', email: 'sara@example.com'));
  }
  return [
    envProvider.overrideWithValue(env),
    preferencesProvider.overrideWithValue(prefs ?? await testPreferences()),
    appVersionProvider.overrideWithValue('1.0.0 (1)'),
    patchReaderProvider.overrideWithValue(patch ?? () async => null),
    serviceNoticeReaderProvider.overrideWithValue(notice ?? () async => null),
    authRepositoryProvider.overrideWithValue(auth.repo),
    incomingAuthLinksProvider.overrideWith((ref) => const Stream<Uri>.empty()),
    accountRepositoryProvider.overrideWithValue(accounts),
    profileRepositoryProvider.overrideWithValue((profiles ?? FakeProfileApi()).repo),
    matchesRepositoryProvider.overrideWithValue((matches ?? FakeMatchesApi()).repo),
    jobsRepositoryProvider.overrideWithValue((jobs ?? FakeJobsApi()).repo),
    applicationsRepositoryProvider.overrideWithValue((applications ?? FakeApplicationsApi()).repo),
    linkOpenerProvider.overrideWithValue((links ?? FakeLinks()).open),
    returnWaiterProvider.overrideWithValue((links ?? FakeLinks()).back),
    taxonomyProvider.overrideWith((ref) async => taxonomy ?? testTaxonomy),
    cvPickerProvider.overrideWithValue(picker ?? () async => null),
    backgroundActivityProvider.overrideWithValue(background ?? FakeBackground()),
    autoApplyNotificationsProvider.overrideWithValue(notifications ?? FakeNotifications()),
  ];
}

/// A common phone: 393 x 851 points (Pixel 7 class).
void usePhoneSize(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1179, 2553)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// One screen inside the app's theme and languages, on a phone-sized screen.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  required List<Override> overrides,
  Locale locale = const Locale('en'),
}) async {
  usePhoneSize(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      retry: (_, _) => null,
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: appLocalizationsDelegates,
        home: screen,
      ),
    ),
  );
  await tester.pump();
}

/// pumpAndSettle that gives up after 10 seconds (the default waits 10 minutes) and says so.
Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
  const Duration(milliseconds: 100),
  EnginePhase.sendSemanticsUpdate,
  const Duration(seconds: 10),
);
