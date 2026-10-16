import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/theme_ext.dart';
import '../../../../core/theme/tokens.dart';

/// "Continue with Google", in Google's own style (the colored G on a neutral button, as its branding asks).
class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onPressed, this.loading = false});

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = colors.brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: dark ? const Color(0xFF131314) : Colors.white,
          foregroundColor: dark ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F),
          disabledBackgroundColor: dark ? const Color(0xFF131314) : Colors.white,
          side: BorderSide(color: dark ? const Color(0xFF8E918F) : const Color(0xFFD0D5E2)),
        ),
        child: AnimatedSwitcher(
          duration: AppDurations.fast,
          child: loading
              ? const SizedBox.square(
                  key: ValueKey('loading'),
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset('assets/brand/google_g.svg', width: 20, height: 20),
                    const SizedBox(width: AppSpace.md),
                    Flexible(child: Text(context.l10n.continueWithGoogle, overflow: TextOverflow.ellipsis)),
                  ],
                ),
        ),
      ),
    );
  }
}
