import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/widgets/app_state_views.dart';
import 'package:nexo_social/core/widgets/offline_view.dart';

void main() {
  group('error view', () {
    testWidgets('exposes a retry action', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppErrorView(onRetry: () => retried = true)),
        ),
      );

      await tester.tap(find.text('Reintentar'));
      expect(retried, isTrue);
    });

    /// Offline is not the same failure as a server error, and the copy says
    /// so — one tells the user their connection is the problem, the other
    /// tells them it is ours.
    testWidgets('distinguishes offline from a server failure', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AppErrorView(onRetry: () {}, isOffline: true),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Sin conexión a Internet'), findsOneWidget);
      expect(find.text('Modo sin conexión'), findsOneWidget);
      // Regresión: listaba dos lecturas "guardadas" de demo con un "Leer
      // ahora" que no abría nada. Sin caché offline no hay qué ofrecer.
      expect(find.textContaining('Lectura disponible offline'), findsNothing);
      expect(find.text('Leer ahora'), findsNothing);
      expect(find.text('Contenido guardado'), findsNothing);
    });
  });

  group('offline view', () {
    Future<void> pump(WidgetTester tester, AppOfflineView view) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: view)),
          ),
        );

    testWidgets('drafts are offered only when they can be opened', (
      tester,
    ) async {
      await pump(tester, AppOfflineView(onRetry: () {}, draftCount: 3));
      expect(find.byKey(const Key('offline-drafts')), findsNothing);

      var opened = false;
      await pump(
        tester,
        AppOfflineView(
          onRetry: () {},
          draftCount: 3,
          onViewDrafts: () => opened = true,
        ),
      );
      await tester.tap(find.byKey(const Key('offline-drafts')));
      expect(opened, isTrue);
    });

    testWidgets('a saved reading offers "Leer ahora" only if it opens', (
      tester,
    ) async {
      var opened = false;
      await pump(
        tester,
        AppOfflineView(
          onRetry: () {},
          savedReadings: [
            const SavedReading(
              title: 'Sin abrir',
              summary: 'Resumen',
              author: 'A',
              minutes: 2,
            ),
            SavedReading(
              title: 'Se abre',
              summary: 'Resumen',
              author: 'B',
              minutes: 3,
              onOpen: () => opened = true,
            ),
          ],
        ),
      );

      expect(find.text('Leer ahora'), findsOneWidget);
      await tester.tap(find.text('Leer ahora'));
      expect(opened, isTrue);
    });
  });

  group('empty view', () {
    testWidgets('always offers the action that resolves it', (tester) async {
      var acted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyView(
              title: 'Nada por aquí',
              message: 'Sigue creadores para llenar este espacio.',
              actionLabel: 'Explorar',
              onAction: () => acted = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Explorar'));
      expect(acted, isTrue);
    });
  });

  group('feed skeleton', () {
    /// It is a Column, not a ListView, because it is rendered as one item
    /// inside the page's sliver list — a nested scrollable there has no
    /// bounded height and throws on layout. The flip side is that it must be
    /// given a scroll parent, which is how it is actually used.
    testWidgets('renders placeholder cards inside a scroll view', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: FeedSkeleton())),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AppSkeleton), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows as many cards as asked for', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: FeedSkeleton(count: 1)),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Un placeholder por post pedido. Ya no es una Card: el post de verdad
      // vive sobre el liner, sin tarjeta, y el placeholder copia su forma.
      expect(find.byKey(const Key('feed-skeleton-item')), findsOneWidget);
    });

    /// A pulse repaints every frame. Without a boundary that repaint walks up
    /// to the nearest ancestor and re-rasterises whatever shares the layer.
    testWidgets('isolates its repaints', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: FeedSkeleton())),
        ),
      );

      expect(find.byType(PulsingSkeleton), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(FadeTransition),
          matching: find.byType(RepaintBoundary),
        ),
        findsWidgets,
        reason:
            'El RepaintBoundary va por ENCIMA del FadeTransition: debajo no '
            'aísla el repintado que la animación programa cada frame.',
      );
    });
  });
}
