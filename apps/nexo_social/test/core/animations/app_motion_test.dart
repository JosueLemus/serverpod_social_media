import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/animations/app_motion.dart';

void main() {
  group('Pop', () {
    /// Regression, and the reason `Pop` does not forward `animate:`.
    ///
    /// `animate_do`'s `animate: false` does not mean "render without
    /// animating" — it holds the child at frame zero, which for a scale-and-
    /// fade is fully transparent. Wired the obvious way, every un-liked heart
    /// in the feed vanished and left a bare count with nothing to tap.
    testWidgets('renders its child at full opacity when not triggered', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Pop(trigger: false, child: Icon(Icons.favorite_border)),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((widget) => widget.opacity);
      expect(
        opacities.every((value) => value == 1),
        isTrue,
        reason: 'Un ícono sin animación tiene que ser visible, no invisible.',
      );
    });

    testWidgets('still shows the child once the animation finishes', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Pop(trigger: true, child: Icon(Icons.favorite))),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });

  group('stagger', () {
    test('grows with the index', () {
      expect(AppMotion.staggerFor(0), Duration.zero);
      expect(AppMotion.staggerFor(1), AppMotion.staggerStep);
      expect(AppMotion.staggerFor(3), AppMotion.staggerStep * 3);
    });

    /// Without the cap, item 30 of a feed waits three seconds before it
    /// appears — so a list that is scrolled quickly shows blank cards.
    test('stops compounding past the cap', () {
      final capped = AppMotion.staggerStep * AppMotion.maxStaggerSteps;
      expect(AppMotion.staggerFor(AppMotion.maxStaggerSteps), capped);
      expect(AppMotion.staggerFor(50), capped);
      expect(AppMotion.staggerFor(500), capped);
    });

    test('the cap keeps the longest wait under a second', () {
      expect(
        AppMotion.staggerFor(999).inMilliseconds,
        lessThan(1000),
        reason:
            'Una entrada que tarda más de un segundo deja de leerse como '
            'entrada y se lee como carga.',
      );
    });
  });

  group('EnterStatic', () {
    /// The rule that keeps buttons tappable: a translate animation leaves its
    /// child offset from where it is painted, and hit testing follows the
    /// transform — so taps in that window land on nothing.
    testWidgets('never displaces its child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: EnterStatic(
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Crear cuenta'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 16));
      final atStart = tester.getRect(find.text('Crear cuenta'));
      await tester.pump(const Duration(milliseconds: 500));
      final atEnd = tester.getRect(find.text('Crear cuenta'));

      expect(
        atStart,
        atEnd,
        reason:
            'EnterStatic sólo puede cambiar opacidad. Si se mueve, el hit '
            'test se mueve con él y el botón no responde durante la entrada.',
      );
    });
  });
}
