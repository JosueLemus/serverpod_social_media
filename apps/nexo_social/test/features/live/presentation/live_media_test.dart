import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/core/media/simulated_live_media_engine.dart';
import 'package:nexo_social/features/live/domain/entities/live_media_grant.dart';
import 'package:nexo_social/features/live/domain/repositories/live_repository.dart';
import 'package:nexo_social/features/live/presentation/bloc/live_media_cubit.dart';
import 'package:nexo_social/features/live/presentation/widgets/live_video_surface.dart';

/// Un motor que registra lo que se le pide y emite lo que el test quiere.
class _FakeEngine implements LiveMediaEngine {
  final calls = <String>[];
  final _states = StreamController<LiveMediaState>.broadcast();

  void emit(LiveMediaState state) => _states.add(state);

  @override
  bool get isSimulated => false;

  @override
  Stream<LiveMediaState> get states => _states.stream;

  String? lastToken;
  int? lastUid;

  @override
  Future<void> join({
    required String channel,
    required LiveMediaRole role,
    String token = '',
    int uid = 0,
  }) async {
    lastToken = token;
    lastUid = uid;
    calls.add('join $channel ${role.name}');
  }

  @override
  Future<void> leave() async => calls.add('leave');

  /// Lo que contesta el "sistema" al pedir cámara y micrófono.
  LiveMediaIssue? permissionResult;

  @override
  Future<LiveMediaIssue?> preparePublish() async {
    calls.add('preparePublish');
    return permissionResult;
  }

  @override
  Future<void> openPermissionSettings() async => calls.add('settings');

  @override
  Future<void> switchCamera() async => calls.add('switchCamera');

  @override
  Future<void> setMicrophoneMuted({required bool muted}) async {
    calls.add('mute $muted');
    emit(LiveMediaState(phase: LiveMediaPhase.connected, micMuted: muted));
  }

  @override
  Widget localView() => const Text('LOCAL', key: Key('local-video'));

  @override
  Widget remoteView(String channel, int uid) =>
      Text('REMOTE $uid', key: const Key('remote-video'));

  @override
  Future<void> dispose() async {
    calls.add('dispose');
    await _states.close();
  }
}

/// La credencial que "emite el servidor". Por defecto deja publicar: la
/// pantalla de audiencia igual entra como audiencia.
class _FakeLives extends Fake implements LiveRepository {
  _FakeLives({
    this.role = LiveMediaGrantRole.publisher,
    this.token = '',
    this.uid = 0,
    this.error,
  });

  final LiveMediaGrantRole role;
  final String token;
  final int uid;
  final Failure? error;

  @override
  Future<LiveMediaGrant> mediaToken(String liveId) async {
    if (error != null) throw error!;
    return LiveMediaGrant(
      channel: LiveMediaCubit.channelFor(liveId),
      role: role,
      token: token,
      uid: uid,
    );
  }
}

void main() {
  group('LiveMediaCubit', () {
    test('one channel per live, with characters Agora accepts', () {
      expect(LiveMediaCubit.channelFor('live-2'), 'nexo_live_live_2');
    });

    test('joining twice the same live joins once', () async {
      final engine = _FakeEngine();
      final cubit = LiveMediaCubit(engine, _FakeLives());

      await cubit.join('live-1', LiveMediaRole.audience);
      await cubit.join('live-1', LiveMediaRole.audience);

      expect(engine.calls, ['join nexo_live_live_1 audience']);
      await cubit.close();
    });

    /// Cerrar la pantalla libera la cámara: un host que cerró el studio no
    /// puede quedar transmitiendo.
    test('closing releases the engine', () async {
      final engine = _FakeEngine();
      final cubit = LiveMediaCubit(engine, _FakeLives());
      await cubit.join('live-1', LiveMediaRole.host);

      await cubit.close();

      expect(engine.calls.last, 'dispose');
    });

    test('permissions are asked before going on air', () async {
      final engine = _FakeEngine()
        ..permissionResult = LiveMediaIssue.permissionBlocked;
      final cubit = LiveMediaCubit(engine, _FakeLives());
      addTearDown(cubit.close);

      expect(await cubit.preparePublish(), LiveMediaIssue.permissionBlocked);
      engine.permissionResult = null;
      expect(await cubit.preparePublish(), isNull);
      expect(engine.calls, ['preparePublish', 'preparePublish']);
    });

    /// El botón refleja lo que confirmó el motor, no lo que se pidió.
    test('toggling the microphone follows the engine', () async {
      final engine = _FakeEngine();
      final cubit = LiveMediaCubit(engine, _FakeLives());
      addTearDown(cubit.close);

      await cubit.toggleMicrophone();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.micMuted, isTrue);

      await cubit.toggleMicrophone();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.micMuted, isFalse);
      expect(engine.calls, ['mute true', 'mute false']);
    });

    test('switching camera goes to the engine', () async {
      final engine = _FakeEngine();
      final cubit = LiveMediaCubit(engine, _FakeLives());
      addTearDown(cubit.close);

      await cubit.switchCamera();
      await cubit.openPermissionSettings();

      expect(engine.calls, ['switchCamera', 'settings']);
    });

    /// Un token firmado para un uid no vale para otro: los dos tienen que
    /// llegar al motor tal como los emitió el servidor.
    test('the server token and uid reach the engine', () async {
      final engine = _FakeEngine();
      final cubit = LiveMediaCubit(
        engine,
        _FakeLives(token: '007abc', uid: 4242),
      );
      addTearDown(cubit.close);

      await cubit.join('12', LiveMediaRole.host);

      expect(engine.calls, ['join nexo_live_12 host']);
      expect(engine.lastToken, '007abc');
      expect(engine.lastUid, 4242);
    });

    /// D9: el cliente nunca decide volverse emisor. Si el servidor dice
    /// "suscriptor", el studio entra a mirar.
    test('a subscriber grant joins as audience even from the studio', () async {
      final engine = _FakeEngine();
      final cubit = LiveMediaCubit(
        engine,
        _FakeLives(role: LiveMediaGrantRole.subscriber),
      );
      addTearDown(cubit.close);

      await cubit.join('12', LiveMediaRole.host);

      expect(engine.calls, ['join nexo_live_12 audience']);
    });

    test(
      'without a token the video fails and the engine is not joined',
      () async {
        final engine = _FakeEngine();
        final cubit = LiveMediaCubit(
          engine,
          _FakeLives(error: const ConflictFailure('not on air')),
        );
        addTearDown(cubit.close);

        await cubit.join('12', LiveMediaRole.host);

        expect(engine.calls, isEmpty);
        expect(cubit.state.phase, LiveMediaPhase.failed);
        expect(cubit.state.issue, LiveMediaIssue.unavailable);
      },
    );
  });

  group('LiveVideoSurface', () {
    Future<void> pump(
      WidgetTester tester,
      LiveMediaCubit cubit,
      LiveMediaRole role,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: LiveVideoSurface(
              role: role,
              fallback: const Text('FALLBACK', key: Key('fallback')),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('without Agora it is the simulated stage', (tester) async {
      final cubit = LiveMediaCubit(SimulatedLiveMediaEngine(), _FakeLives());
      addTearDown(cubit.close);

      await pump(tester, cubit, LiveMediaRole.audience);

      expect(find.byKey(const Key('fallback')), findsOneWidget);
      expect(find.byKey(const Key('live-video-status')), findsNothing);
    });

    testWidgets('the audience waits for the host, then sees the host', (
      tester,
    ) async {
      final engine = _FakeEngine();
      final cubit = LiveMediaCubit(engine, _FakeLives());
      addTearDown(cubit.close);
      await cubit.join('live-1', LiveMediaRole.audience);
      await pump(tester, cubit, LiveMediaRole.audience);

      engine.emit(const LiveMediaState(phase: LiveMediaPhase.connected));
      // El evento llega en una microtarea; el segundo pump lo dibuja.
      await tester.pump();
      await tester.pump();
      expect(find.text('Esperando la señal del host…'), findsOneWidget);

      engine.emit(
        const LiveMediaState(phase: LiveMediaPhase.connected, remoteUids: [42]),
      );
      // El evento llega en una microtarea; el segundo pump lo dibuja.
      await tester.pump();
      await tester.pump();
      expect(find.text('REMOTE 42'), findsOneWidget);
    });

    testWidgets('the host sees its own camera once connected', (tester) async {
      final engine = _FakeEngine();
      final cubit = LiveMediaCubit(engine, _FakeLives());
      addTearDown(cubit.close);
      await pump(tester, cubit, LiveMediaRole.host);

      engine.emit(const LiveMediaState(phase: LiveMediaPhase.connected));
      // El evento llega en una microtarea; el segundo pump lo dibuja.
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('local-video')), findsOneWidget);
    });

    testWidgets('a denied camera says so, and the room keeps working', (
      tester,
    ) async {
      final engine = _FakeEngine();
      final cubit = LiveMediaCubit(engine, _FakeLives());
      addTearDown(cubit.close);
      await pump(tester, cubit, LiveMediaRole.host);

      engine.emit(
        const LiveMediaState(
          phase: LiveMediaPhase.failed,
          issue: LiveMediaIssue.permissionDenied,
        ),
      );
      // El evento llega en una microtarea; el segundo pump lo dibuja.
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('fallback')), findsOneWidget);
      expect(find.textContaining('Sin permiso de cámara'), findsOneWidget);
    });
  });
}
