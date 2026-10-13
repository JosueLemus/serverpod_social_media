import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/app/router/app_routes.dart';
import 'package:nexo_social/app/theme/app_theme.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nexo_social/features/posts/presentation/pages/create_post_page.dart';

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

  Future<GoRouter> pump(WidgetTester tester, String initialLocation) async {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('inicio')),
        GoRoute(path: '/otra', builder: (_, _) => const Text('otra')),
        GoRoute(
          path: AppRoutes.create,
          builder: (_, _) => const CreatePostPage(),
        ),
      ],
    );
    await tester.pumpWidget(
      BlocProvider.value(
        value: sl<AuthCubit>(),
        child: MaterialApp.router(theme: AppTheme.nexo, routerConfig: router),
      ),
    );
    await AppHarness.settle(tester);
    return router;
  }

  // Regresión: abierto por URL (o recargando la pestaña) no hay nada debajo,
  // y `context.pop()` sobre la pila vacía revienta.
  testWidgets('cancelar desde un enlace directo lleva al feed', (tester) async {
    await pump(tester, AppRoutes.create);

    await tester.tap(find.byKey(const Key('composer-close')));
    await AppHarness.settle(tester);

    expect(find.text('inicio'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelar con algo debajo vuelve a donde se estaba', (
    tester,
  ) async {
    final router = await pump(tester, '/otra');
    // El compositor se empuja sobre la pantalla de la que se salió.
    unawaited(router.push(AppRoutes.create));
    await AppHarness.settle(tester);

    await tester.tap(find.byKey(const Key('composer-close')));
    await AppHarness.settle(tester);

    expect(find.text('otra'), findsOneWidget);
  });
}
