import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/core/media/live_media_engine.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nexo_social/features/live/domain/entities/live_comment.dart';
import 'package:nexo_social/features/live/domain/entities/live_media_grant.dart';
import 'package:nexo_social/features/live/domain/entities/live_room_event.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';
import 'package:nexo_social/features/live/domain/repositories/live_repository.dart';
import 'package:nexo_social/features/live/presentation/pages/creator_studio_page.dart';

import '../../../support/app_harness.dart';

/// El servidor de mentira del Studio: devuelve los shows del host y deja que
/// el test empuje eventos de la sala.
class _FakeLiveRepository implements LiveRepository {
  final shows = <LiveSession>[];
  final calls = <String>[];
  var seeded = <LiveComment>[];
  final _rooms = <String, StreamController<LiveRoomEvent>>{};

  StreamController<LiveRoomEvent> room(String id) =>
      _rooms.putIfAbsent(id, StreamController<LiveRoomEvent>.broadcast);

  @override
  Future<List<LiveSession>> mine() async => List.of(shows);

  @override
  Future<List<LiveSession>> list() async => List.of(shows);

  @override
  Future<LiveSession?> byId(String id) async =>
      shows.where((show) => show.id == id).firstOrNull;

  @override
  Stream<LiveRoomEvent> watch(String liveId) async* {
    final show = shows.firstWhere((item) => item.id == liveId);
    yield LiveRoomSnapshot(
      session: show,
      role: LiveRole.host,
      comments: seeded,
    );
    yield* room(liveId).stream;
  }

  @override
  Future<LiveSession> transition(String id, LiveStatus status) async {
    calls.add('transition $id ${status.name}');
    final index = shows.indexWhere((show) => show.id == id);
    final updated = shows[index].copyWith(status: status);
    shows[index] = updated;
    return updated;
  }

  @override
  Future<LiveSession> goLive(String title) async {
    calls.add('goLive $title');
    final created = LiveSession(
      id: 'new-${shows.length}',
      title: title,
      hostName: 'Elena Vega',
      status: LiveStatus.live,
      startedAt: DateTime.now(),
    );
    shows.add(created);
    return created;
  }

  @override
  Future<LiveMediaGrant> mediaToken(String liveId) async => LiveMediaGrant(
    channel: 'nexo_live_$liveId',
    role: LiveMediaGrantRole.publisher,
  );

  @override
  Future<List<LiveComment>> comments(String liveId) async => seeded;

  @override
  Future<LiveComment> postComment(String liveId, String body) async =>
      LiveComment(id: 'mine', author: 'Elena Vega', body: body, isMine: true);

  @override
  Future<void> hideComment(String liveId, String commentId) async {
    calls.add('hide $commentId');
    room(liveId).add(LiveCommentHidden(commentId));
  }

  @override
  Future<LiveRole> roleIn(String liveId) async => LiveRole.host;

  @override
  Stream<void> changes() => const Stream.empty();
}

/// Un motor con cámara "real" que registra lo que se le pide.
class _StudioEngine implements LiveMediaEngine {
  final calls = <String>[];
  LiveMediaIssue? permissionResult;
  final _states = StreamController<LiveMediaState>.broadcast();
  var _muted = false;

  void _emit(LiveMediaState state) {
    if (!_states.isClosed) _states.add(state);
  }

  @override
  bool get isSimulated => false;

  @override
  Stream<LiveMediaState> get states => _states.stream;

  @override
  Future<void> join({
    required String channel,
    required LiveMediaRole role,
    String token = '',
    int uid = 0,
  }) async {
    calls.add('join ${role.name}');
    _emit(LiveMediaState(phase: LiveMediaPhase.connected, micMuted: _muted));
  }

  @override
  Future<void> leave() async {
    calls.add('leave');
    _emit(const LiveMediaState());
  }

  @override
  Future<LiveMediaIssue?> preparePublish() async {
    calls.add('permissions');
    return permissionResult;
  }

  @override
  Future<void> openPermissionSettings() async => calls.add('settings');

  @override
  Future<void> switchCamera() async => calls.add('flip');

  @override
  Future<void> setMicrophoneMuted({required bool muted}) async {
    _muted = muted;
    _emit(LiveMediaState(phase: LiveMediaPhase.connected, micMuted: muted));
  }

  @override
  Widget localView() => const SizedBox.expand(key: Key('camera'));

  @override
  Widget remoteView(String channel, int uid) => const SizedBox.shrink();

  @override
  Future<void> dispose() => _states.close();
}

void main() {
  late _FakeLiveRepository repository;
  late _StudioEngine engine;

  const scheduled = LiveSession(
    id: 'show-1',
    title: 'Masterclass de Diseño Mobile',
    hostName: 'Elena Vega',
    status: LiveStatus.scheduled,
  );

  setUp(() async {
    await AppHarness.bootstrap(
      initialPreferences: {
        'mock_session':
            '{"id":"creator-1","username":"elena_ux","name":"Elena Vega","role":"creator"}',
      },
    );
    await sl<AuthCubit>().restore();
    repository = _FakeLiveRepository();
    engine = _StudioEngine();
    sl
      ..unregister<LiveRepository>()
      ..registerLazySingleton<LiveRepository>(() => repository)
      ..unregister<LiveMediaEngine>()
      ..registerFactory<LiveMediaEngine>(() => engine);
  });

  Future<void> pumpStudio(WidgetTester tester) async {
    // Un teléfono alto: el Studio es una lista, y lo que queda fuera del
    // viewport no se construye.
    tester.view.physicalSize = const Size(390, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppHarness.wrap(const CreatorStudioPage()));
    await AppHarness.settle(tester);
  }

  Future<void> tapControl(WidgetTester tester, String key) async {
    await tester.tap(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(IconButton),
      ),
    );
    await AppHarness.settle(tester);
  }

  testWidgets('sin show propio ofrece transmitir ahora y programar', (
    tester,
  ) async {
    await pumpStudio(tester);

    expect(find.text('Transmitir ahora'), findsOneWidget);
    expect(find.byKey(const Key('studio-schedule')), findsOneWidget);
  });

  testWidgets('sin cámara ni micrófono no sale al aire', (tester) async {
    repository.shows.add(scheduled);
    engine.permissionResult = LiveMediaIssue.permissionDenied;
    await pumpStudio(tester);

    await tester.tap(find.byKey(const Key('studio-start')));
    await AppHarness.settle(tester);

    expect(engine.calls, contains('permissions'));
    expect(repository.calls, isEmpty);
    expect(
      find.text('Necesitamos tu cámara y micrófono para transmitir.'),
      findsOneWidget,
    );
    expect(find.text('Ajustes'), findsNothing);
  });

  testWidgets('con el permiso bloqueado ofrece abrir los ajustes', (
    tester,
  ) async {
    repository.shows.add(scheduled);
    engine.permissionResult = LiveMediaIssue.permissionBlocked;
    await pumpStudio(tester);

    await tester.tap(find.byKey(const Key('studio-start')));
    await AppHarness.settle(tester);
    await tester.tap(find.text('Ajustes'));
    await AppHarness.settle(tester);

    expect(repository.calls, isEmpty);
    expect(engine.calls, contains('settings'));
  });

  testWidgets('con permisos inicia el vivo', (tester) async {
    repository.shows.add(scheduled);
    await pumpStudio(tester);

    await tester.tap(find.byKey(const Key('studio-start')));
    await AppHarness.settle(tester);

    expect(engine.calls.first, 'permissions');
    expect(repository.calls, ['transition show-1 live']);
  });

  testWidgets('el host ve el chat y oculta con pulsación larga', (
    tester,
  ) async {
    repository
      ..shows.add(scheduled.copyWith(status: LiveStatus.live))
      ..seeded = const [
        LiveComment(id: 'c1', author: 'Troll 99', body: 'spam spam'),
      ];
    await pumpStudio(tester);

    expect(
      find.textContaining('spam spam', findRichText: true),
      findsOneWidget,
    );

    await tester.longPress(find.byKey(const Key('chat-c1')));
    await AppHarness.settle(tester);
    await tester.tap(find.text('Ocultar comentario'));
    await AppHarness.settle(tester);

    expect(repository.calls, ['hide c1']);
    expect(find.byKey(const Key('chat-c1')), findsNothing);
  });

  testWidgets('silenciar alterna con activar micrófono', (tester) async {
    repository.shows.add(scheduled.copyWith(status: LiveStatus.live));
    await pumpStudio(tester);

    expect(find.text('Silenciar'), findsOneWidget);
    await tapControl(tester, 'studio-mute');
    expect(find.text('Activar micrófono'), findsOneWidget);

    await tapControl(tester, 'studio-mute');
    expect(find.text('Silenciar'), findsOneWidget);

    await tapControl(tester, 'studio-flip');
    expect(engine.calls, contains('flip'));
  });

  testWidgets('después de finalizar se puede salir con un vivo nuevo', (
    tester,
  ) async {
    repository.shows.add(scheduled.copyWith(status: LiveStatus.live));
    await pumpStudio(tester);

    await tester.tap(find.byKey(const Key('studio-end')));
    await AppHarness.settle(tester);
    await tester.tap(find.byKey(const Key('studio-new-live')));
    await AppHarness.settle(tester);
    await tester.enterText(
      find.byKey(const Key('go-live-title')),
      'Charla de prueba',
    );
    await tester.tap(find.byKey(const Key('go-live-submit')));
    await AppHarness.settle(tester);

    expect(engine.calls, contains('permissions'));
    expect(repository.calls, [
      'transition show-1 recorded',
      'goLive Charla de prueba',
    ]);
    expect(find.byKey(const Key('studio-end')), findsOneWidget);
  });

  testWidgets('sin billing ni solicitudes reales no hay datos inventados', (
    tester,
  ) async {
    repository.shows.add(scheduled.copyWith(status: LiveStatus.live));
    await pumpStudio(tester);

    // Las métricas sin fuente dicen "—" y avisan que son mock.
    expect(
      find.descendant(
        of: find.byKey(const Key('studio-subs')),
        matching: find.text('—'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('studio-donations')),
        matching: find.text('—'),
      ),
      findsOneWidget,
    );
    expect(find.text('Nuevos subs (mock)'), findsOneWidget);
    expect(find.text('+14'), findsNothing);
    expect(find.text(r'$185'), findsNothing);
    // Nadie inventado esperando para unirse.
    expect(find.text('Marcos Dev'), findsNothing);
    expect(find.text('Nadie está esperando aprobación.'), findsOneWidget);
  });

  testWidgets('al aire el host comenta en su propio chat', (tester) async {
    repository.shows.add(scheduled.copyWith(status: LiveStatus.live));
    await pumpStudio(tester);

    await tester.enterText(
      find.byKey(const Key('studio-comment-field')),
      'gracias por venir',
    );
    await tester.tap(find.byKey(const Key('studio-send')));
    await AppHarness.settle(tester);

    expect(
      find.textContaining('gracias por venir', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('antes de salir al aire no hay campo para comentar', (
    tester,
  ) async {
    repository.shows.add(scheduled);
    await pumpStudio(tester);

    expect(find.byKey(const Key('studio-comment-field')), findsNothing);
  });
}
