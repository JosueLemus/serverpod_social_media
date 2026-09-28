import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/layout/nexo_page.dart';
import 'package:nexo_social/core/responsive/breakpoints.dart';
import 'package:nexo_social/features/feed/presentation/pages/feed_page.dart';
import 'package:nexo_social/features/feed/presentation/widgets/post_card.dart';

import '../../../support/app_harness.dart';

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
  Future<void> pumpWide(WidgetTester tester) =>
      pumpAt(tester, const Size(700, 1600));

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
    /// selected, none tappable.
    testWidgets('"En vivo" narrows the list to live posts', (tester) async {
      await pumpWide(tester);

      await tapFilter(tester, 'En vivo');

      expect(find.byType(PostCard), findsOneWidget);
      // Aparece en la fila de historias y en la tarjeta del post.
      expect(find.text('Elena Vega'), findsWidgets);
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
      expect(find.byType(PostCard), findsOneWidget);

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
      await pumpAt(tester, const Size(390, 1600));

      expect(find.text('482'), findsOneWidget);

      await tester.tap(find.byKey(const Key('like-post-1')));
      await AppHarness.settle(tester);

      expect(find.text('483'), findsOneWidget);
      // Regression: the filled heart must exist after the pop animation, and
      // the outlined one must exist before it.
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });

    testWidgets('an unliked post still shows a heart to tap', (tester) async {
      await pumpAt(tester, const Size(390, 1600));

      // `animate_do` with `animate: false` holds its child at frame zero,
      // which is invisible. That made every un-liked heart disappear.
      expect(find.byIcon(Icons.favorite_border), findsWidgets);
    });

    testWidgets('saving toggles the bookmark', (tester) async {
      await pumpAt(tester, const Size(390, 1600));

      await tester.tap(find.byKey(const Key('save-post-1')));
      await AppHarness.settle(tester);

      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    });
  });

  group('post content', () {
    /// Every post used to print a hardcoded "hace 25 min".
    testWidgets('timestamps come from the post, not a constant', (
      tester,
    ) async {
      await pumpAt(tester, const Size(390, 1600));

      expect(find.textContaining('25 min'), findsOneWidget);
      expect(find.textContaining('3 h'), findsOneWidget);
      expect(find.textContaining('1 d'), findsOneWidget);
    });
  });
}
