import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/features/live/domain/entities/live_reaction.dart';
import 'package:nexo_social/features/live/presentation/widgets/live_reactions.dart';

import '../../../support/app_harness.dart';

/// Reacciones efímeras (D7 del SDD 0011). Son dos piezas: la hoja —que arma
/// la decisión y no aplica nada— y el overlay —que escucha al bus y hace
/// flotar cada reacción recibida—.
void main() {
  setUp(AppHarness.bootstrap);

  group('la hoja de reacciones', () {
    testWidgets('ofrece las cinco categorías', (tester) async {
      LiveReactionKind? picked;
      await tester.pumpWidget(
        AppHarness.wrap(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showReactionsSheet(
                    context,
                    onPick: (kind) => picked = kind,
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await AppHarness.settle(tester);

      // Las cinco por su clave `react-<name>`.
      for (final kind in LiveReactionKind.values) {
        expect(
          find.byKey(Key('react-${kind.name}')),
          findsOneWidget,
          reason: 'falta la reacción ${kind.name}',
        );
      }

      await tester.tap(find.byKey(const Key('react-fire')));
      await AppHarness.settle(tester);
      expect(picked, LiveReactionKind.fire);
    });
  });

  group('el overlay', () {
    testWidgets(
      'dibuja la reacción que llega al bus y la saca al terminar',
      (tester) async {
        await tester.pumpWidget(
          AppHarness.wrap(
            const Scaffold(
              body: SizedBox.expand(child: LiveReactionsOverlay()),
            ),
          ),
        );
        // Nada flotando al principio.
        expect(find.text('❤️'), findsNothing);

        LiveReactionBus.instance.publish(LiveReactionKind.heart);
        await tester.pump();
        expect(find.text('❤️'), findsOneWidget);

        // La animación dura 1.5s; a los 2s debería haberse quitado del árbol.
        await tester.pump(const Duration(seconds: 2));
        expect(find.text('❤️'), findsNothing);
      },
    );

    testWidgets('se queda por debajo del tope de simultáneas', (tester) async {
      await tester.pumpWidget(
        AppHarness.wrap(
          const Scaffold(
            body: SizedBox.expand(
              child: LiveReactionsOverlay(maxConcurrent: 3),
            ),
          ),
        ),
      );

      // Mandamos cinco: el overlay sólo debería tener tres a la vez (las dos
      // primeras se descartan por el tope).
      for (var i = 0; i < 5; i++) {
        LiveReactionBus.instance.publish(LiveReactionKind.heart);
      }
      await tester.pump();
      expect(find.text('❤️'), findsNWidgets(3));

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('❤️'), findsNothing);
    });
  });
}
