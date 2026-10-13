import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/features/explore/presentation/bloc/search_cubit.dart';
import 'package:nexo_social/features/explore/presentation/widgets/search_results_view.dart';
import 'package:nexo_social/features/profile/domain/entities/follow.dart';

import '../../../support/app_harness.dart';

void main() {
  setUp(AppHarness.bootstrap);

  testWidgets('a failed search shows the error even with older results', (
    tester,
  ) async {
    final cubit = SearchCubit(sl(), sl());
    addTearDown(cubit.close);
    // Resultados de "ele" que quedaron de antes; la de "elena" falló.
    const state = SearchState(
      text: 'elena',
      status: SearchStatus.failed,
      results: SearchResults(
        query: 'ele',
        accounts: [
          ProfileSummary(id: 'u-1', username: 'elena_ux', name: 'Elena Vega'),
        ],
      ),
    );

    await tester.pumpWidget(
      AppHarness.wrap(
        BlocProvider.value(
          value: cubit,
          child: SingleChildScrollView(
            child: SearchResultsView(
              state: state,
              onTag: (_) {},
              onClear: () {},
            ),
          ),
        ),
      ),
    );
    await AppHarness.settle(tester);

    expect(find.byKey(const Key('search-failed')), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.byKey(const Key('search-results')), findsNothing);
    expect(find.byKey(const Key('search-account-elena_ux')), findsNothing);
  });
}
