import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/app/router/app_router.dart';
import 'package:nexo_social/app/router/app_routes.dart';
import 'package:nexo_social/app/theme/app_theme.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nexo_social/features/feed/presentation/pages/feed_page.dart';
import 'package:nexo_social/features/live/presentation/pages/live_room_page.dart';
import 'package:nexo_social/features/messages/presentation/bloc/unread_messages_cubit.dart';

import '../support/app_harness.dart';

/// Explorar dejó de ser una pestaña: el descubrimiento y la sala del vivo
/// viven en Inicio. Un enlace viejo no puede dar una pantalla en blanco.
void main() {
  setUp(() async {
    await AppHarness.bootstrap(
      initialPreferences: {
        'mock_session':
            '{"id":"user-tomas","username":"tomas","name":"Tomás Ríos","role":"user"}',
      },
    );
    await sl<AuthCubit>().restore();
  });

  Future<GoRouter> pumpAt(WidgetTester tester, String location) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final auth = sl<AuthCubit>();
    final router = createRouter(auth, initialLocation: location);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: auth),
          BlocProvider.value(value: sl<UnreadMessagesCubit>()),
        ],
        child: MaterialApp.router(theme: AppTheme.nexo, routerConfig: router),
      ),
    );
    await AppHarness.settle(tester);
    return router;
  }

  testWidgets('el enlace viejo /explore lleva a Inicio', (tester) async {
    await pumpAt(tester, AppRoutes.legacyExplore);

    expect(find.byType(FeedPage), findsOneWidget);
  });

  testWidgets('el enlace viejo /explore/live/<id> abre la sala nueva', (
    tester,
  ) async {
    final router = await pumpAt(
      tester,
      '${AppRoutes.legacyExplore}/live/live-1',
    );

    expect(find.byType(LiveRoomPage), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.liveRoom('live-1'),
    );
  });

  testWidgets('la sala vive en Inicio: al volver, queda el feed', (
    tester,
  ) async {
    final router = await pumpAt(tester, AppRoutes.liveRoom('live-1'));

    expect(find.byType(LiveRoomPage), findsOneWidget);
    // Debajo de la sala, en la misma pila, está Inicio.
    expect(find.byType(FeedPage, skipOffstage: false), findsOneWidget);

    router.pop();
    await AppHarness.settle(tester);

    expect(find.byType(LiveRoomPage), findsNothing);
    expect(find.byType(FeedPage), findsOneWidget);
  });
}
