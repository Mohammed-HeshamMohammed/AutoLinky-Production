import 'package:material_ui/material_ui.dart';

import '../theme/theme_ext.dart';
import '../theme/tokens.dart';

/// Text-led hierarchy shared by the public identity and the mobile workspace.
class EditorialHeading extends StatelessWidget {
  const EditorialHeading({super.key, required this.eyebrow, required this.title, this.description, this.trailing});
  final String eyebrow;
  final String title;
  final String? description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpace.lg, bottom: AppSpace.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: context.text.labelSmall?.copyWith(letterSpacing: 1.2, color: context.colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpace.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(title, style: context.text.headlineLarge)),
            if (trailing != null) ...[const SizedBox(width: AppSpace.md), trailing!],
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: AppSpace.md),
          Text(description!, style: context.text.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant)),
        ],
      ],
    ),
  );
}

class EditorialSectionLabel extends StatelessWidget {
  const EditorialSectionLabel({super.key, required this.number, required this.label});
  final String number;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpace.lg, bottom: AppSpace.md),
    child: Row(
      children: [
        Text(number, style: context.text.labelSmall?.copyWith(color: context.palette.accent)),
        const SizedBox(width: AppSpace.md),
        Expanded(child: Text(label, style: context.text.titleSmall)),
        const SizedBox(width: AppSpace.md),
        SizedBox(width: 28, child: Divider(color: context.colors.outlineVariant)),
      ],
    ),
  );
}
