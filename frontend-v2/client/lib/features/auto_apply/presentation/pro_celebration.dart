import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/providers.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../applications/application/applications_providers.dart';
import '../../applications/data/applications_repository.dart';
import '../../auth/application/auth_providers.dart';

/// The users (ids) already welcomed to Pro on this phone. A user whose plan ends is taken off, so subscribing again
/// is celebrated again.
const proCelebratedKey = 'pro_celebrated_users';

/// The first time the app opens after the user's plan turned Pro (the owner turns it on by hand once paid,
/// backend/billing.py): a celebration, confetti and a welcome. Once per user per phone.
class ProCelebrationHost extends ConsumerStatefulWidget {
  const ProCelebrationHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ProCelebrationHost> createState() => _ProCelebrationHostState();
}

class _ProCelebrationHostState extends ConsumerState<ProCelebrationHost> {
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(autoApplyProvider, (previous, next) {
      if (next case AsyncData(:final value)) _check(value);
    }, fireImmediately: true);
  }

  void _check(AutoApplyState state) {
    final userId = ref.read(currentUserProvider)?.uid;
    if (userId == null) return;
    final prefs = ref.read(preferencesProvider);
    final celebrated = prefs.getStringList(proCelebratedKey) ?? const <String>[];
    if (!state.pro) {
      if (celebrated.contains(userId)) {
        unawaited(prefs.setStringList(proCelebratedKey, [...celebrated]..remove(userId)));
      }
      return;
    }
    if (_showing || celebrated.contains(userId)) return;
    _showing = true;
    // saved before showing: never twice, even if the app is closed while it is on screen
    unawaited(prefs.setStringList(proCelebratedKey, [...celebrated, userId]));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showProCelebration(context);
      _showing = false;
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The welcome to Pro, over the whole app.
Future<void> showProCelebration(BuildContext context) {
  unawaited(HapticFeedback.mediumImpact());
  return showGeneralDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: AppDurations.slow,
    pageBuilder: (dialog, _, _) => const ProCelebration(),
    transitionBuilder: (_, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}

class ProCelebration extends StatefulWidget {
  const ProCelebration({super.key});

  static const confettiFor = Duration(milliseconds: 3200);

  @override
  State<ProCelebration> createState() => _ProCelebrationState();
}

class _ProCelebrationState extends State<ProCelebration> with TickerProviderStateMixin {
  late final AnimationController _confetti = AnimationController(vsync: this, duration: ProCelebration.confettiFor);
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final _pieces = _Confetti.make(90);

  @override
  void initState() {
    super.initState();
    unawaited(_confetti.forward());
    unawaited(_enter.forward());
  }

  @override
  void dispose() {
    _confetti.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final palette = context.palette;
    final confettiColors = [
      colors.primary,
      palette.accent,
      palette.success,
      palette.warning,
      const Color(0xFFFF5C8A),
      const Color(0xFFFFC53D),
    ];
    final badge = CurvedAnimation(parent: _enter, curve: Curves.elasticOut);
    final card = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.page),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: FadeTransition(
                opacity: card,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(card),
                  child: Material(
                    color: colors.surface,
                    borderRadius: AppRadius.xlAll,
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.xxl, AppSpace.xl, AppSpace.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: ScaleTransition(scale: badge, child: const _ProBadge(size: 96)),
                          ),
                          const SizedBox(height: AppSpace.xl),
                          Text(
                            l10n.proWelcomeTitle,
                            textAlign: TextAlign.center,
                            style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppSpace.sm),
                          Text(
                            l10n.proWelcomeBody,
                            textAlign: TextAlign.center,
                            style: context.text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: AppSpace.xl),
                          _Perk(text: l10n.upgradePerkUnlimited),
                          _Perk(text: l10n.upgradePerkAuto),
                          _Perk(text: l10n.upgradePerkLetters),
                          const SizedBox(height: AppSpace.xl),
                          AppButton(
                            label: l10n.proWelcomeButton,
                            icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // over the card, never in the way of the button
        IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _ConfettiPainter(pieces: _pieces, colors: confettiColors, progress: _confetti),
            ),
          ),
        ),
      ],
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.xs + 2),
    child: Row(
      children: [
        Icon(Icons.check_circle_rounded, size: 22, color: context.palette.success),
        const SizedBox(width: AppSpace.md),
        Expanded(child: Text(text, style: context.text.bodyLarge)),
      ],
    ),
  );
}

/// The Pro mark: a crowned medal on the brand gradient, softly glowing.
class _ProBadge extends StatelessWidget {
  const _ProBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, context.palette.accent],
        ),
        boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.4), blurRadius: 28, spreadRadius: 2)],
      ),
      child: Icon(Icons.workspace_premium_rounded, color: colors.onPrimary, size: size * 0.55),
    );
  }
}

/// One piece of confetti: where it starts and how it falls, all as fractions of the screen and the animation.
@immutable
class _Confetti {
  const _Confetti({
    required this.x,
    required this.delay,
    required this.fall,
    required this.sway,
    required this.swaySpeed,
    required this.spin,
    required this.size,
    required this.color,
    required this.round,
  });

  /// The same pieces every time (screenshots and tests stay the same).
  static List<_Confetti> make(int count) {
    final random = math.Random(7);
    return List.generate(
      count,
      (_) => _Confetti(
        x: random.nextDouble(),
        delay: random.nextDouble() * 0.35,
        fall: 0.9 + random.nextDouble() * 0.5,
        sway: 0.02 + random.nextDouble() * 0.05,
        swaySpeed: 1 + random.nextDouble() * 2,
        spin: (random.nextDouble() - 0.5) * 16,
        size: 6 + random.nextDouble() * 6,
        color: random.nextInt(6),
        round: random.nextInt(4) == 0,
      ),
    );
  }

  final double x;
  final double delay;
  final double fall;
  final double sway;
  final double swaySpeed;
  final double spin;
  final double size;
  final int color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.pieces, required this.colors, required this.progress}) : super(repaint: progress);

  final List<_Confetti> pieces;
  final List<Color> colors;
  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return;
    final paint = Paint();
    for (final piece in pieces) {
      final p = ((t - piece.delay) / (1 - piece.delay)).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final y = (-0.05 + p * piece.fall) * size.height;
      final x = (piece.x + math.sin(p * math.pi * 2 * piece.swaySpeed) * piece.sway) * size.width;
      final fade = p > 0.8 ? (1 - p) / 0.2 : 1.0;
      paint.color = colors[piece.color % colors.length].withValues(alpha: fade);
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(p * piece.spin);
      if (piece.round) {
        canvas.drawCircle(Offset.zero, piece.size / 2.4, paint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: piece.size, height: piece.size * 0.5), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.pieces != pieces || old.colors != colors;
}
