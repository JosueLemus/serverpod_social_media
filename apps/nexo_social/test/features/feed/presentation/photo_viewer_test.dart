import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/theme/app_theme.dart';
import 'package:nexo_social/features/feed/presentation/widgets/photo_viewer.dart';

/// El visor de fotos: pellizcar hace zoom, el doble toque acerca y aleja, y
/// deslizar sólo cierra sin zoom. Antes, el arrastre vertical que cerraba el
/// visor le ganaba la arena de gestos al pellizco y el zoom no andaba nunca.
void main() {
  /// Avanza cuadro a cuadro: `pumpAndSettle` no sirve si la imagen de red
  /// queda cargando, y un solo `pump` no alcanza para que entre una ruta.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> openViewer(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.nexo,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () =>
                    showPhotoViewer(context, url: 'https://nexo.test/foto.jpg'),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    // La ruta aparece en el segundo cuadro y entra con un fundido.
    await settle(tester);
    expect(find.byType(PhotoViewer), findsOneWidget);
  }

  double scaleOf(WidgetTester tester) => tester
      .widget<InteractiveViewer>(find.byKey(const Key('photo-viewer-zoom')))
      .transformationController!
      .value
      .getMaxScaleOnAxis();

  Future<void> doubleTap(WidgetTester tester, Offset at) async {
    await tester.tapAt(at);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tapAt(at);
    // La animación del zoom dura ~220 ms.
    await settle(tester);
  }

  testWidgets('pellizcar con dos dedos hace zoom', (tester) async {
    await openViewer(tester);
    const center = Offset(200, 400);
    final first = await tester.startGesture(center - const Offset(40, 0));
    final second = await tester.startGesture(center + const Offset(40, 0));
    for (var i = 0; i < 10; i++) {
      await first.moveBy(const Offset(-8, 0));
      await second.moveBy(const Offset(8, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await first.up();
    await second.up();
    await settle(tester);

    expect(scaleOf(tester), greaterThan(1.5));
    // Un pellizco nunca cierra el visor.
    expect(find.byType(PhotoViewer), findsOneWidget);
  });

  // El que fallaba en el teléfono: los dedos se separan en vertical (lo más
  // común al pellizcar una foto), y el arrastre vertical que cierra el visor
  // se quedaba con el gesto antes que el zoom.
  testWidgets('pellizcar en vertical también hace zoom y no cierra', (
    tester,
  ) async {
    await openViewer(tester);
    const center = Offset(200, 400);
    final first = await tester.startGesture(center - const Offset(0, 40));
    await tester.pump(const Duration(milliseconds: 16));
    // El primer dedo ya se mueve antes de que apoye el segundo.
    await first.moveBy(const Offset(0, -12));
    await tester.pump(const Duration(milliseconds: 16));
    final second = await tester.startGesture(center + const Offset(0, 40));
    for (var i = 0; i < 10; i++) {
      await first.moveBy(const Offset(0, -8));
      await second.moveBy(const Offset(0, 8));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await first.up();
    await second.up();
    await settle(tester);

    expect(find.byType(PhotoViewer), findsOneWidget);
    expect(scaleOf(tester), greaterThan(1.5));
  });

  testWidgets('el doble toque acerca y otro doble toque aleja', (tester) async {
    await openViewer(tester);
    expect(scaleOf(tester), closeTo(1, .01));

    await doubleTap(tester, const Offset(200, 400));
    expect(scaleOf(tester), closeTo(PhotoViewer.doubleTapScale, .05));

    await doubleTap(tester, const Offset(200, 400));
    expect(scaleOf(tester), closeTo(1, .01));
  });

  testWidgets('sin zoom, deslizar hacia abajo cierra el visor', (tester) async {
    await openViewer(tester);
    await tester.drag(
      find.byKey(const Key('photo-viewer')),
      const Offset(0, 220),
    );
    await settle(tester);

    expect(find.byType(PhotoViewer), findsNothing);
  });

  testWidgets('con zoom, deslizar mueve la foto y no cierra', (tester) async {
    await openViewer(tester);
    await doubleTap(tester, const Offset(200, 400));
    expect(scaleOf(tester), greaterThan(1.5));

    await tester.drag(
      find.byKey(const Key('photo-viewer')),
      const Offset(0, 220),
    );
    await settle(tester);

    expect(find.byType(PhotoViewer), findsOneWidget);
    expect(scaleOf(tester), greaterThan(1.5));
  });
}
