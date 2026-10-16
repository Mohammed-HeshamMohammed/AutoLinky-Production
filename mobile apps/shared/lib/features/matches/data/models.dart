import 'package:flutter/foundation.dart';

import '../../jobs/data/job.dart';

export '../../jobs/data/job.dart';

/// How the job's role relates to the user's jobs (match_reasons.role), closest first.
enum RoleFit {
  sameRole('same_role'),
  similarRole('similar_role'),
  sameField('same_field'),
  relatedField('related_field'),
  skillsOnly('skills_only');

  const RoleFit(this.api);

  final String api;

  static RoleFit fromApi(Object? value) => values.where((v) => v.api == value).firstOrNull ?? skillsOnly;
}

/// The job's level against the user's (match_reasons.level).
enum LevelFit {
  match('match'),
  close('close'),
  far('far'),
  unknown('unknown');

  const LevelFit(this.api);

  final String api;

  static LevelFit fromApi(Object? value) => values.where((v) => v.api == value).firstOrNull ?? unknown;
}

/// Strong / fair / weak: the color of a match percent. 100 needs every part of the match near perfect
/// (backend/README.md, "Matching"): the same job with half the skills is already about 75.
enum MatchTier {
  high,
  medium,
  low;

  static const highFrom = 70;
  static const mediumFrom = 50;

  static MatchTier of(int percent) => percent >= highFrom
      ? high
      : percent >= mediumFrom
      ? medium
      : low;
}

List<String> _strings(Object? value) => value is List ? value.whereType<String>().toList() : const [];

/// Why a job matched (GET /v1/jobs/matched match_reasons). Skills are slugs of the taxonomy.
@immutable
class MatchReasons {
  const MatchReasons({
    this.role = RoleFit.skillsOnly,
    this.skills = const [],
    this.missing = const [],
    this.level = LevelFit.unknown,
  });

  factory MatchReasons.fromJson(Object? json) {
    final m = json is Map<String, Object?> ? json : const <String, Object?>{};
    return MatchReasons(
      role: RoleFit.fromApi(m['role']),
      skills: _strings(m['skills']),
      missing: _strings(m['missing']),
      level: LevelFit.fromApi(m['level']),
    );
  }

  final RoleFit role;

  /// The job's skills the user has, the ones that weigh most first.
  final List<String> skills;

  /// Up to 3 skills the job asks for that the user lacks, required ones first.
  final List<String> missing;
  final LevelFit level;
}

/// How well a job fits the user, and why.
@immutable
class Match {
  const Match({required this.percent, this.reasons = const MatchReasons()});

  /// 0..100.
  final int percent;
  final MatchReasons reasons;

  MatchTier get tier => MatchTier.of(percent);
}

/// One job of the matched lists.
@immutable
class MatchedJob {
  const MatchedJob({required this.job, required this.match});

  factory MatchedJob.fromJson(Object? json) {
    final m = json! as Map<String, Object?>;
    return MatchedJob(
      job: Job.fromJson(m),
      match: Match(
        percent: ((m['match_percent'] as num?)?.toInt() ?? 0).clamp(0, 100),
        reasons: MatchReasons.fromJson(m['match_reasons']),
      ),
    );
  }

  final Job job;
  final Match match;
}

/// A page of GET /v1/jobs/matched; [nextCursor] is null on the last one.
@immutable
class MatchedPage {
  const MatchedPage({required this.items, this.nextCursor});

  factory MatchedPage.fromJson(Object? json) {
    final m = json! as Map<String, Object?>;
    final cursor = m['next_cursor'];
    return MatchedPage(
      items: [for (final item in m['items'] as List? ?? const []) MatchedJob.fromJson(item)],
      nextCursor: cursor is String && cursor.isNotEmpty ? cursor : null,
    );
  }

  final List<MatchedJob> items;
  final String? nextCursor;
}
