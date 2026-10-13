import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/app/router/app_routes.dart';
import 'package:nexo_social/app/theme/app_theme.dart';
import 'package:nexo_social/core/media/live_media_engine.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nexo_social/features/live/domain/entities/live_media_grant.dart';
import 'package:nexo_social/features/live/domain/entities/live_room_event.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';
import 'package:nexo_social/features/live/domain/repositories/live_repository.dart';
import 'package:nexo_social/features/live/presentation/pages/live_room_page.dart';
import 'package:nexo_social/features/live/presentation/utils/live_navigation.dart';
import 'package:nexo_social/features/live/presentation/widgets/featured_live_card.dart';

import '../../../support/app_harness.dart';

/// Un vivo visto por quien lo transmite. El host no es audiencia de sí mismo:
/// en la sala abría un segundo motor de video, y al salir cortaba el Studio.
class _HostRepository implements LiveRepository {
  _HostRepository(this.show, {this.role = LiveRole.host});

  final LiveSession show;
  final LiveRole role;

  /// Cuántas salas escuchan ahora: lo que el servidor cuenta como
  /// espectadores.
  int listening = 0;

  @override
  Stream<LiveRoomEvent> watch(String liveId) {
    late final StreamController<LiveRoomEvent> controller;
    controller = StreamController<LiveRoomEvent>(
      onListen: () {
        listening++;
        controller.add(
          LiveRoomSnapshot(session: show, role: role, comments: const []),
        );
      },
      onCancel: () {
        listening--;
      },
    );
    return controller.stream;
  }

  @override
  Future<LiveMediaGrant> mediaToken(String liveId) async => LiveMediaGrant(
    channel: 'nexo_live_$liveId',
    role: LiveMediaGrantRole.publisher,
  );

  @override
  Stream<void> changes() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Cuenta cuántas veces se intentó entrar al canal.
class _CountingEngine implements LiveMediaEngine {
  int joins = 0;
  final _states = StreamController<LiveMediaState>.broadcast();

  @override
  bool get isSimulated => true;

  @override
  Stream<LiveMediaState> get states => _states.stream;

  @override
  Future<void> join({
    required String channel,
    required LiveMediaRole role,
    String token = '',
    int uid = 0,
  }) async => joins++;

  int leaves = 0;

  @override
  Future<void> leave() async => leaves++;

  @override
  Future<void> dispose() => _states.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final elenaLive = LiveSession(
    id: '5',
    title: 'Masterclass',
    hostId: DemoAccounts.elena.id,
    hostName: 'Elena Vega',
    hostUsername: 'elena_ux',
    status: LiveStatus.live,
    startedAt: DateTime(2026, 10, 11, 20),
  );
  final carlosLive = LiveSession(
    id: '6',
    title: 'Flutter en vivo',
    hostId: DemoAccounts.carlos.id,
    hostName: 'Carlos Méndez',
    hostUsername: 'carlos_mendez',
    status: LiveStatus.live,
  );

  late _CountingEngine engine;

  setUp(() async {
    await AppHarness.bootstrap();
    engine = _CountingEngine();
    sl
      ..unregister<LiveMediaEngine>()
      ..registerFactory<LiveMediaEngine>(() => engine);
    await sl<AuthCubit>().signIn(DemoAccounts.elena.email, 'nexo-demo-2026');
  });

  /// Un router mínimo: la sala, el Studio y una página de partida que muestra
  /// [start] con la misma decisión que usan el feed, Explorar y el perfil.
  GoRouter router(String initialLocation, {Widget? start}) => GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(body: start ?? const SizedBox.shrink()),
      ),
      GoRoute(
        path: AppRoutes.studio,
        builder: (_, state) => Scaffold(
          body: Column(
            children: [
              const Text('studio-page'),
              Text(
                'show=${state.uri.queryParameters[AppRoutes.studioShowParam]}',
              ),
            ],
          ),
        ),
      ),
      GoRoute(
        path: '${AppRoutes.explore}/${AppRoutes.liveRoomSegment}',
        builder: (_, state) =>
            LiveRoomPage(liveId: state.pathParameters['liveId']!),
      ),
    ],
  );

  Future<void> pump(WidgetTester tester, GoRouter routerConfig) async {
    await tester.pumpWidget(
      BlocProvider.value(
        value: sl<AuthCubit>(),
        child: MaterialApp.router(
          theme: AppTheme.nexo,
          routerConfig: routerConfig,
        ),
      ),
    );
    await AppHarness.settle(tester);
  }

  Widget featured(LiveSession session) => Builder(
    builder: (context) => FeaturedLiveCard(
      session: session,
      hostUsername: session.hostUsername,
      isOwn: isOwnLive(context, session),
      onJoin: () => openLive(context, session),
    ),
  );

  testWidgets('el host ve "Volver a tu vivo" y vuelve a su Studio', (
    tester,
  ) async {
    await pump(tester, router('/', start: featured(elenaLive)));

    expect(find.text('Volver a tu vivo'), findsOneWidget);
    expect(find.text('Unirme al Live'), findsNothing);

    await tester.tap(find.byKey(const Key('join-featured-live')));
    await AppHarness.settle(tester);
    expect(find.text('studio-page'), findsOneWidget);
    // Al aire va sin `?show=`: reusa el Studio que sigue transmitiendo.
    expect(find.text('show=null'), findsOneWidget);
  });

  testWidgets('un show propio programado abre el Studio sobre ese show', (
    tester,
  ) async {
    final scheduled = LiveSession(
      id: '7',
      title: 'Taller del viernes',
      hostId: DemoAccounts.elena.id,
      hostName: 'Elena Vega',
      hostUsername: 'elena_ux',
      status: LiveStatus.scheduled,
    );
    await pump(
      tester,
      router(
        '/',
        start: Builder(
          builder: (context) => TextButton(
            onPressed: () => openLive(context, scheduled),
            child: const Text('abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await AppHarness.settle(tester);

    expect(find.text('studio-page'), findsOneWidget);
    expect(find.text('show=7'), findsOneWidget);
  });

  testWidgets('el vivo de otro se ofrece para unirse y abre la sala', (
    tester,
  ) async {
    sl
      ..unregister<LiveRepository>()
      ..registerLazySingleton<LiveRepository>(
        () => _HostRepository(carlosLive, role: LiveRole.audience),
      );
    await pump(tester, router('/', start: featured(carlosLive)));

    expect(find.text('Unirme al Live'), findsOneWidget);
    await tester.tap(find.byKey(const Key('join-featured-live')));
    await AppHarness.settle(tester);
    expect(find.text('studio-page'), findsNothing);
    expect(find.byType(LiveRoomPage), findsOneWidget);
  });

  testWidgets('el host que abre su sala va al Studio sin entrar al canal', (
    tester,
  ) async {
    sl
      ..unregister<LiveRepository>()
      ..registerLazySingleton<LiveRepository>(() => _HostRepository(elenaLive));
    await pump(tester, router(AppRoutes.liveRoom(elenaLive.id)));

    expect(find.text('studio-page'), findsOneWidget);
    expect(engine.joins, 0);
  });

  group('con pestañas, como en la app', () {
    /// Explorar y Studio como branches de un `StatefulShellRoute`: el branch
    /// que no se ve queda montado, que es justo lo que dejaba la sala
    /// sonando y contando espectadores.
    GoRouter shell(String initialLocation) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigation) => Scaffold(
            body: navigation,
            bottomNavigationBar: Row(
              children: [
                TextButton(
                  onPressed: () => navigation.goBranch(0),
                  child: const Text('tab-explore'),
                ),
                TextButton(
                  onPressed: () => navigation.goBranch(1),
                  child: const Text('tab-studio'),
                ),
              ],
            ),
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.explore,
                  builder: (_, _) => const Text('explore-root'),
                  routes: [
                    GoRoute(
                      path: AppRoutes.liveRoomSegment,
                      builder: (_, state) =>
                          LiveRoomPage(liveId: state.pathParameters['liveId']!),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.studio,
                  builder: (_, _) => const Text('studio-page'),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    testWidgets('el host que se va al Studio deja de mirar su propia sala', (
      tester,
    ) async {
      final repository = _HostRepository(elenaLive);
      sl
        ..unregister<LiveRepository>()
        ..registerLazySingleton<LiveRepository>(() => repository);
      await pump(tester, shell(AppRoutes.liveRoom(elenaLive.id)));

      expect(find.text('studio-page'), findsOneWidget);
      // La sala sigue montada en Explorar, pero ya no escucha.
      expect(repository.listening, 0);

      await tester.tap(find.text('tab-explore'));
      await AppHarness.settle(tester);
      expect(find.byKey(const Key('live-handed-off')), findsOneWidget);
      expect(repository.listening, 0);
      expect(engine.joins, 0);
    });

    testWidgets('cambiar de pestaña saca a la audiencia y volver la devuelve', (
      tester,
    ) async {
      final repository = _HostRepository(carlosLive, role: LiveRole.audience);
      sl
        ..unregister<LiveRepository>()
        ..registerLazySingleton<LiveRepository>(() => repository);
      await pump(tester, shell(AppRoutes.liveRoom(carlosLive.id)));

      expect(repository.listening, 1);
      expect(engine.joins, 1);

      await tester.tap(find.text('tab-studio'));
      await AppHarness.settle(tester);
      expect(repository.listening, 0, reason: 'no cuenta como espectador');
      expect(engine.leaves, 1, reason: 'el audio no sigue sonando');

      await tester.tap(find.text('tab-explore'));
      await AppHarness.settle(tester);
      expect(repository.listening, 1);
      expect(engine.joins, 2);
    });
  });
}
