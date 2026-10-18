import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/theme_ext.dart';

/// Shared vector identity, also used by web and native launcher assets.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 56});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'AutoLinky',
    image: true,
    child: SvgPicture.asset(
      'assets/brand/logo-${context.colors.brightness == Brightness.dark ? 'dark' : 'light'}.svg',
      width: size,
      height: size,
      excludeFromSemantics: true,
    ),
  );
}

/// The linked A starts the name; the L echoes its returning link.
class AppWordmark extends StatefulWidget {
  const AppWordmark({super.key, this.logoSize = 36, this.color});

  final double logoSize;
  final Color? color;

  @override
  State<AppWordmark> createState() => _AppWordmarkState();
}

class _AppWordmarkState extends State<AppWordmark> with SingleTickerProviderStateMixin {
  late final AnimationController _formation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _formation.value = 1;
    } else if (TickerMode.valuesOf(context).enabled) {
      if (!_formation.isCompleted && !_formation.isAnimating) {
        _formation.forward();
      }
    } else {
      _formation.stop();
    }
  }

  @override
  void dispose() {
    _formation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget artwork() => SvgPicture.asset(
      'assets/brand/logo-full-${context.colors.brightness == Brightness.dark ? 'dark' : 'light'}.svg',
      width: widget.logoSize * 405 / 80,
      height: widget.logoSize,
      excludeFromSemantics: true,
      colorFilter: widget.color == null ? null : ColorFilter.mode(widget.color!, BlendMode.srcIn),
    );
    return Semantics(
      label: 'AutoLinky',
      image: true,
      child: AnimatedBuilder(
        animation: _formation,
        builder: (context, child) => SizedBox(
          width: widget.logoSize * 405 / 80,
          height: widget.logoSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipPath(clipper: _WordmarkFormationClipper(_formation.value), child: child),
              ),
              if (_formation.value >= _WordmarkDotMotion.start && _formation.value < .97)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: _WordmarkDotMotion.opacity(_formation.value),
                      child: Transform.translate(
                        key: const ValueKey('wordmark-i-dot'),
                        offset: Offset(0, _WordmarkDotMotion.offset(_formation.value) * widget.logoSize / 80),
                        child: ClipRect(clipper: const _WordmarkDotClipper(), child: artwork()),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        child: artwork(),
      ),
    );
  }
}

abstract final class _WordmarkDotMotion {
  static const start = .65;
  static const end = .96;
  static const bounds = Rect.fromLTRB(250.780385437, 4.447470551, 262.932015533, 15.979229126);
  static const _keyframes = [
    (0.0, -22.0),
    (.01, -22.0),
    (.38, 4.10759903),
    (.42, 4.10759903),
    (.62, -3.2),
    (.8, 4.10759903),
    (.84, 4.10759903),
    (.93, -.7),
    (1.0, 0.0),
  ];

  static double _relative(double progress) => ((progress - start) / (end - start)).clamp(0.0, 1.0);
  static double opacity(double progress) => (_relative(progress) / .01).clamp(0.0, 1.0);

  static double offset(double progress) {
    final relative = _relative(progress);
    for (var i = 1; i < _keyframes.length; i++) {
      final (begin, from) = _keyframes[i - 1];
      final (finish, to) = _keyframes[i];
      if (relative <= finish) {
        final t = ((relative - begin) / (finish - begin)).clamp(0.0, 1.0);
        final eased = i == 4 || i == 7 ? 1 - (1 - t) * (1 - t) : t * t;
        return from + (to - from) * eased;
      }
    }
    return 0;
  }
}

class _WordmarkDotClipper extends CustomClipper<Rect> {
  const _WordmarkDotClipper();

  @override
  Rect getClip(Size size) {
    const bounds = _WordmarkDotMotion.bounds;
    return Rect.fromLTRB(
      bounds.left * size.width / 405,
      bounds.top * size.height / 80,
      bounds.right * size.width / 405,
      bounds.bottom * size.height / 80,
    );
  }

  @override
  bool shouldReclip(_WordmarkDotClipper oldClipper) => false;
}

/// The exported outline is never deformed. A pen mask builds the A, staggered
/// strokes reveal the lettering, then the L return closes from its foot.
class _WordmarkFormationClipper extends CustomClipper<Path> {
  const _WordmarkFormationClipper(this.progress);
  final double progress;

  double phase(double start, double end) {
    final t = ((progress - start) / (end - start)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  double aPhase(double start, double end) => ((progress - start) / (end - start)).clamp(0.0, 1.0);

  // Exact accent outlines from the canonical 405 × 80 wordmark. Subtracting
  // them from the body masks prevents a brush from exposing a detached tip.
  static final _aAccent =
      (Path()
            ..moveTo(43, 51)
            ..lineTo(73, 51)
            ..cubicTo(82, 51, 88, 57, 88, 64)
            ..cubicTo(88, 71, 82, 76, 74, 76)
            ..cubicTo(68, 76, 64, 73, 62, 69)
            ..lineTo(57, 60)
            ..lineTo(68, 60)
            ..lineTo(71, 66)
            ..cubicTo(72, 69, 74, 69, 76, 68)
            ..cubicTo(79, 67, 80, 64, 79, 62)
            ..cubicTo(78, 60, 76, 59, 73, 59)
            ..lineTo(39, 59)
            ..close())
          .shift(const Offset(-14, -17));
  static final _lAccent =
      (Path()
            ..moveTo(14, 32)
            ..lineTo(24, 32)
            ..cubicTo(31, 32, 36, 36.5, 36, 42)
            ..cubicTo(36, 47.5, 31, 52, 24, 52)
            ..lineTo(14, 52)
            ..lineTo(14, 45)
            ..lineTo(24, 45)
            ..cubicTo(27, 45, 28.5, 44, 28.5, 42)
            ..cubicTo(28.5, 40, 27, 39, 24, 39)
            ..lineTo(14, 39)
            ..close())
          .shift(const Offset(207.765, 7));

  @override
  Path getClip(Size size) {
    if (progress >= .97) return Path()..addRect(Offset.zero & size);
    var path = Path();
    void add(Path outline) => path = Path.combine(PathOperation.union, path, outline);
    var aBody = Path();
    _stroke(aBody, const [Offset(9, 59), Offset(35, 11), Offset(39, 11), Offset(51, 32)], aPhase(.015, .22), 16);
    _stroke(aBody, const [Offset(23, 46), Offset(44, 46), Offset(51, 55), Offset(61, 58)], aPhase(.14, .29), 12);
    if (progress >= .29) aBody = Path()..addRect(const Rect.fromLTRB(0, 0, 76, 80));
    add(Path.combine(PathOperation.difference, aBody, _aAccent));
    final aBar = Path.combine(
      PathOperation.intersect,
      _aAccent,
      Path()..addRect(const Rect.fromLTRB(24, 33, 59, 42.01)),
    );
    final aLoop = Path.combine(PathOperation.difference, _aAccent, aBar);
    final aReturn = Path();
    _stroke(
      aReturn,
      [
        ..._curve(const Offset(49, 46), const Offset(53, 54), const Offset(57, 58), const Offset(64, 55)),
        ..._curve(const Offset(64, 55), const Offset(77, 51), const Offset(72, 38), const Offset(59, 38)).skip(1),
      ],
      aPhase(.27, .44),
      14,
    );
    add(Path.combine(PathOperation.intersect, aReturn, aLoop));
    if (progress >= .44) add(aLoop);
    final aBarBrush = Path();
    _stroke(aBarBrush, const [Offset(59, 38), Offset(25, 38)], aPhase(.42, .52), 14);
    add(Path.combine(PathOperation.intersect, aBarBrush, aBar));
    if (progress >= .52) add(Path()..addRect(const Rect.fromLTRB(0, 0, 76, 80)));

    void letter(double left, double right, double start, {bool down = true}) {
      final amount = phase(start, start + .22);
      if (amount == 0) return;
      final visible = down
          ? Rect.fromLTRB(left, 0, right, 80 * amount)
          : Rect.fromLTRB(left, 80 * (1 - amount), right, 80);
      add(Path.combine(PathOperation.difference, Path()..addRect(visible), _lAccent));
    }

    letter(78, 123, .27);
    letter(123, 154, .31);
    letter(154, 202, .35, down: false);
    letter(203, 245, .39);
    letter(245, 269, .43);
    letter(269, 315, .47, down: false);
    letter(315, 359.5, .51);
    letter(359.5, 405, .55);
    final lReturn = Path();
    _stroke(
      lReturn,
      [
        const Offset(221.765, 55.5),
        const Offset(231.765, 55.5),
        ..._curve(
          const Offset(231.765, 55.5),
          const Offset(242.765, 55.5),
          const Offset(242.765, 42.5),
          const Offset(231.765, 42.5),
        ).skip(1),
        const Offset(221.765, 42.5),
      ],
      phase(.76, .88),
      9,
    );
    add(Path.combine(PathOperation.intersect, lReturn, _lAccent));
    if (progress >= .88) add(_lAccent);
    path = Path.combine(PathOperation.difference, path, Path()..addRect(_WordmarkDotMotion.bounds));
    return path.transform(Matrix4.diagonal3Values(size.width / 405, size.height / 80, 1).storage);
  }

  List<Offset> _curve(Offset start, Offset first, Offset second, Offset end) => [
    for (var i = 0; i <= 12; i++)
      start * ((1 - i / 12) * (1 - i / 12) * (1 - i / 12)) +
          first * (3 * (1 - i / 12) * (1 - i / 12) * i / 12) +
          second * (3 * (1 - i / 12) * i / 12 * i / 12) +
          end * (i / 12 * i / 12 * i / 12),
  ];

  /// Rounded brush segments clip the existing vector without raster animation.
  void _stroke(Path path, List<Offset> points, double amount, double width) {
    if (amount <= 0) return;
    var length = 0.0;
    for (var i = 1; i < points.length; i++) {
      length += (points[i] - points[i - 1]).distance;
    }
    var remaining = length * amount;
    final radius = width / 2;
    for (var i = 1; i < points.length && remaining > 0; i++) {
      final start = points[i - 1];
      final delta = points[i] - start;
      final distance = delta.distance;
      final end = start + delta * (remaining / distance).clamp(0.0, 1.0);
      final normal = Offset(-delta.dy, delta.dx) * (radius / distance);
      path.addPolygon([start - normal, end - normal, end + normal, start + normal], true);
      path.addOval(Rect.fromCircle(center: start, radius: radius));
      path.addOval(Rect.fromCircle(center: end, radius: radius));
      remaining -= distance;
    }
  }

  @override
  bool shouldReclip(_WordmarkFormationClipper oldClipper) => progress != oldClipper.progress;
}
