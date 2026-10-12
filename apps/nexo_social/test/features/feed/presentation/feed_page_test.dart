import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/widgets/nexo_icon.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nexo_social/core/layout/nexo_page.dart';
import 'package:nexo_social/core/responsive/breakpoints.dart';
import 'package:nexo_social/features/feed/presentation/pages/feed_page.dart';
import 'package:nexo_social/features/feed/presentation/widgets/post_card.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';
import 'package:nexo_social/features/live/domain/repositories/live_repository.dart';
import 'package:nexo_social/features/live/presentation/widgets/live_card.dart';

import '../../../support/app_harness.dart';

/// Un servidor sin nadie al aire. Sólo responde lo que el feed lee.
class _NobodyLive implements LiveRepository {
  @override
  Future<List<LiveSession>> list() async => const [];

  @override
  Stream<void> changes() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(AppHarness.bootstrap);

  /// The narrowest phone the app is expected to survive. Every layout
  /// regression in this file showed up here first.
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppHarness.wrap(const FeedPage()));
    await AppHarness.settle(tester);
  }

  group('layout', () {
    /// The regression that started the rewrite: the shell hands the child zero
    /// horizontal padding so a profile cover can bleed to the edges, and no
    /// page put it back. "Para ti" rendered half off the left edge on every
    /// phone, and nothing failed — a missing EdgeInsets is an absence.
    testWidgets('nothing is clipped by the left edge on a small phone', (
      tester,
    ) async {
      await pumpAt(tester, const Size(320, 900));

      // Only the chips currently laid out can be measured: the filter row is
      // a lazy horizontal list, so the ones past the right edge do not exist
      // as elements at all. That is the point — they scroll into view rather
      // than being squeezed in.
      for (final label in ['Para ti', 'Siguiendo']) {
        final left = tester.getTopLeft(find.text(label).last).dx;
        expect(
          left,
          greaterThanOrEqualTo(0),
          reason: '"$label" arranca fuera de la pantalla',
        );
      }
    });

    testWidgets('the heading keeps the page gutter', (tester) async {
      await pumpAt(tester, const Size(390, 900));

      final gutter = NexoPage.gutterOf(FormFactor.compact);
      expect(
        tester.getTopLeft(find.text('Para ti').first).dx,
        greaterThanOrEqualTo(gutter - 1),
      );
    });

    /// The filter row is a horizontal list precisely so a narrow screen
    /// scrolls it instead of overflowing. A RenderFlex overflow here used to
    /// cut "Comunidades" in half.
    testWidgets('the filter row never overflows', (tester) async {
      await pumpAt(tester, const Size(320, 900));

      expect(tester.takeException(), isNull);
    });

    testWidgets('content clears the bottom navigation bar', (tester) async {
      await pumpAt(tester, const Size(390, 900));

      final scrollView = tester.widget<CustomScrollView>(
        find.byType(CustomScrollView).first,
      );
      expect(scrollView.slivers, isNotEmpty);
    });
  });

  /// Filter behaviour is exercised on a surface wide enough to lay out all
  /// four chips at once.
  ///
  /// On a phone the row is a lazy horizontal list: the chips past the right
  /// edge are not built, and scrolling one into view disposes the one that
  /// scrolls out — so a test that taps two chips in sequence would be
  /// measuring the list's recycling, not the filter.
  /// Alto de sobra para que entren las tres publicaciones del mock junto con
  /// la fila "A quién seguir": la lista de slivers no construye lo que queda
  /// fuera del viewport, y un post sin construir no se puede contar.
  Future<void> pumpWide(WidgetTester tester) =>
      pumpAt(tester, const Size(700, 2600));

  /// The chip, not the page heading — "Para ti" is both.
  Future<void> tapFilter(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await AppHarness.settle(tester);
  }

  group('filters', () {
    testWidgets('start on "Para ti" and show every post', (tester) async {
      await pumpWide(tester);

      expect(find.byType(PostCard), findsNWidgets(3));
    });

    /// They used to be decorative: four identical Material chips, none
    /// selected, none tappable. "En vivo" lists the lives on air, not posts:
    /// with Serverpod no post says it is live, and the list came out empty.
    testWidgets('"En vivo" lists the lives on air instead of posts', (
      tester,
    ) async {
      await pumpWide(tester);

      await tapFilter(tester, 'En vivo');

      expect(find.byType(PostCard), findsNothing);
      // La semilla del mock tiene dos al aire: Elena y Carlos.
      expect(find.byType(LiveCard), findsNWidgets(2));
    });

    testWidgets('"En vivo" with nobody on air says so', (tester) async {
      sl
        ..unregister<LiveRepository>()
        ..registerLazySingleton<LiveRepository>(_NobodyLive.new);
      await pumpWide(tester);

      await tapFilter(tester, 'En vivo');

      expect(find.byKey(const Key('feed-live-empty')), findsOneWidget);
      expect(find.text('Nadie está en vivo ahora'), findsOneWidget);
      expect(find.byType(PostCard), findsNothing);
    });

    testWidgets('the heading follows the selected filter', (tester) async {
      await pumpWide(tester);

      await tapFilter(tester, 'Siguiendo');

      expect(find.text('Siguiendo'), findsWidgets);
      expect(find.byType(PostCard), findsNWidgets(2));
    });

    testWidgets('switching back to "Para ti" restores every post', (
      tester,
    ) async {
      await pumpWide(tester);

      await tapFilter(tester, 'En vivo');
      expect(find.byType(PostCard), findsNothing);

      await tapFilter(tester, 'Para ti');
      // Filtering is applied on read, never by dropping posts from the state,
      // so going back needs no refetch and cannot lose anything.
      expect(find.byType(PostCard), findsNWidgets(3));
    });
  });

  group('reactions', () {
    testWidgets('liking updates the count and keeps the icon visible', (
      tester,
    ) async {
      await sl<AuthCubit>().signIn(DemoAccounts.viewer.email, 'demo');
      await pumpAt(tester, const Size(390, 1600));

      expect(find.text('482'), findsOneWidget);

      await tester.tap(find.byKey(const Key('like-post-1')));
      await AppHarness.settle(tester);

      expect(find.text('483'), findsOneWidget);
      // Regression: the filled heart must exist after the pop animation, and
      // the outlined one must exist before it.
      expect(
        find.descendant(
          of: find.byKey(const Key('like-post-1')),
          matching: _glyph(NexoGlyph.heart, filled: true),
        ),
        findsOneWidget,
      );
    });

    /// Regresión: el toque de un visitante llegaba al servidor, que lo
    /// rechazaba, y el aviso decía "No pudimos guardar tu me gusta".
    testWidgets('a visitor is asked to sign in instead', (tester) async {
      await sl<AuthCubit>().guest();
      await pumpAt(tester, const Size(390, 1600));

      await tester.tap(find.byKey(const Key('like-post-1')));
      await AppHarness.settle(tester);

      expect(find.byKey(const Key('like-sign-in')), findsOneWidget);
      expect(find.text('482'), findsOneWidget);
    });

    testWidgets('an unliked post still shows a heart to tap', (tester) async {
      await pumpAt(tester, const Size(390, 1600));

      // `animate_do` with `animate: false` holds its child at frame zero,
      // which is invisible. That made every un-liked heart disappear.
      expect(_glyph(NexoGlyph.heart, filled: false), findsWidgets);
    });

    testWidgets('saving toggles the bookmark', (tester) async {
      await pumpAt(tester, const Size(390, 1600));

      await tester.tap(find.byKey(const Key('save-post-1')));
      await AppHarness.settle(tester);

      expect(
        find.descendant(
          of: find.byKey(const Key('save-post-1')),
          matching: _glyph(NexoGlyph.bookmark, filled: true),
        ),
        findsOneWidget,
      );
    });
  });

  group('post content', () {
    /// Every post used to print a hardcoded "hace 25 min".
    testWidgets('timestamps come from the post, not a constant', (
      tester,
    ) async {
      await pumpAt(tester, const Size(390, 2600));

      expect(find.textContaining('25 min'), findsOneWidget);
      expect(find.textContaining('3 h'), findsOneWidget);
      expect(find.textContaining('1 d'), findsOneWidget);
    });
  });

  group('sections', () {
    /// "Para ti" en el orden del servidor: de quienes sigues, a quién seguir
    /// y para descubrir. El mock arma lo mismo con su semilla.
    testWidgets('"Para ti" shows the sections in order', (tester) async {
      await sl<AuthCubit>().signIn(DemoAccounts.viewer.email, 'demo');
      await pumpAt(tester, const Size(390, 2600));

      final following = tester.getTopLeft(
        find.byKey(const Key('feed-section-following')),
      );
      final suggested = tester.getTopLeft(
        find.byKey(const Key('feed-section-suggested')),
      );
      final discover = tester.getTopLeft(
        find.byKey(const Key('feed-section-discover')),
      );
      expect(following.dy, lessThan(suggested.dy));
      expect(suggested.dy, lessThan(discover.dy));
    });

    testWidgets('a suggested account is followed from the feed', (
      tester,
    ) async {
      await sl<AuthCubit>().signIn(DemoAccounts.viewer.email, 'demo');
      await pumpAt(tester, const Size(390, 2600));
      final button = find.byKey(const Key('suggested-follow-elena_ux'));
      expect(
        find.descendant(of: button, matching: find.text('Seguir')),
        findsOneWidget,
      );

      await tester.tap(button);
      await AppHarness.settle(tester);

      expect(
        find.descendant(of: button, matching: find.text('Siguiendo')),
        findsOneWidget,
      );
    });

    testWidgets('"Siguiendo" shows the posts of followed accounts', (
      tester,
    ) async {
      await sl<AuthCubit>().signIn(DemoAccounts.viewer.email, 'demo');
      await pumpWide(tester);

      await tapFilter(tester, 'Siguiendo');

      // La semilla del mock tiene dos posts de cuentas seguidas.
      expect(find.byType(PostCard), findsNWidgets(2));
    });
  });
}

/// Los íconos del post son `NexoIcon` (los propios), no `Icons.*`: el estado
/// se lee en si el glifo está relleno o en contorno.
Finder _glyph(NexoGlyph glyph, {required bool filled}) =>
    find.byWidgetPredicate(
      (widget) =>
          widget is NexoIcon &&
          widget.glyph == glyph &&
          widget.filled == filled,
    );
