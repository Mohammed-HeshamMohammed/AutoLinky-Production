/// The search a job title stands for: 'Senior Network Engineer (CCNP)' -> 'network engineer'; null if it cannot be a
/// job title. The same rule as title_key() in backend/cv_ai.py and search_title_key() in SQL (what the collector
/// searches): two titles with the same key are one search. test/core/title_key_test.dart checks it on the shared
/// cases of tests/title_key_cases.py.
String? titleKey(String? title) {
  var t = _foldWidth(title ?? '').toLowerCase();
  if (_link.hasMatch(t)) return null;
  t = t.replaceAll(_brackets, ' ');
  t = t.replaceFirst(_tail, '');
  t = t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).join(' ');
  t = t.replaceFirst(_seniority, '');
  t = t.replaceAll(_edges, '');
  if (t.length < 2 || t.length > 60 || t.split(' ').length > 6 || !_letter.hasMatch(t)) return null;
  return t;
}

final _link = RegExp(r'@|https?:|www\.');
final _brackets = RegExp(r'\([^)]*\)|\[[^\]]*\]');
final _tail = RegExp(r'\s+[-–—]\s+.*$|\s*[|:•·].*$');
final _seniority = RegExp(r'^(?:(?:senior|sr|junior|jr|mid-level|mid level|entry-level|entry level)\.?(?:\s+|$))+');
final _edges = RegExp(r'''^[\s,;/\\_*'"-]+|[\s.,;/\\_*'"-]+$''');
final _letter = RegExp(r'[a-zà-ɏ؀-ۿ]');

/// Full-width letters and digits (Ｎｅｔｗｏｒｋ) as plain ones, the part of Unicode NFKC that job titles meet.
String _foldWidth(String s) => String.fromCharCodes(
  s.runes.map(
    (c) => c >= 0xFF01 && c <= 0xFF5E
        ? c - 0xFEE0
        : c == 0x3000
        ? 0x20
        : c,
  ),
);
