import 'package:autolinky/core/widgets/app_logo.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _welcomeBrand({
  bool reducedMotion = false,
  bool ticking = true,
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
}) => MediaQuery(
  data: MediaQueryData(size: const Size(800, 600), disableAnimations: reducedMotion),
  child: Theme(
    data: ThemeData(brightness: brightness),
    child: Localizations(
      locale: locale,
      delegates: const [GlobalWidgetsLocalizations.delegate],
      child: Directionality(
        textDirection: locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: TickerMode(
          enabled: ticking,
          child: const Center(child: AppWordmark(logoSize: 80)),
        ),
      ),
    ),
  ),
);

Finder get _formation => find.descendant(of: find.byType(AppWordmark), matching: find.byType(ClipPath)).first;
Finder get _movingDot => find.byKey(const ValueKey('wordmark-i-dot'));

double _dotOffset(WidgetTester tester) => tester.widget<Transform>(_movingDot).transform.storage[13];

Path _visibleMask(WidgetTester tester) {
  final clip = tester.widget<ClipPath>(_formation);
  return clip.clipper!.getClip(tester.getSize(_formation));
}

/// Sample the public clip geometry, rather than the controller or private state.
List<bool> _coverage(WidgetTester tester) {
  final mask = _visibleMask(tester);
  final size = tester.getSize(_formation);
  return [
    for (var y = 0; y < 16; y++)
      for (var x = 0; x < 83; x++) mask.contains(Offset(size.width * (x + .5) / 83, size.height * (y + .5) / 16)),
  ];
}

void _expectComplete(WidgetTester tester) {
  final size = tester.getSize(_formation);
  final mask = _visibleMask(tester);
  expect(mask.getBounds(), Offset.zero & size);
  expect(_coverage(tester), everyElement(isTrue), reason: 'The final mask must expose the unchanged complete vector.');
}

void main() {
  testWidgets('the A forms before the rest of the word and ends with the complete original outline', (tester) async {
    await tester.pumpWidget(_welcomeBrand());
    expect(_visibleMask(tester).getBounds().isEmpty, isTrue);
    final sizeBefore = tester.getSize(find.byType(AppWordmark));

    await tester.pump(const Duration(milliseconds: 400));
    final drawing = _visibleMask(tester);
    expect(drawing.contains(const Offset(11, 54)), isTrue, reason: 'The first A stroke should already be drawn.');
    expect(drawing.contains(const Offset(374, 70)), isFalse, reason: 'The remaining lettering should follow the A.');
    expect(
      drawing.getBounds().width,
      lessThan(100),
      reason: 'The word must build from its A rather than fade as a whole.',
    );

    await tester.pump(const Duration(seconds: 3));
    _expectComplete(tester);
    expect(
      tester.getSize(find.byType(AppWordmark)),
      sizeBefore,
      reason: 'Formation must never shift the welcome layout.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion exposes the complete wordmark on the first frame', (tester) async {
    await tester.pumpWidget(_welcomeBrand(reducedMotion: true));
    _expectComplete(tester);
    expect(_movingDot, findsNothing);
    await tester.pump(const Duration(seconds: 3));
    _expectComplete(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the i stem forms before its dot drops, touches it, rebounds and settles on the original outline', (
    tester,
  ) async {
    await tester.pumpWidget(_welcomeBrand());
    final originalSize = tester.getSize(find.byType(AppWordmark));
    await tester.pump(const Duration(milliseconds: 1420));
    expect(
      _visibleMask(tester).contains(const Offset(256, 40)),
      isTrue,
      reason: 'The stem must be visible before the dot starts falling.',
    );
    expect(_visibleMask(tester).contains(const Offset(256, 10)), isFalse);
    expect(_movingDot, findsNothing);

    await tester.pump(const Duration(milliseconds: 40));
    expect(_movingDot, findsOneWidget);
    expect(_dotOffset(tester), lessThan(-20), reason: 'The actual dot begins above its final position.');
    final transform = tester.widget<Transform>(_movingDot).transform;
    expect(transform.storage[12], 0, reason: 'The dot stays aligned above its own stem.');
    expect(transform.storage[0], 1);
    expect(transform.storage[5], 1, reason: 'The dot moves rigidly without stretching.');

    await tester.pump(const Duration(milliseconds: 240));
    expect(
      15.979229126 + _dotOffset(tester),
      closeTo(20.086828156, .00001),
      reason: 'The dot must touch the stem, not bounce in empty space.',
    );
    expect(
      _visibleMask(tester).contains(const Offset(256, 10)),
      isFalse,
      reason: 'The original dot stays masked while the moving copy is active.',
    );
    await tester.pump(const Duration(milliseconds: 153));
    expect(_dotOffset(tester), closeTo(-3.2, .001), reason: 'After contact it rebounds above the original position.');
    await tester.pump(const Duration(milliseconds: 137));
    expect(
      15.979229126 + _dotOffset(tester),
      closeTo(20.086828156, .00001),
      reason: 'The second bounce also reaches the actual stem.',
    );
    await tester.pump(const Duration(milliseconds: 75));
    expect(_dotOffset(tester), inExclusiveRange(-1, 0));
    await tester.pump(const Duration(milliseconds: 47));
    expect(_dotOffset(tester), closeTo(0, .00001));
    await tester.pump(const Duration(milliseconds: 23));
    expect(_movingDot, findsNothing);
    _expectComplete(tester);
    expect(tester.getSize(find.byType(AppWordmark)), originalSize);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'the moving dot preserves position through theme, language and ticker changes and stops for reduced motion',
    (tester) async {
      await tester.pumpWidget(_welcomeBrand());
      await tester.pump(const Duration(milliseconds: 1560));
      final before = _dotOffset(tester);
      await tester.pumpWidget(_welcomeBrand(brightness: Brightness.dark, locale: const Locale('ar')));
      expect(_dotOffset(tester), closeTo(before, .00001));
      await tester.pumpWidget(_welcomeBrand(brightness: Brightness.dark, locale: const Locale('ar'), ticking: false));
      await tester.pump(const Duration(seconds: 3));
      expect(_dotOffset(tester), closeTo(before, .00001));
      await tester.pumpWidget(_welcomeBrand(brightness: Brightness.dark, locale: const Locale('ar')));
      await tester.pump(const Duration(milliseconds: 50));
      expect(_dotOffset(tester), greaterThan(before));
      await tester.pumpWidget(_welcomeBrand(reducedMotion: true));
      expect(_movingDot, findsNothing);
      _expectComplete(tester);
      await tester.pumpWidget(_welcomeBrand());
      await tester.pump(const Duration(milliseconds: 100));
      expect(_movingDot, findsNothing);
      _expectComplete(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the A return grows from its lower joint before its free crossbar tip appears', (tester) async {
    await tester.pumpWidget(_welcomeBrand());
    await tester.pump(const Duration(milliseconds: 580));
    expect(_visibleMask(tester).contains(const Offset(49, 46)), isFalse);
    expect(_visibleMask(tester).contains(const Offset(30, 38)), isFalse);

    await tester.pump(const Duration(milliseconds: 40));
    expect(
      _visibleMask(tester).contains(const Offset(49, 46)),
      isTrue,
      reason: 'The return must start at the visible lower leg.',
    );
    expect(
      _visibleMask(tester).contains(const Offset(49, 38)),
      isFalse,
      reason: 'Its wide brush must not expose a floating piece of the parallel bar.',
    );
    expect(_visibleMask(tester).contains(const Offset(30, 38)), isFalse);
    await tester.pump(const Duration(milliseconds: 280));
    expect(_visibleMask(tester).contains(const Offset(49, 38)), isFalse);
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      _visibleMask(tester).contains(const Offset(30, 38)),
      isTrue,
      reason: 'The free bar tip appears only after the outer loop reaches its attachment.',
    );
    await tester.pump(const Duration(seconds: 2));
    _expectComplete(tester);
  });

  testWidgets('the A keeps gaining visible ink across the loop-to-bar join without a hold', (tester) async {
    await tester.pumpWidget(_welcomeBrand());
    await tester.pump(const Duration(milliseconds: 880));
    int visibleA() {
      final mask = _visibleMask(tester);
      return [
        for (var y = 0; y < 80; y++)
          for (var x = 0; x < 76; x++)
            if (mask.contains(Offset(x + .5, y + .5))) true,
      ].length;
    }

    var before = visibleA();
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 35));
      final after = visibleA();
      expect(after, greaterThan(before), reason: 'The A must continue forming through the connected loop/bar handoff.');
      before = after;
    }
    await tester.pump(const Duration(seconds: 2));
    _expectComplete(tester);
  });

  testWidgets('ordinary t and y reveal with the lettering without waiting for a custom return', (tester) async {
    await tester.pumpWidget(_welcomeBrand());
    await tester.pump(const Duration(milliseconds: 1720));
    final mask = _visibleMask(tester);
    expect(mask.contains(const Offset(146, 55)), isTrue);
    expect(mask.contains(const Offset(150, 46)), isTrue, reason: 't has no separately delayed terminal.');
    expect(mask.contains(const Offset(374, 70)), isTrue);
    expect(mask.contains(const Offset(363, 60)), isTrue, reason: 'y has no separately delayed terminal.');
    expect(mask.contains(const Offset(223, 42.5)), isFalse, reason: 'Only the linked L still has a return to draw.');
    await tester.pump(const Duration(seconds: 1));
    _expectComplete(tester);
  });

  testWidgets('the L return begins at its letter body and reaches the free tip last', (tester) async {
    await tester.pumpWidget(_welcomeBrand());
    await tester.pump(const Duration(milliseconds: 1720));
    expect(
      _visibleMask(tester).contains(const Offset(223, 55.5)),
      isTrue,
      reason: 'L begins along its already drawn foot.',
    );
    expect(
      _visibleMask(tester).contains(const Offset(223, 42.5)),
      isFalse,
      reason: 'The floating upper-left terminal must wait for the loop to return.',
    );

    await tester.pump(const Duration(seconds: 1));
    _expectComplete(tester);
  });

  testWidgets('enabling reduced motion during formation completes it and disabling it does not replay', (tester) async {
    await tester.pumpWidget(_welcomeBrand());
    await tester.pump(const Duration(milliseconds: 400));
    expect(_coverage(tester), contains(isFalse));

    await tester.pumpWidget(_welcomeBrand(reducedMotion: true));
    _expectComplete(tester);
    await tester.pumpWidget(_welcomeBrand());
    await tester.pump(const Duration(milliseconds: 100));
    _expectComplete(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing theme and language preserves an in-progress formation', (tester) async {
    await tester.pumpWidget(_welcomeBrand());
    await tester.pump(const Duration(milliseconds: 400));
    final before = _coverage(tester);
    expect(before, contains(isTrue));
    expect(before, contains(isFalse));

    await tester.pumpWidget(_welcomeBrand(brightness: Brightness.dark, locale: const Locale('ar')));
    expect(
      _coverage(tester),
      orderedEquals(before),
      reason: 'Changing brand colors or language must not restart the reveal.',
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      _coverage(tester),
      isNot(orderedEquals(before)),
      reason: 'The existing formation must continue progressing.',
    );
    await tester.pump(const Duration(seconds: 3));
    _expectComplete(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TickerMode pauses the visible drawing and resumes from that geometry', (tester) async {
    await tester.pumpWidget(_welcomeBrand());
    await tester.pump(const Duration(milliseconds: 400));
    final before = _coverage(tester);

    await tester.pumpWidget(_welcomeBrand(ticking: false));
    await tester.pump(const Duration(seconds: 3));
    expect(
      _coverage(tester),
      orderedEquals(before),
      reason: 'An offscreen wordmark must remain paused, not jump to the end.',
    );

    await tester.pumpWidget(_welcomeBrand());
    expect(_coverage(tester), orderedEquals(before), reason: 'Resuming must preserve the visible strokes.');
    await tester.pump(const Duration(milliseconds: 400));
    expect(_coverage(tester), isNot(orderedEquals(before)));
    await tester.pump(const Duration(seconds: 3));
    _expectComplete(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a completed wordmark stays complete through theme, language and ticker changes', (tester) async {
    await tester.pumpWidget(_welcomeBrand());
    await tester.pump(const Duration(seconds: 3));
    _expectComplete(tester);

    await tester.pumpWidget(_welcomeBrand(brightness: Brightness.dark, locale: const Locale('ar'), ticking: false));
    _expectComplete(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(_welcomeBrand());
    await tester.pump(const Duration(milliseconds: 100));
    _expectComplete(tester);
    expect(tester.takeException(), isNull);
  });
}
