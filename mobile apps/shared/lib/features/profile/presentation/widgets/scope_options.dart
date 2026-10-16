import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/theme_ext.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/models.dart';

IconData scopeIcon(SearchScope scope) => switch (scope) {
  SearchScope.egypt => Icons.location_on_outlined,
  SearchScope.egyptGulf => Icons.map_outlined,
  SearchScope.egyptRemote => Icons.home_work_outlined,
  SearchScope.egyptGulfRemote => Icons.travel_explore_rounded,
  SearchScope.remote => Icons.laptop_chromebook_outlined,
  SearchScope.worldwide => Icons.public_rounded,
};

String scopeTitle(AppLocalizations l10n, SearchScope scope) => switch (scope) {
  SearchScope.egypt => l10n.scopeEgypt,
  SearchScope.egyptGulf => l10n.scopeEgyptGulf,
  SearchScope.egyptRemote => l10n.scopeEgyptRemote,
  SearchScope.egyptGulfRemote => l10n.scopeEgyptGulfRemote,
  SearchScope.remote => l10n.scopeRemote,
  SearchScope.worldwide => l10n.scopeWorldwide,
};

String scopeBody(AppLocalizations l10n, SearchScope scope) => switch (scope) {
  SearchScope.egypt => l10n.scopeEgyptBody,
  SearchScope.egyptGulf => l10n.scopeEgyptGulfBody,
  SearchScope.egyptRemote => l10n.scopeEgyptRemoteBody,
  SearchScope.egyptGulfRemote => l10n.scopeEgyptGulfRemoteBody,
  SearchScope.remote => l10n.scopeRemoteBody,
  SearchScope.worldwide => l10n.scopeWorldwideBody,
};

/// The "where do you want to work" choices as big tappable cards (one selected).
class ScopeOptions extends StatelessWidget {
  const ScopeOptions({super.key, required this.selected, required this.onChanged});

  final SearchScope? selected;
  final ValueChanged<SearchScope> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final scope in SearchScope.values) ...[
          _ScopeCard(scope: scope, selected: scope == selected, onTap: () => onChanged(scope)),
          const SizedBox(height: AppSpace.md),
        ],
      ],
    );
  }
}

class _ScopeCard extends StatelessWidget {
  const _ScopeCard({required this.scope, required this.selected, required this.onTap});

  final SearchScope scope;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Semantics(
      selected: selected,
      button: true,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? colors.primaryContainer.withValues(alpha: 0.55) : context.theme.cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: selected ? colors.primary : context.palette.cardBorder, width: selected ? 1.6 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: AppDurations.fast,
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: selected ? colors.primary : colors.surfaceContainerHigh,
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Icon(scopeIcon(scope), color: selected ? colors.onPrimary : colors.onSurfaceVariant),
                ),
                const SizedBox(width: AppSpace.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(scopeTitle(l10n, scope), style: context.text.titleSmall),
                      const SizedBox(height: AppSpace.xxs),
                      Text(scopeBody(l10n, scope), style: context.text.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                AnimatedSwitcher(
                  duration: AppDurations.fast,
                  child: selected
                      ? Icon(Icons.check_circle_rounded, key: const ValueKey('on'), color: colors.primary)
                      : Icon(Icons.circle_outlined, key: const ValueKey('off'), color: colors.outline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Changing where to work from the profile: the same choices in a bottom sheet. Null when dismissed.
Future<SearchScope?> showScopeSheet(BuildContext context, SearchScope? current) {
  return showModalBottomSheet<SearchScope>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.scopeTitle, style: context.text.titleLarge),
            const SizedBox(height: AppSpace.lg),
            ScopeOptions(selected: current, onChanged: (scope) => Navigator.pop(context, scope)),
          ],
        ),
      ),
    ),
  );
}
