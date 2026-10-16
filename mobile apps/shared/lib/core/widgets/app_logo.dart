import 'package:material_ui/material_ui.dart';

import '../theme/app_palette.dart';
import '../theme/theme_ext.dart';

/// The Autolinky mark, drawn (sharp at any size, follows the theme): a white "A" chevron with the mint "match"
/// dot on the brand gradient. Same geometry as tool/make_brand.py, which draws the app icon.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Autolinky',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppPalette.light.brandGradient,
            borderRadius: BorderRadius.circular(size * 0.26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2F4FE8).withValues(alpha: 0.18),
                blurRadius: size * 0.3,
                offset: Offset(0, size * 0.06),
              ),
            ],
          ),
          child: const CustomPaint(painter: _MarkPainter()),
        ),
      ),
    );
  }
}

/// The logo next to the name.
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.logoSize = 36, this.color});

  final double logoSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: logoSize),
        SizedBox(width: logoSize * 0.3),
        Text(
          'Autolinky',
          style: context.text.titleLarge?.copyWith(
            fontSize: logoSize * 0.62,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();

  static const _dot = Color(0xFF2DD4A0); // the brand mint, the same in light and dark

  @override
  void paint(Canvas canvas, Size size) {
    // artwork on a 100-unit grid, filling 86% of the tile (as the app icon)
    final unit = size.width * 0.86 / 100;
    final offset = (size.width - 100 * unit) / 2;
    Offset p(double x, double y) => Offset(offset + x * unit, offset + y * unit);
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13 * unit
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final path = Path()
      ..moveTo(p(26, 74).dx, p(26, 74).dy)
      ..lineTo(p(50, 26).dx, p(50, 26).dy)
      ..lineTo(p(74, 74).dx, p(74, 74).dy);
    canvas
      ..drawPath(path, stroke)
      ..drawCircle(p(50, 62), 7.5 * unit, Paint()..color = _dot);
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}
