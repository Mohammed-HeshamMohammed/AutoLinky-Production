import '../../l10n/gen/app_localizations.dart';

/// How long ago something was posted, in the user's language: "Just now", "5 minutes ago", "3 days ago"...
/// A time ahead of [now] (a phone clock behind the server's) counts as just now.
String timeAgo(AppLocalizations l10n, DateTime at, {DateTime? now}) {
  final age = (now ?? DateTime.now()).difference(at);
  if (age.inMinutes < 1) return l10n.postedJustNow;
  if (age.inHours < 1) return l10n.postedMinutes(age.inMinutes);
  if (age.inDays < 1) return l10n.postedHours(age.inHours);
  if (age.inDays < 7) return l10n.postedDays(age.inDays);
  if (age.inDays < 30) return l10n.postedWeeks(age.inDays ~/ 7);
  return l10n.postedMonths(age.inDays ~/ 30);
}
