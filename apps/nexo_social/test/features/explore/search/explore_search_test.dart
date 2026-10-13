import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nexo_social/features/explore/presentation/pages/explore_page.dart';

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

  Future<void> pumpExplore(WidgetTester tester, {double width = 390}) async {
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppHarness.wrap(const ExplorePage()));
    await AppHarness.settle(tester);
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('explore-search')), text);
    // El debounce, y después la respuesta.
    await tester.pump(const Duration(milliseconds: 350));
    await AppHarness.settle(tester);
  }

  testWidgets('typing shows accounts instead of the explore content', (
    tester,
  ) async {
    await pumpExplore(tester);
    expect(find.byKey(const Key('search-results')), findsNothing);

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
  });

  testWidgets('nothing found says so, and clearing goes back to explore', (
    tester,
  ) async {
    await pumpExplore(tester);

    await type(tester, 'zzzzqq');
    expect(find.byKey(const Key('search-empty')), findsOneWidget);

    await tester.tap(find.byKey(const Key('explore-search-clear')));
    await AppHarness.settle(tester);
    expect(find.byKey(const Key('search-empty')), findsNothing);
    expect(find.byKey(const Key('search-results')), findsNothing);
  });

  testWidgets('one letter does not search', (tester) async {
    await pumpExplore(tester);

    await type(tester, 'c');

    expect(find.byKey(const Key('search-results')), findsNothing);
    expect(find.byKey(const Key('search-empty')), findsNothing);
  });

  testWidgets('results do not overflow at 320', (tester) async {
    await pumpExplore(tester, width: 320);

    await type(tester, 'elena');

    expect(find.byKey(const Key('search-results')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
