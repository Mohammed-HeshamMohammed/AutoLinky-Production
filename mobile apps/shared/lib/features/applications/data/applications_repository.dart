import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';
import '../../jobs/data/job.dart';

/// A job the user applied to (GET /v1/applications): the job as it was then, and how it went.
@immutable
class Application {
  /// [job] is taken as applied to with [state], whatever it says.
  Application({required Job job, required this.state, this.error, this.auto = false})
    : job = job.withApplication(state);

  factory Application.fromJson(Object? json) {
    final m = json! as Map<String, Object?>;
    final job = Job.fromJson(m['job']);
    final state =
        ApplicationState.fromJson({'method': m['method'], 'status': m['status'], 'applied_at': m['applied_at']}) ??
        ApplicationState(method: ApplyMethod.link, status: ApplicationStatus.applied, appliedAt: job.postedAt);
    final error = m['error'];
    return Application(
      job: job,
      state: state,
      error: error is String && error.isNotEmpty ? error : null,
      auto: m['auto'] == true,
    );
  }

  final Job job;
  final ApplicationState state;

  /// An e-mail that failed: why (address_refused, message_refused, interrupted).
  final String? error;

  /// Sent by auto apply, not by the user's tap.
  final bool auto;
}

@immutable
class ApplicationPage {
  const ApplicationPage({required this.items, required this.total, this.nextCursor});

  factory ApplicationPage.fromJson(Object? json) {
    final m = json! as Map<String, Object?>;
    final cursor = m['next_cursor'];
    return ApplicationPage(
      items: [for (final item in m['items'] as List? ?? const []) Application.fromJson(item)],
      total: (m['total'] as num?)?.toInt() ?? 0,
      nextCursor: cursor is String && cursor.isNotEmpty ? cursor : null,
    );
  }

  final List<Application> items;
  final int total;
  final String? nextCursor;
}

/// The Gmail Autolinky sends from (never its app password).
@immutable
class MailAccount {
  const MailAccount({
    required this.address,
    this.senderName = '',
    this.status = MailStatus.ok,
    this.error,
    this.signature,
  });

  static MailAccount? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final address = json['address'];
    if (address is! String || address.isEmpty) return null;
    final error = json['error'];
    return MailAccount(
      address: address,
      senderName: json['sender_name'] as String? ?? '',
      status: MailStatus.fromApi(json['status']),
      error: error is String && error.isNotEmpty ? error : null,
      signature: json['signature'] is String && (json['signature']! as String).isNotEmpty
          ? json['signature']! as String
          : null,
    );
  }

  final String address;

  /// The name recruiters see; the letter is signed with it.
  final String senderName;
  final MailStatus status;

  /// Why Gmail refused the app password: auth, not_app_password, blocked.
  final String? error;

  /// The lines under the name in every e-mail, as the user wrote them; null: the ones from their CV.
  final String? signature;
}

/// ok: Gmail accepted the app password. unverified: Gmail could not be asked yet (the first e-mail checks it).
/// invalid: Gmail refused it since: the user must save a new one.
enum MailStatus {
  ok('ok'),
  unverified('unverified'),
  invalid('invalid');

  const MailStatus(this.api);

  final String api;

  static MailStatus fromApi(Object? value) => values.where((v) => v.api == value).firstOrNull ?? unverified;
}

/// What stops auto apply now.
enum AutoApplyProblem {
  /// Gmail refused the saved app password.
  emailInvalid('email_invalid'),

  /// No CV to attach.
  noCv('no_cv'),

  /// The free applications are used up: subscribers only ("Upgrade").
  freeLimit('free_limit'),

  /// Gmail's own daily sending limit: paused until tomorrow.
  gmailLimit('gmail_limit'),

  /// Gmail asked to wait a little.
  gmailBusy('gmail_busy'),

  /// Autolinky's sender is not running (the server's side).
  senderOffline('sender_offline');

  const AutoApplyProblem(this.api);

  final String api;

  static AutoApplyProblem? fromApi(Object? value) => values.where((v) => v.api == value).firstOrNull;
}

/// Can Autolinky send applications for the user (their Gmail connected), is auto apply on, and how it goes
/// (GET /v1/auto-apply).
@immutable
class AutoApplyState {
  const AutoApplyState({
    required this.emailConnected,
    required this.enabled,
    this.email,
    this.minMatch = 70,
    this.dailyLimit = 20,
    this.gapMinutes = 5,
    this.sentToday = 0,
    this.nextSendAt,
    this.pausedUntil,
    this.problem,
    this.waiting,
    this.pro = false,
    this.freeLimit = 20,
    this.freeUsed = 0,
    this.freeLeft,
    this.proUntil,
    this.upgradeUrl = '',
  });

  factory AutoApplyState.fromJson(Object? json) {
    final m = json! as Map<String, Object?>;
    DateTime? date(Object? value) => value is String ? DateTime.tryParse(value)?.toLocal() : null;
    return AutoApplyState(
      emailConnected: m['email_connected'] == true,
      enabled: m['enabled'] == true,
      email: MailAccount.fromJson(m['email']),
      minMatch: (m['min_match'] as num?)?.toInt() ?? 70,
      dailyLimit: (m['daily_limit'] as num?)?.toInt() ?? 20,
      gapMinutes: (m['gap_minutes'] as num?)?.toInt() ?? 5,
      sentToday: (m['sent_today'] as num?)?.toInt() ?? 0,
      nextSendAt: date(m['next_send_at']),
      pausedUntil: date(m['paused_until']),
      problem: AutoApplyProblem.fromApi(m['problem']),
      waiting: (m['waiting'] as num?)?.toInt(),
      pro: m['plan'] == 'pro',
      freeLimit: (m['free_limit'] as num?)?.toInt() ?? 20,
      freeUsed: (m['free_used'] as num?)?.toInt() ?? 0,
      freeLeft: (m['free_left'] as num?)?.toInt(),
      proUntil: date(m['pro_until']),
      upgradeUrl: m['upgrade_url'] as String? ?? '',
    );
  }

  /// A Gmail Autolinky can send from (connected, and not refused by Gmail since).
  final bool emailConnected;
  final bool enabled;
  final MailAccount? email;

  /// Only jobs that fit at least this much (%).
  final int minMatch;

  /// At most this many e-mails a day.
  final int dailyLimit;

  /// At least this many minutes between two e-mails (the sender adds up to half of it, at random).
  final int gapMinutes;

  /// E-mails sent in the last 24 hours, by the user's taps and auto apply.
  final int sentToday;

  /// When the next e-mail may go (on only).
  final DateTime? nextSendAt;

  /// Gmail asked to wait until then.
  final DateTime? pausedUntil;
  final AutoApplyProblem? problem;

  /// The matched jobs it would send the CV to now (at most 50); null: unknown.
  final int? waiting;

  /// A subscriber: no limit to the applications by e-mail.
  final bool pro;

  /// The applications by e-mail a free user can send in all ("Send my CV" and auto apply), and how many went.
  final int freeLimit;
  final int freeUsed;

  /// Free ones left; null for a subscriber.
  final int? freeLeft;

  /// When the subscription ends; null: until it is stopped.
  final DateTime? proUntil;

  /// "Upgrade": the WhatsApp chat to subscribe, the message ready.
  final String upgradeUrl;

  /// Free ones left now (also when the API did not say).
  int get freeLeftNow => freeLeft ?? (freeLimit - freeUsed).clamp(0, freeLimit);

  /// The free applications are used up and there is no subscription: nothing more can go until they upgrade.
  bool get outOfFree => !pro && freeLeftNow <= 0;
}

/// What "Send my CV" sends (GET /v1/applications/email-preview), for the user to check first.
@immutable
class EmailPreview {
  const EmailPreview({
    required this.to,
    required this.subject,
    required this.body,
    this.from,
    this.attachment,
    this.writtenByAi = false,
  });

  factory EmailPreview.fromJson(Object? json) {
    final m = json! as Map<String, Object?>;
    return EmailPreview(
      to: m['to'] as String? ?? '',
      subject: m['subject'] as String? ?? '',
      body: m['body'] as String? ?? '',
      from: m['from_address'] as String?,
      attachment: m['attachment'] as String?,
      writtenByAi: m['written_by_ai'] == true,
    );
  }

  final String to;
  final String subject;
  final String body;

  /// The user's Gmail; null until it is connected.
  final String? from;

  /// The CV's file name as the recruiter gets it; null without a CV.
  final String? attachment;

  /// The letter was written for this job from the CV; false: the short template.
  final bool writtenByAi;
}

/// One thing auto apply did: a CV sent, or one Gmail refused.
@immutable
class ActivityItem {
  const ActivityItem({required this.jobId, required this.title, required this.sent, required this.at, this.company});

  static ActivityItem? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final raw = json['at'];
    final at = raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
    if (at == null) return null;
    return ActivityItem(
      jobId: '${json['job_id']}',
      title: json['title'] as String? ?? '',
      company: json['company'] as String?,
      sent: json['status'] == 'sent',
      at: at,
    );
  }

  final String jobId;
  final String title;
  final String? company;
  final bool sent;
  final DateTime at;
}

/// What auto apply did since the last check (GET /v1/auto-apply/activity); [now] is where the next check starts.
@immutable
class AutoApplyActivity {
  const AutoApplyActivity({
    required this.items,
    required this.enabled,
    required this.now,
    this.problem,
    this.newMatches = 0,
  });

  factory AutoApplyActivity.fromJson(Object? json) {
    final m = json! as Map<String, Object?>;
    final now = m['now'];
    return AutoApplyActivity(
      items: [for (final item in m['items'] as List? ?? const []) ?ActivityItem.fromJson(item)],
      enabled: m['enabled'] == true,
      problem: AutoApplyProblem.fromApi(m['problem']),
      newMatches: (m['new_matches'] as num?)?.toInt() ?? 0,
      now: (now is String ? DateTime.tryParse(now) : null) ?? DateTime.now().toUtc(),
    );
  }

  final List<ActivityItem> items;
  final bool enabled;
  final AutoApplyProblem? problem;

  /// New jobs that fit the user well (60%+), collected since the last check.
  final int newMatches;

  /// The server's time of this answer: the next check asks from it.
  final DateTime now;
}

/// The jobs the user applied to (/v1/applications), the Gmail Autolinky sends from (/v1/mail-account) and auto
/// apply (/v1/auto-apply).
class ApplicationsRepository {
  const ApplicationsRepository(this._api);

  final ApiClient _api;

  Future<ApplicationPage> list({String? cursor}) =>
      _api.get('/v1/applications', ApplicationPage.fromJson, query: {'cursor': cursor});

  /// The user applied to [jobId] this way. "email": Autolinky sends the CV now, from the user's Gmail: the answer
  /// says sent or failed; nothing sent: ApiFailure email_not_connected / email_invalid / cv_needed (409),
  /// daily_limit / gmail_limit (429), gmail_busy / mail_unavailable (503).
  /// [letter]: "email" only, the letter as the user edited it (what they saw, changed or not).
  Future<Application> record(String jobId, ApplyMethod method, {String? letter}) =>
      _api.post('/v1/applications', {'job_id': jobId, 'method': method.api, 'letter': ?letter}, Application.fromJson);

  /// "I did not apply after all". An e-mail already sent stays: ApiFailure 409 already_sent.
  Future<void> withdraw(String jobId) => _api.delete('/v1/applications/$jobId');

  Future<AutoApplyState> autoApply() => _api.get('/v1/auto-apply', AutoApplyState.fromJson);

  /// Turning it on needs the Gmail connected and a CV: ApiFailure 409 email_not_connected / email_invalid /
  /// cv_needed.
  Future<AutoApplyState> setAutoApply({bool? enabled, int? minMatch, int? dailyLimit, int? gapMinutes}) => _api.put(
    '/v1/auto-apply',
    {'enabled': ?enabled, 'min_match': ?minMatch, 'daily_limit': ?dailyLimit, 'gap_minutes': ?gapMinutes},
    AutoApplyState.fromJson,
  );

  /// Saves the Gmail Autolinky sends from once Gmail accepted [appPassword] (else ApiFailure 422
  /// wrong_app_password / not_app_password / gmail_blocked / invalid_app_password). Without [appPassword]: the
  /// name only (same address).
  /// [signature]: the lines under the name ("" = the CV's again; null = unchanged).
  Future<AutoApplyState> connectGmail({
    required String address,
    required String senderName,
    String? appPassword,
    String? signature,
  }) => _api.put('/v1/mail-account', {
    'address': address,
    'sender_name': senderName,
    'app_password': ?appPassword,
    'signature': ?signature,
  }, AutoApplyState.fromJson);

  /// The signature the user's CV gives (📧 e-mail, 📞 phone, 🔗 LinkedIn), to start from.
  Future<String> suggestedSignature() =>
      _api.get('/v1/mail-account/signature', (data) => (data! as Map<String, Object?>)['signature'] as String? ?? '');

  /// Forgets the Gmail (auto apply turns off).
  Future<void> disconnectGmail() => _api.delete('/v1/mail-account');

  /// The e-mail "Send my CV" would send for [jobId]. The first time for a job the AI writes the letter (a few
  /// seconds).
  Future<EmailPreview> emailPreview(String jobId) =>
      _api.get('/v1/applications/email-preview', EmailPreview.fromJson, query: {'job_id': jobId});

  /// What auto apply did after [after].
  Future<AutoApplyActivity> activity(DateTime after) => _api.get(
    '/v1/auto-apply/activity',
    AutoApplyActivity.fromJson,
    query: {'after': after.toUtc().toIso8601String()},
  );
}

final applicationsRepositoryProvider = Provider<ApplicationsRepository>(
  (ref) => ApplicationsRepository(ref.watch(apiClientProvider)),
);
