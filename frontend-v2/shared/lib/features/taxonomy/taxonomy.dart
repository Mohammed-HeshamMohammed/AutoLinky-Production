import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_providers.dart';

/// The dictionary of fields, roles and skills (GET /v1/taxonomy): names for the slugs the profile stores, and
/// the choices when the user adds a role or a skill.
@immutable
class TaxonomyRole {
  const TaxonomyRole({required this.slug, required this.field, required this.nameEn, required this.nameAr});

  final String slug;
  final String field;
  final String nameEn;
  final String nameAr;

  String name(String languageCode) => languageCode == 'ar' && nameAr.isNotEmpty ? nameAr : nameEn;
}

@immutable
class TaxonomySkill {
  const TaxonomySkill({required this.slug, required this.name, required this.group});

  final String slug;
  final String name;
  final String group;
}

@immutable
class Taxonomy {
  Taxonomy({required List<TaxonomyRole> roles, required List<TaxonomySkill> skills, required this.fieldNames})
    : roles = {for (final r in roles) r.slug: r},
      skills = {for (final s in skills) s.slug: s};

  factory Taxonomy.fromJson(Object? json) {
    final m = json! as Map<String, Object?>;
    List<Map<String, Object?>> list(String key) => (m[key] as List? ?? const []).cast<Map<String, Object?>>();
    return Taxonomy(
      roles: [
        for (final r in list('roles'))
          TaxonomyRole(
            slug: r['slug']! as String,
            field: r['field']! as String,
            nameEn: r['name_en']! as String,
            nameAr: (r['name_ar'] as String?) ?? '',
          ),
      ],
      skills: [
        for (final s in list('skills'))
          TaxonomySkill(slug: s['slug']! as String, name: s['name']! as String, group: s['group']! as String),
      ],
      fieldNames: {
        for (final f in list('fields'))
          f['slug']! as String: (en: f['name_en']! as String, ar: (f['name_ar'] as String?) ?? ''),
      },
    );
  }

  final Map<String, TaxonomyRole> roles;
  final Map<String, TaxonomySkill> skills;
  final Map<String, ({String en, String ar})> fieldNames;

  /// The name to show; an unknown slug (retired from the dictionary) shows as itself, made readable.
  String roleName(String slug, String languageCode) => roles[slug]?.name(languageCode) ?? readable(slug);

  String skillName(String slug) => skills[slug]?.name ?? readable(slug);

  String fieldName(String slug, String languageCode) {
    final f = fieldNames[slug];
    if (f == null) return readable(slug);
    return languageCode == 'ar' && f.ar.isNotEmpty ? f.ar : f.en;
  }

  /// A slug as words (before the dictionary is loaded, or for a slug it no longer has).
  static String readable(String slug) => slug.replaceAll('_', ' ');
}

/// Loaded once per app run (the dictionary changes rarely).
final taxonomyProvider = FutureProvider<Taxonomy>(
  (ref) => ref.watch(apiClientProvider).get('/v1/taxonomy', Taxonomy.fromJson),
);
