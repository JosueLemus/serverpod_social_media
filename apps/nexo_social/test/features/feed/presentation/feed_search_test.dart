import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nexo_social/features/feed/presentation/pages/feed_page.dart';

import '../../../support/app_harness.dart';

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

  /// Inicio: el buscador vive arriba del feed desde que Explorar dejó de ser
  /// una pestaña.
  Future<void> pumpHome(WidgetTester tester, {double width = 390}) async {
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppHarness.wrap(const FeedPage()));
    await AppHarness.settle(tester);
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('feed-search')), text);
    // El debounce, y después la respuesta.
    await tester.pump(const Duration(milliseconds: 350));
    await AppHarness.settle(tester);
  }

  testWidgets('typing shows accounts instead of the feed', (tester) async {
    await pumpHome(tester);
    expect(find.byKey(const Key('search-results')), findsNothing);
    expect(find.byKey(const Key('filter-forYou')), findsOneWidget);

    await type(tester, 'carlos');

    expect(find.byKey(const Key('search-results')), findsOneWidget);
    expect(
      find.byKey(const Key('search-account-carlos_mendez')),
      findsOneWidget,
    );
    // Elena tiene sesión y Carlos no es ella: puede seguirlo desde acá.
    expect(
      find.byKey(const Key('search-follow-carlos_mendez')),
      findsOneWidget,
    );
    // Los resultados reemplazan al feed: no quedan los filtros abajo.
    expect(find.byKey(const Key('filter-forYou')), findsNothing);
  });

  testWidgets('nothing found says so, and clearing brings the feed back', (
    tester,
  ) async {
    await pumpHome(tester);

    await type(tester, 'zzzzqq');
    expect(find.byKey(const Key('search-empty')), findsOneWidget);

    await tester.tap(find.byKey(const Key('feed-search-clear')));
    await AppHarness.settle(tester);
    expect(find.byKey(const Key('search-empty')), findsNothing);
    expect(find.byKey(const Key('search-results')), findsNothing);
    expect(find.byKey(const Key('filter-forYou')), findsOneWidget);
  });

  testWidgets('one letter does not search', (tester) async {
    await pumpHome(tester);

    await type(tester, 'c');

    expect(find.byKey(const Key('search-results')), findsNothing);
    expect(find.byKey(const Key('search-empty')), findsNothing);
  });

  testWidgets('the keyboard stays open while the results come and go', (
    tester,
  ) async {
    await pumpHome(tester);
    final field = find.byKey(const Key('feed-search'));
    EditableTextState editable() => tester.state<EditableTextState>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    );

    await tester.tap(field);
    await tester.pump();
    final mounted = editable();
    expect(mounted.widget.focusNode.hasFocus, isTrue);

    // Por el teclado y no con `tester.enterText`, que vuelve a enfocar el
    // campo antes de escribir y escondería justamente el bug. Pasa por dos
    // letras (aparecen los resultados) y vuelve a una y a nada (se van).
    for (final text in ['c', 'ca', 'car', 'ca', 'c', '']) {
      tester.testTextInput.enterText(text);
      await tester.pump(const Duration(milliseconds: 350));
      await AppHarness.settle(tester);

      expect(editable(), same(mounted), reason: '"$text" remontó el campo');
      expect(mounted.widget.focusNode.hasFocus, isTrue, reason: text);
      expect(FocusManager.instance.primaryFocus, mounted.widget.focusNode);
      expect(tester.testTextInput.isVisible, isTrue, reason: text);
    }
  });

  testWidgets('accents are optional: "rios" finds Tomás Ríos', (tester) async {
    await pumpHome(tester);

    // Sólo el nombre visible ("Ríos") lo tiene: el usuario es `tomas`.
    await type(tester, 'rios');

    expect(find.byKey(const Key('search-account-tomas')), findsOneWidget);
  });

  testWidgets('results do not overflow at 320', (tester) async {
    await pumpHome(tester, width: 320);

    await type(tester, 'elena');

    expect(find.byKey(const Key('search-results')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Inicio also shows what Explore had: upcoming, replays, topics', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 9000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppHarness.wrap(const FeedPage()));
    await AppHarness.settle(tester);

    // El mock trae un vivo programado (live-2) y un replay (live-3).
    expect(find.byKey(const Key('feed-section-upcoming')), findsOneWidget);
    expect(find.byKey(const Key('feed-section-replays')), findsOneWidget);
    expect(find.text('Temas en tendencia'), findsOneWidget);
  });
}
