import 'package:material_ui/material_ui.dart';

import '../errors/failure_messages.dart';
import '../theme/theme_ext.dart';
import '../theme/tokens.dart';
import 'app_button.dart';

/// Keeps a column of content readable on tablets and the web; phones use the full width.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = AppLayout.contentMaxWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// A friendly "nothing here yet": icon, title, one sentence, an optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// A small label above the title ("Coming soon").
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: ContentWidth(
          maxWidth: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(color: colors.primaryContainer, shape: BoxShape.circle),
                child: Icon(icon, size: 40, color: colors.onPrimaryContainer),
              ),
              const SizedBox(height: AppSpace.xl),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xs),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(badge!, style: context.text.labelSmall?.copyWith(color: colors.onSecondaryContainer)),
                ),
                const SizedBox(height: AppSpace.md),
              ],
              Text(title, style: context.text.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: AppSpace.sm),
              Text(message, style: context.text.bodyMedium, textAlign: TextAlign.center),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpace.xl),
                AppButton(label: actionLabel!, onPressed: onAction, expand: false),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// An error with a retry button, worded for people (failureMessage).
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.cloud_off_rounded,
    title: context.l10n.errorTitle,
    message: failureMessage(context.l10n, error),
    actionLabel: onRetry == null ? null : context.l10n.retry,
    onAction: onRetry,
  );
}

/// Shows an error as a snack bar (nothing for a cancelled action).
void showErrorSnack(BuildContext context, Object error) {
  final message = failureMessage(context.l10n, error);
  if (message.isEmpty) return;
  showInfoSnack(context, message, isError: true);
}

/// A short message at the bottom. [actionLabel] with [onAction]: a button in it ("Undo", "Manage"), shown a little
/// longer, then gone like the others (kept with a screen reader on: reaching the button takes longer).
void showInfoSnack(
  BuildContext context,
  String message, {
  bool isError = false,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final action = actionLabel == null || onAction == null
      ? null
      : SnackBarAction(label: actionLabel, onPressed: onAction);
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      action: action,
      duration: action == null ? const Duration(seconds: 4) : const Duration(seconds: 6),
      persist: action != null && MediaQuery.accessibleNavigationOf(context),
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: isError ? const Color(0xFFFF8A80) : const Color(0xFF3EE0AE),
            size: 20,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

/// A screen's main button, fixed at the bottom. Put it in Scaffold.bottomNavigationBar: snack bars then appear
/// above it instead of covering it.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        // as tall as the button (an Align would take the whole screen in a bottom bar)
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppLayout.contentMaxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.md, AppSpace.page, AppSpace.md),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
