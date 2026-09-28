import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/widgets/app_state_views.dart';

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
      // El modo offline no sólo informa: ofrece lo que sí funciona.
      expect(find.text('Modo sin conexión'), findsOneWidget);
      expect(find.textContaining('Lectura disponible offline'), findsOneWidget);
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

      expect(find.byType(Card), findsOneWidget);
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
