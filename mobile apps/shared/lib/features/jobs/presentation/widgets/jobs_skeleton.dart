import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/theme_ext.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/states.dart';

/// The shape of the job cards while the first page loads, so the screen does not jump when they arrive.
class JobsSkeleton extends StatelessWidget {
  const JobsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ContentWidth(
      child: ExcludeSemantics(
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.xl, AppSpace.page, AppSpace.xl),
          itemCount: 3,
          itemBuilder: (context, i) => const _CardSkeleton(),
          separatorBuilder: (context, i) => const SizedBox(height: AppSpace.md),
        ),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    final shade = context.colors.surfaceContainerHigh;
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: shade, borderRadius: AppRadius.smAll),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(double.infinity, 16),
                      const SizedBox(height: AppSpace.sm),
                      bar(140, 12),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.xl),
                Container(
                  width: 56,
                  height: 30,
                  decoration: BoxDecoration(color: shade, borderRadius: AppRadius.smAll),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            bar(220, 12),
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                bar(64, 22),
                const SizedBox(width: AppSpace.sm),
                bar(52, 22),
                const SizedBox(width: AppSpace.sm),
                bar(72, 22),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            Row(children: [bar(110, 18), const Spacer(), bar(124, 40)]),
          ],
        ),
      ),
    );
  }
}
