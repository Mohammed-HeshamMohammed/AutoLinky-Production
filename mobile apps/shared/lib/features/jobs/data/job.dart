import 'package:flutter/foundation.dart';

// The API's jobs (GET /v1/jobs, /v1/jobs/matched, /v1/jobs/{id}, /v1/applications), shared by every tab.

enum JobSource {
  post('post'),
  linkedinJob('linkedin_job');

  const JobSource(this.api);

  final String api;

  static JobSource fromApi(Object? value) => values.where((v) => v.api == value).firstOrNull ?? post;
}

enum WorkMode {
  onsite('onsite'),
  remote('remote'),
  hybrid('hybrid');

  const WorkMode(this.api);

  final String api;

  static WorkMode? fromApi(Object? value) => values.where((v) => v.api == value).firstOrNull;
}

/// Null for the API's "unknown".
enum EmploymentType {
  fullTime('full_time'),
  partTime('part_time'),
  contract('contract'),
  temporary('temporary'),
  internship('internship'),
  freelance('freelance'),
  volunteer('volunteer');

  const EmploymentType(this.api);

  final String api;

  static EmploymentType? fromApi(Object? value) => values.where((v) => v.api == value).firstOrNull;
}

/// The ways a job can be applied to, as the collector found them: a post's contacts (email, phone, whatsapp,
/// link, "DM me", "comment") or a LinkedIn job's button (Easy Apply, or the company's site).
enum ApplyMethod {
  email('email'),
  phone('phone'),
  whatsapp('whatsapp'),
  link('link'),
  dm('dm'),
  comment('comment'),
  easyApply('easy_apply'),
  external('external');

  const ApplyMethod(this.api);

  final String api;

  static ApplyMethod? fromApi(Object? value) => values.where((v) => v.api == value).firstOrNull;
}

/// applied: the user said so after opening the way; queued / sent / failed: an e-mail Autolinky sends for them.
enum ApplicationStatus {
  applied('applied'),
  queued('queued'),
  sent('sent'),
  failed('failed');

  const ApplicationStatus(this.api);

  final String api;

  static ApplicationStatus fromApi(Object? value) => values.where((v) => v.api == value).firstOrNull ?? applied;
}

/// The user applied to the job: how, where it is, when.
@immutable
class ApplicationState {
  const ApplicationState({required this.method, required this.status, required this.appliedAt});

  static ApplicationState? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final method = ApplyMethod.fromApi(json['method']);
    final at = _date(json['applied_at']);
    if (method == null || at == null) return null;
    return ApplicationState(method: method, status: ApplicationStatus.fromApi(json['status']), appliedAt: at);
  }

  final ApplyMethod method;
  final ApplicationStatus status;
  final DateTime appliedAt;
}

List<String> _strings(Object? value) => value is List ? value.whereType<String>().toList() : const [];

String? _text(Object? value) => value is String && value.trim().isNotEmpty ? value.trim() : null;

DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value)?.toLocal() : null;

/// One job as the lists show it. No contact details: GET /v1/jobs/{id} has them ([JobDetail]).
@immutable
class Job {
  const Job({
    required this.id,
    required this.title,
    required this.postedAt,
    this.source = JobSource.post,
    this.company,
    this.city,
    this.country,
    this.workMode,
    this.employmentType,
    this.skills = const [],
    this.applyMethods = const {},
    this.language = 'en',
    this.url,
    this.application,
  });

  factory Job.fromJson(Object? json) {
    final m = json! as Map<String, Object?>;
    return Job(
      id: m['id']! as String,
      source: JobSource.fromApi(m['source']),
      title: (m['title'] as String?)?.trim() ?? '',
      company: _text(m['company']),
      city: _text(m['city']),
      country: _text(m['country']),
      workMode: WorkMode.fromApi(m['work_mode']),
      employmentType: EmploymentType.fromApi(m['employment_type']),
      skills: _strings(m['skills']),
      applyMethods: {for (final s in _strings(m['apply_methods'])) ?ApplyMethod.fromApi(s)},
      language: _text(m['language']) ?? 'en',
      url: _text(m['url']),
      postedAt: _date(m['posted_at']) ?? DateTime.now(),
      application: ApplicationState.fromJson(m['application']),
    );
  }

  final String id;
  final JobSource source;
  final String title;
  final String? company;
  final String? city;
  final String? country;
  final WorkMode? workMode;
  final EmploymentType? employmentType;

  /// Taxonomy slugs, the ones that weigh most first.
  final List<String> skills;
  final Set<ApplyMethod> applyMethods;

  /// The language of the ad ("en", "ar"...): a message to the recruiter is written in it.
  final String language;

  /// The post on LinkedIn, or the LinkedIn job page.
  final String? url;
  final DateTime postedAt;

  /// How and when the user applied, as the API knew it when the list was loaded.
  final ApplicationState? application;

  /// The same job, applied to that way (or not: null).
  Job withApplication(ApplicationState? application) => Job(
    id: id,
    title: title,
    postedAt: postedAt,
    source: source,
    company: company,
    city: city,
    country: country,
    workMode: workMode,
    employmentType: employmentType,
    skills: skills,
    applyMethods: applyMethods,
    language: language,
    url: url,
    application: application,
  );

  /// "Cairo, Egypt"; null when the job gives no place.
  String? get place {
    final parts = [?city, if (country != null && country!.toLowerCase() != city?.toLowerCase()) country!];
    return parts.isEmpty ? null : parts.join(', ');
  }
}

/// A way to apply found in a post: an address, a number in E.164 (+20...), a URL, or the author / post for a
/// message / a comment.
@immutable
class Contact {
  const Contact({required this.type, required this.value, this.label});

  final ApplyMethod type;
  final String value;
  final String? label;
}

/// Everything about one job (GET /v1/jobs/{id}): its full text and every way to apply.
@immutable
class JobDetail {
  const JobDetail({
    required this.job,
    this.description,
    this.contacts = const [],
    this.authorUrl,
    this.companyUrl,
    this.applicants,
  });

  factory JobDetail.fromJson(Object? json) {
    final m = json! as Map<String, Object?>;
    return JobDetail(
      job: Job.fromJson(m),
      description: _text(m['description']),
      contacts: [
        for (final c in m['contacts'] as List? ?? const [])
          if (c case {'type': final String type, 'value': final String value} when ApplyMethod.fromApi(type) != null)
            Contact(type: ApplyMethod.fromApi(type)!, value: value, label: _text(c['label'])),
      ],
      authorUrl: _text(m['author_url']),
      companyUrl: _text(m['company_url']),
      applicants: _text(m['applicants']),
    );
  }

  final Job job;

  /// The post's text, or the LinkedIn job's description.
  final String? description;
  final List<Contact> contacts;
  final String? authorUrl;
  final String? companyUrl;

  /// LinkedIn jobs: "Over 200 applicants".
  final String? applicants;

  /// The first contact of these types, in this order of preference.
  Contact? contact(List<ApplyMethod> types) {
    for (final type in types) {
      final found = contacts.where((c) => c.type == type).firstOrNull;
      if (found != null) return found;
    }
    return null;
  }
}

/// A page of GET /v1/jobs; [nextCursor] is null on the last one.
@immutable
class JobPage {
  const JobPage({required this.items, this.nextCursor});

  factory JobPage.fromJson(Object? json) {
    final m = json! as Map<String, Object?>;
    return JobPage(
      items: [for (final item in m['items'] as List? ?? const []) Job.fromJson(item)],
      nextCursor: _text(m['next_cursor']),
    );
  }

  final List<Job> items;
  final String? nextCursor;
}
