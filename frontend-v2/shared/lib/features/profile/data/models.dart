import 'package:flutter/foundation.dart';

/// Where the user wants to work (PUT /v1/profile search_scope). It filters their matches and tells the collector
/// where to search their job titles (supabase/migrations/step8b_search_scope.sql).
enum SearchScope {
  egypt('egypt'),
  egyptGulf('egypt_gulf'),
  egyptRemote('egypt_remote'),
  egyptGulfRemote('egypt_gulf_remote'),
  remote('remote'),
  worldwide('worldwide');

  const SearchScope(this.api);

  final String api;

  static SearchScope? fromApi(Object? value) => SearchScope.values.where((s) => s.api == value).firstOrNull;
}

/// The job levels of the API, in order.
const jobLevels = ['intern', 'junior', 'mid', 'senior', 'manager'];

List<String> _strings(Object? value) => value is List ? value.whereType<String>().toList() : const [];

DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value)?.toLocal() : null;

/// The profile the matching uses (GET /v1/profile).
@immutable
class Profile {
  const Profile({
    this.headline,
    this.targetRoles = const [],
    this.targetFields = const [],
    this.skills = const [],
    this.extraSkills = const [],
    this.level,
    this.yearsExperience,
    this.countries = const [],
    this.remoteOk = true,
    this.languages = const [],
    this.searchTitles = const [],
    this.searchScope,
    this.updatedAt,
  });

  factory Profile.fromJson(Object? json) {
    final m = json! as Map<String, Object?>;
    return Profile(
      headline: m['headline'] as String?,
      targetRoles: _strings(m['target_roles']),
      targetFields: _strings(m['target_fields']),
      skills: _strings(m['skills']),
      extraSkills: _strings(m['extra_skills']),
      level: m['level'] as String?,
      yearsExperience: (m['years_experience'] as num?)?.toInt(),
      countries: _strings(m['countries']),
      remoteOk: m['remote_ok'] as bool? ?? true,
      languages: _strings(m['languages']),
      searchTitles: _strings(m['search_titles']),
      searchScope: SearchScope.fromApi(m['search_scope']),
      updatedAt: _date(m['updated_at']),
    );
  }

  final String? headline;
  final List<String> targetRoles;
  final List<String> targetFields;
  final List<String> skills;
  final List<String> extraSkills;
  final String? level;
  final int? yearsExperience;
  final List<String> countries;
  final bool remoteOk;
  final List<String> languages;
  final List<String> searchTitles;
  final SearchScope? searchScope;
  final DateTime? updatedAt;

  /// Ready for matching: the user said where to work (older profiles have no scope yet).
  bool get isComplete => searchScope != null;
}

/// The stored CV (GET /v1/cv): never the file or its text.
@immutable
class CvInfo {
  const CvInfo({
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.analysis,
    required this.uploadedAt,
    this.pages,
  });

  factory CvInfo.fromJson(Object? json) {
    final m = json! as Map<String, Object?>;
    return CvInfo(
      fileName: m['file_name']! as String,
      fileType: m['file_type']! as String,
      fileSize: (m['file_size']! as num).toInt(),
      pages: (m['pages'] as num?)?.toInt(),
      analysis: m['analysis']! as String,
      uploadedAt: _date(m['uploaded_at']) ?? DateTime.now(),
    );
  }

  final String fileName;
  final String fileType;
  final int fileSize;
  final int? pages;

  /// "full", or "partial" when the AI could not read it (rules only): the user can ask for another reading.
  final String analysis;
  final DateTime uploadedAt;

  bool get isPartial => analysis == 'partial';
}

/// After an upload or a new reading: the CV, and the profile it filled.
@immutable
class CvResult {
  const CvResult({required this.cv, required this.profile});

  factory CvResult.fromJson(Object? json) {
    final m = json! as Map<String, Object?>;
    return CvResult(cv: CvInfo.fromJson(m['cv']), profile: Profile.fromJson(m['profile']));
  }

  final CvInfo cv;
  final Profile profile;
}

/// Where the collector is with one of the user's job titles: searched at least once, being searched for the first
/// time (a title new to Autolinky: within minutes, ahead of everything), or not searched (switched off).
enum TitleSearchState {
  searched,
  searching,
  skipped;

  static TitleSearchState fromApi(Object? value) =>
      values.where((s) => s.name == value).firstOrNull ?? TitleSearchState.skipped;
}

/// One of the user's job titles, as the collector searches it ("Senior Network Engineer" -> "network engineer").
@immutable
class TitleSearch {
  const TitleSearch({required this.title, required this.state});

  final String title;
  final TitleSearchState state;
}

/// Has the collector searched the user's job titles yet? (GET /v1/profile/search-status)
@immutable
class SearchStatus {
  const SearchStatus({this.titles = const [], this.searching = false});

  factory SearchStatus.fromJson(Object? json) {
    final m = json! as Map<String, Object?>;
    return SearchStatus(
      titles: [
        for (final t in (m['titles'] as List? ?? const []).whereType<Map<String, Object?>>())
          if (t['title'] case final String title)
            TitleSearch(title: title, state: TitleSearchState.fromApi(t['status'])),
      ],
      searching: m['searching'] as bool? ?? false,
    );
  }

  final List<TitleSearch> titles;

  /// Some of the titles are being searched for the first time.
  final bool searching;
}
