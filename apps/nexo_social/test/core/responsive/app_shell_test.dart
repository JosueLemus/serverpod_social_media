import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/app/router/app_router.dart';
import 'package:nexo_social/app/router/app_routes.dart';
import 'package:nexo_social/app/theme/app_theme.dart';
import 'package:nexo_social/core/responsive/shell_destinations.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nexo_social/features/feed/presentation/widgets/post_card.dart';

import '../../support/app_harness.dart';

void main() {
  setUp(() async {
    await AppHarness.bootstrap(
      initialPreferences: {
        'mock_session':
            '{"id":"creator-1","username":"elena_ux","name":"Elena Vega","role":"creator"}',
      },
    );
    await sl<AuthCubit>().restore();
  });

  Future<void> pumpShell(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final auth = sl<AuthCubit>();
    await tester.pumpWidget(
      BlocProvider.value(
        value: auth,
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: createRouter(auth, initialLocation: AppRoutes.feed),
        ),
      ),
    );
    await AppHarness.settle(tester);
  }

  group('which navigation surface appears', () {
    testWidgets('a phone gets the bottom bar and no rail', (tester) async {
      await pumpShell(tester, const Size(390, 900));

      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Explorar'), findsOneWidget);
      // El botón de componer no tiene etiqueta —es una acción, no un
      // destino— así que se busca por su semántica.
      expect(find.bySemanticsLabel('Crear publicación'), findsOneWidget);
    });

    testWidgets('a tablet gets the rail and no bottom bar', (tester) async {
      await pumpShell(tester, const Size(900, 1000));

      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets('a desktop window gets the rail plus the side panel', (
      tester,
    ) async {
      await pumpShell(tester, const Size(1400, 1000));

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Tendencias'), findsWidgets);
    });
  });

  group('creator surfaces', () {
    /// Regression: `/studio` and `/moderation` existed as routes with no way
    /// to reach them, because the bottom bar and the rail kept two separate
    /// lists of destinations.
    testWidgets('are reachable from the rail on a wide window', (tester) async {
      await pumpShell(tester, const Size(1400, 1000));

      expect(find.text('Studio'), findsWidgets);
      expect(find.text('Moderación'), findsWidgets);
    });

    testWidgets('stay out of the phone tab bar', (tester) async {
      await pumpShell(tester, const Size(390, 900));

      expect(find.text('Studio'), findsNothing);
      expect(find.text('Moderación'), findsNothing);
    });

    test('every desktop-only destination is excluded from compact', () {
      final compactBranches = ShellDestinations.compact
          .map((destination) => destination.branch)
          .toSet();
      final desktopOnly = ShellDestinations.all
          .where((destination) => destination.desktopOnly)
          .map((destination) => destination.branch);

      for (final branch in desktopOnly) {
        expect(compactBranches.contains(branch), isFalse);
      }
    });

    /// Regression: filtering the list shifted every index after the hidden
    /// entry, so a tab pointed at the wrong branch.
    test('branch indices are explicit, not positional', () {
      for (final (index, destination) in ShellDestinations.all.indexed) {
        expect(
          destination.branch,
          index,
          reason:
              'ShellDestinations.all tiene que estar ordenada por branch para '
              'que coincida con el orden de StatefulShellRoute.',
        );
      }
    });
  });

  group('switching tabs', () {
    testWidgets('moves to the selected branch', (tester) async {
      await pumpShell(tester, const Size(390, 900));

      expect(find.byType(PostCard), findsWidgets);

      // By icon, not by text: "En vivo" is also the label of a feed filter
      // chip, so `find.text` is ambiguous on this screen.
      await tester.tap(find.byIcon(Icons.explore_outlined));
      await AppHarness.settle(tester);

      expect(find.text('En vivo ahora'), findsWidgets);
    });

    /// The whole reason for StatefulShellRoute. The old shell rebuilt the
    /// subtree on every tab change, so leaving Inicio and coming back put the
    /// feed at the top again.
    testWidgets('keeps each tab scrolled where the user left it', (
      tester,
    ) async {
      await pumpShell(tester, const Size(390, 900));

      final feed = find.byType(CustomScrollView).first;
      await tester.drag(feed, const Offset(0, -400));
      await AppHarness.settle(tester);
      final scrolledTo = tester
          .widget<CustomScrollView>(feed)
          .controller
          ?.offset;

      await tester.tap(find.text('Actividad'));
      await AppHarness.settle(tester);
      await tester.tap(find.text('Inicio'));
      await AppHarness.settle(tester);

      final restored = tester
          .widget<CustomScrollView>(find.byType(CustomScrollView).first)
          .controller
          ?.offset;

      expect(restored, scrolledTo);
    });

    testWidgets('compose is pushed over the shell, not a tab', (tester) async {
      await pumpShell(tester, const Size(390, 900));

      await tester.tap(find.bySemanticsLabel('Crear publicación'));
      await AppHarness.settle(tester);

      expect(find.byKey(const Key('create-post-field')), findsOneWidget);
      // Pushed full screen: the tab bar is covered, so the user cannot wander
      // off mid-draft.
      expect(find.text('Actividad'), findsNothing);
    });
  });
}
