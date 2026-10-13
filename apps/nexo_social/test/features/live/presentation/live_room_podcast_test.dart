import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/core/media/live_media_engine.dart';
import 'package:nexo_social/core/media/simulated_live_media_engine.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nexo_social/features/live/domain/entities/live_comment.dart';
import 'package:nexo_social/features/live/domain/entities/live_media_grant.dart';
import 'package:nexo_social/features/live/domain/entities/live_moderation.dart';
import 'package:nexo_social/features/live/domain/entities/live_room_event.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';
import 'package:nexo_social/features/live/domain/entities/live_stage.dart';
import 'package:nexo_social/features/live/domain/repositories/live_repository.dart';
import 'package:nexo_social/features/live/presentation/pages/live_room_page.dart';

import '../../../support/app_harness.dart';

/// Un servidor falso que emite el snapshot que el test arma y recuerda las
/// llamadas de escenario.
///
/// No reusa `StageStubs`: ese mixin **implementa** cada método del escenario
/// como un `async {}`, así que las llamadas no caen en `noSuchMethod` y el
/// contador de `calls` se queda en vacío. Acá queremos ver cada llamada.
class _FakeLiveRepository implements LiveRepository {
  _FakeLiveRepository(this.snapshot);

  LiveRoomSnapshot snapshot;
  final events = StreamController<LiveRoomEvent>.broadcast();
  final calls = <String>[];

  @override
  Stream<LiveRoomEvent> watch(String liveId) async* {
    yield snapshot;
    yield* events.stream;
  }

  @override
  Future<LiveMediaGrant> mediaToken(String liveId) async => LiveMediaGrant(
    channel: 'nexo_live_$liveId',
    role: snapshot.role == LiveRole.audience
        ? LiveMediaGrantRole.subscriber
        : LiveMediaGrantRole.publisher,
  );

  @override
  Stream<void> changes() => const Stream.empty();

  // El contrato pide muchos métodos; sólo nos interesa saber que la View los
  // llamó. `noSuchMethod` nos deja afirmar sobre eso sin stubear cada uno.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString();
    final args = invocation.positionalArguments.join(',');
    calls.add('$name($args)');
    // Un `Future<void>` sirve para todos los métodos que estamos ejerciendo
    // (raiseHand, approveRequest, kick, muteChat, …).
    return Future<void>.value();
  }
}

const _hostId = 'host-elena';
const _guestId = 'guest-ana';
const _handId = 'listener-luz';

LiveSession _onAir() => const LiveSession(
  id: 'live-9',
  title: 'Masterclass',
  hostId: _hostId,
  hostName: 'Elena Vega',
  hostUsername: 'elena_ux',
  status: LiveStatus.live,
  viewers: 2845,
  cohostIds: [_guestId],
);

LiveStage _stage({
  bool meOnStage = false,
  LiveRole meRole = LiveRole.audience,
  bool withHand = true,
}) => LiveStage(
  speakers: [
    const LiveSpeaker(
      userId: _hostId,
      name: 'Elena Vega',
      username: 'elena_ux',
      role: LiveRole.host,
    ),
    const LiveSpeaker(
      userId: _guestId,
      name: 'Ana Mendoza',
      username: 'ana_mendoza',
      role: LiveRole.cohost,
      cameraOn: true,
    ),
    if (meOnStage)
      LiveSpeaker(
        userId: 'me',
        name: 'Soy yo',
        role: meRole,
        isMe: true,
      ),
  ],
  hands: [
    if (withHand)
      LiveHand(
        userId: _handId,
        name: 'Luz Herrera',
        username: 'luz_herrera',
        raisedAt: DateTime(2026, 10, 12, 20, 20),
      ),
  ],
);

LiveRoomSnapshot _snapshot({
  required LiveRole role,
  LiveStage? stage,
  LiveChatMute? myMute,
  LiveSanctionKind? exclusion,
}) => LiveRoomSnapshot(
  session: _onAir(),
  role: role,
  comments: const [
    LiveComment(id: 'c1', authorId: 'u1', author: 'Alguien', body: 'hola'),
    LiveComment(
      id: 'c-troll',
      authorId: 'u-troll',
      author: 'Troll 99',
      body: 'spam spam',
    ),
  ],
  stage: stage ?? _stage(),
  myMute: myMute,
  exclusion: exclusion,
);

Future<void> _pumpRoom(
  WidgetTester tester,
  _FakeLiveRepository repository,
) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  sl
    ..unregister<LiveRepository>()
    ..registerLazySingleton<LiveRepository>(() => repository)
    ..unregister<LiveMediaEngine>()
    ..registerFactory<LiveMediaEngine>(SimulatedLiveMediaEngine.new);
  await tester.pumpWidget(
    AppHarness.wrap(const LiveRoomPage(liveId: 'live-9')),
  );
  await AppHarness.settle(tester);
}

void main() {
  setUp(() async {
    await AppHarness.bootstrap(
      initialPreferences: {
        'mock_session':
            '{"id":"me","username":"soyyo","name":"Soy yo","role":"user"}',
      },
    );
    await sl<AuthCubit>().restore();
  });

  group('la sala por rol', () {
    testWidgets('el oyente puede pedir la palabra, nada más', (tester) async {
      final repo = _FakeLiveRepository(_snapshot(role: LiveRole.audience));
      await _pumpRoom(tester, repo);

      expect(find.byKey(const Key('room-raise-hand')), findsOneWidget);
      // No ve controles de escenario ni cola de pedidos.
      expect(find.byKey(const Key('room-mic')), findsNothing);
      expect(find.byKey(const Key('room-hands')), findsNothing);
      expect(find.byKey(const Key('room-end')), findsNothing);
    });

    testWidgets('el invitado tiene micrófono, cámara y bajarse', (tester) async {
      final repo = _FakeLiveRepository(
        _snapshot(
          role: LiveRole.cohost,
          stage: _stage(meOnStage: true, meRole: LiveRole.cohost),
        ),
      );
      await _pumpRoom(tester, repo);

      expect(find.byKey(const Key('room-mic')), findsOneWidget);
      expect(find.byKey(const Key('room-camera')), findsOneWidget);
      expect(find.byKey(const Key('room-leave-stage')), findsOneWidget);
      // No modera ni termina el vivo.
      expect(find.byKey(const Key('room-hands')), findsNothing);
      expect(find.byKey(const Key('room-end')), findsNothing);
    });

    testWidgets('el moderador ve la cola de pedidos', (tester) async {
      final repo = _FakeLiveRepository(
        _snapshot(
          role: LiveRole.moderator,
          stage: _stage(meOnStage: true, meRole: LiveRole.moderator),
        ),
      );
      await _pumpRoom(tester, repo);

      expect(find.byKey(const Key('room-hands')), findsOneWidget);
      expect(find.text('Pedidos · 1'), findsOneWidget);
      // El moderador no termina el vivo (sólo el host, SDD 0011 §3).
      expect(find.byKey(const Key('room-end')), findsNothing);
    });

    testWidgets('al oyente lo redirecciona el router si llega como host', (
      tester,
    ) async {
      // El rol host ya tiene un listener que lo manda al Studio: lo que acá
      // probamos es que, parado como host, la sala no se dibuja como pantalla
      // de audiencia. Sin router no hay a dónde ir, pero el `isLoading`
      // inicial lo prueba.
      final repo = _FakeLiveRepository(_snapshot(role: LiveRole.audience));
      await _pumpRoom(tester, repo);
      expect(find.byKey(const Key('room-raise-hand')), findsOneWidget);
    });
  });

  // La cola de pedidos la pueden abrir host y moderador. Testeamos con
  // moderador: el host dispara un `context.go(studio)` del router (D1 del
  // SDD 0011) y necesitaría un GoRouter montado; el moderador no, y el flujo
  // de la cola es exactamente el mismo.
  group('la cola de pedidos', () {
    testWidgets('aprobar llama al cubit con el id de quien pidió', (
      tester,
    ) async {
      final repo = _FakeLiveRepository(
        _snapshot(
          role: LiveRole.moderator,
          stage: _stage(meOnStage: true, meRole: LiveRole.moderator),
        ),
      );
      await _pumpRoom(tester, repo);

      await tester.tap(find.byKey(const Key('room-hands')));
      await AppHarness.settle(tester);
      expect(find.byKey(Key('hand-$_handId')), findsOneWidget);

      await tester.tap(find.byKey(Key('approve-$_handId')));
      await AppHarness.settle(tester);
      expect(
        repo.calls.any((c) => c.contains('approveRequest') && c.contains(_handId)),
        isTrue,
      );
    });

    testWidgets('rechazar llama al cubit con el id de quien pidió', (
      tester,
    ) async {
      final repo = _FakeLiveRepository(
        _snapshot(
          role: LiveRole.moderator,
          stage: _stage(meOnStage: true, meRole: LiveRole.moderator),
        ),
      );
      await _pumpRoom(tester, repo);

      await tester.tap(find.byKey(const Key('room-hands')));
      await AppHarness.settle(tester);
      await tester.tap(find.byKey(Key('deny-$_handId')));
      await AppHarness.settle(tester);

      expect(
        repo.calls.any((c) => c.contains('denyRequest') && c.contains(_handId)),
        isTrue,
      );
    });
  });

  // Las acciones del host sobre otros se prueban como moderador por la misma
  // razón que la cola: el host dispara el redirect al Studio y necesita un
  // router. La diferencia que importa (ban: sólo el host) se prueba por el
  // test de contrato de `LivePermissions`, no acá.
  group('la hoja de persona', () {
    testWidgets('el moderador ve silenciar y expulsar sobre un invitado', (
      tester,
    ) async {
      final repo = _FakeLiveRepository(
        _snapshot(
          role: LiveRole.moderator,
          stage: _stage(meOnStage: true, meRole: LiveRole.moderator),
        ),
      );
      await _pumpRoom(tester, repo);

      await tester.longPress(find.byKey(const Key('stage-$_guestId')));
      await AppHarness.settle(tester);

      expect(find.byKey(const Key('person-mute-mic')), findsOneWidget);
      expect(find.byKey(const Key('person-kick')), findsOneWidget);
      // El moderador NO ban-ea ni invita directo al escenario: eso es sólo
      // del host (SDD 0011, §3).
      expect(find.byKey(const Key('person-ban')), findsNothing);
      expect(find.byKey(const Key('person-remove-stage')), findsNothing);
    });

    testWidgets('el oyente no abre acciones sobre otro oyente', (tester) async {
      final repo = _FakeLiveRepository(_snapshot(role: LiveRole.audience));
      await _pumpRoom(tester, repo);

      // Pulsa largo sobre un comentario de otro oyente: la hoja no ofrece
      // ninguna acción salvo "nada que hacer".
      await tester.longPress(find.byKey(const Key('chat-c-troll')));
      await AppHarness.settle(tester);

      expect(find.byKey(const Key('person-mute-mic')), findsNothing);
      expect(find.byKey(const Key('person-kick')), findsNothing);
      expect(
        find.textContaining('No puedes aplicar acciones'),
        findsOneWidget,
      );
    });

    testWidgets('silenciar en el chat devuelve la duración elegida', (
      tester,
    ) async {
      final repo = _FakeLiveRepository(
        _snapshot(
          role: LiveRole.moderator,
          stage: _stage(meOnStage: true, meRole: LiveRole.moderator),
        ),
      );
      await _pumpRoom(tester, repo);

      await tester.longPress(find.byKey(const Key('chat-c-troll')));
      await AppHarness.settle(tester);
      // La hoja de persona abierta sobre un comentario tiene la fila de
      // silenciar en el chat para un moderador.
      expect(find.byKey(const Key('mute-oneHour')), findsOneWidget);
      await tester.tap(find.byKey(const Key('mute-oneHour')));
      await AppHarness.settle(tester);
      // Scrollear hasta "Aplicar": en teléfono alto, la fila entra, pero en
      // un viewport apretado la hoja scrollea.
      await tester.ensureVisible(find.byKey(const Key('person-apply-mute')));
      await AppHarness.settle(tester);
      await tester.tap(find.byKey(const Key('person-apply-mute')));
      await AppHarness.settle(tester);

      expect(
        repo.calls.any((c) => c.contains('muteChat')),
        isTrue,
        reason: 'calls=${repo.calls}',
      );
    });
  });

  group('avisos de sala', () {
    testWidgets('silenciado reemplaza el compositor por el aviso', (
      tester,
    ) async {
      final repo = _FakeLiveRepository(
        _snapshot(
          role: LiveRole.audience,
          myMute: LiveChatMute(
            until: DateTime.now().add(const Duration(minutes: 15)),
          ),
        ),
      );
      await _pumpRoom(tester, repo);

      expect(find.byKey(const Key('room-mute-banner')), findsOneWidget);
      expect(find.byKey(const Key('live-comment-field')), findsNothing);
    });

    testWidgets('expulsado reemplaza toda la sala por el estado vacío', (
      tester,
    ) async {
      final repo = _FakeLiveRepository(
        _snapshot(
          role: LiveRole.audience,
          exclusion: LiveSanctionKind.kick,
        ),
      );
      await _pumpRoom(tester, repo);

      expect(find.byKey(const Key('live-excluded')), findsOneWidget);
      expect(find.text('Te sacaron de este vivo'), findsOneWidget);
    });

    testWidgets('baneado dice que es el host quien bloqueó', (tester) async {
      final repo = _FakeLiveRepository(
        _snapshot(
          role: LiveRole.audience,
          exclusion: LiveSanctionKind.ban,
        ),
      );
      await _pumpRoom(tester, repo);

      expect(find.text('El host te bloqueó de sus vivos'), findsOneWidget);
    });

    testWidgets('subir al escenario anuncia con snackbar', (tester) async {
      final repo = _FakeLiveRepository(_snapshot(role: LiveRole.audience));
      await _pumpRoom(tester, repo);

      // Un snapshot nuevo con el rol de cohost y el escenario con "me".
      repo.events.add(
        _snapshot(
          role: LiveRole.cohost,
          stage: _stage(meOnStage: true, meRole: LiveRole.cohost),
        ),
      );
      await AppHarness.settle(tester);

      expect(
        find.textContaining('Estás en el escenario'),
        findsOneWidget,
      );
    });
  });
}
