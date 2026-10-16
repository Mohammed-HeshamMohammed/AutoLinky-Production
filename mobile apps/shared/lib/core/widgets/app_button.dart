import 'package:material_ui/material_ui.dart';

enum AppButtonVariant { filled, tonal, outlined, text }

/// The app's button: one look per variant (from the theme), full width by default, and a [loading] state that
/// shows a spinner and blocks taps (no double submits).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  /// Before the label: an Icon, or any widget (the Google "G").
  final Widget? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final onTap = loading ? null : onPressed;
    final scheme = Theme.of(context).colorScheme;
    final spinnerColor = switch (variant) {
      AppButtonVariant.filled => scheme.onPrimary,
      AppButtonVariant.tonal => scheme.onSecondaryContainer,
      _ => scheme.primary,
    };
    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: loading
          ? SizedBox.square(
              key: const ValueKey('loading'),
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: spinnerColor),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[icon!, const SizedBox(width: 12)],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );
    final button = switch (variant) {
      AppButtonVariant.filled => FilledButton(onPressed: onTap, child: child),
      AppButtonVariant.tonal => FilledButton.tonal(onPressed: onTap, child: child),
      AppButtonVariant.outlined => OutlinedButton(onPressed: onTap, child: child),
      AppButtonVariant.text => TextButton(onPressed: onTap, child: child),
    };
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: loading ? label : null,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}
