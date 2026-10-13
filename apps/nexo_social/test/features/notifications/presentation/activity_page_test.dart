import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/app/router/app_routes.dart';
import 'package:nexo_social/app/theme/app_theme.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nexo_social/features/notifications/presentation/pages/activity_page.dart';

import '../../../support/app_harness.dart';

void main() {
  setUp(AppHarness.bootstrap);

  /// La pantalla dentro de un router mínimo, para ver a dónde lleva tocar.
  Future<void> pumpActivity(WidgetTester tester) async {
    // Alto de sobra: la lista se construye perezosa, y lo que no entra en
    // pantalla no existe para los finders.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: AppRoutes.activity,
      routes: [
        GoRoute(
          path: AppRoutes.activity,
          builder: (context, state) => const Scaffold(body: ActivityPage()),
        ),
        GoRoute(
          path: AppRoutes.userProfilePath,
          builder: (context, state) =>
              Text('perfil de ${state.pathParameters['username']}'),
        ),
        GoRoute(
          path: '/${AppRoutes.liveRoomSegment}',
          builder: (context, state) =>
              Text('sala ${state.pathParameters['liveId']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      BlocProvider.value(
        value: sl<AuthCubit>(),
        child: MaterialApp.router(theme: AppTheme.nexo, routerConfig: router),
      ),
    );
    await AppHarness.settle(tester);
  }

  testWidgets('arma la frase de cada aviso con sus datos', (tester) async {
    await pumpActivity(tester);

    expect(find.text('Comenzó a seguirte'), findsOneWidget);
    expect(
      find.text('Está en vivo: "Masterclass de Diseño Mobile"'),
      findsOneWidget,
    );
    // Un aviso del sistema no tiene actor: lo firma la marca.
    expect(find.text('Nexo'), findsOneWidget);
  });

  testWidgets('tocar un aviso lo marca leído', (tester) async {
    await pumpActivity(tester);
    expect(find.byKey(const Key('activity-unread-2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('activity-2')));
    await AppHarness.settle(tester);

    expect(find.byKey(const Key('activity-unread-2')), findsNothing);
  });

  testWidgets('"Marcar leídas" apaga todos los puntos', (tester) async {
    await pumpActivity(tester);

    await tester.tap(find.byKey(const Key('activity-mark-all')));
    await AppHarness.settle(tester);

    expect(find.byKey(const Key('activity-mark-all')), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'activity-unread-',
            ),
      ),
      findsNothing,
    );
  });

  testWidgets('un seguidor nuevo lleva a su perfil', (tester) async {
    await pumpActivity(tester);

    await tester.tap(find.byKey(const Key('activity-action-4')));
    await AppHarness.settle(tester);

    expect(find.text('perfil de tomas'), findsOneWidget);
  });

  testWidgets('un vivo lleva a la sala', (tester) async {
    await pumpActivity(tester);

    await tester.tap(find.byKey(const Key('activity-action-1')));
    await AppHarness.settle(tester);

    expect(find.text('sala live-1'), findsOneWidget);
  });

  testWidgets('un filtro sin avisos lo dice y ofrece volver', (tester) async {
    await pumpActivity(tester);

    final chip = find.byKey(const Key('activity-filter-showSoon'));
    await tester.scrollUntilVisible(
      chip,
      120,
      scrollable: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.right,
      ),
    );
    await tester.tap(chip);
    await AppHarness.settle(tester);

    expect(find.text('Nada por aquí'), findsOneWidget);
  });
}
