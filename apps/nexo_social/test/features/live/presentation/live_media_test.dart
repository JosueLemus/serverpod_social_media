import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/media/simulated_live_media_engine.dart';
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

  @override
  Future<void> join({
    required String channel,
    required LiveMediaRole role,
    String token = '',
  }) async => calls.add('join $channel ${role.name}');

  @override
  Future<void> leave() async => calls.add('leave');

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

void main() {
  group('LiveMediaCubit', () {
    test('one channel per live, with characters Agora accepts', () {
      expect(LiveMediaCubit.channelFor('live-2'), 'nexo_live_live_2');
    });

    test('joining twice the same live joins once', () async {
      final engine = _FakeEngine();
      final cubit = LiveMediaCubit(engine);

      await cubit.join('live-1', LiveMediaRole.audience);
      await cubit.join('live-1', LiveMediaRole.audience);

      expect(engine.calls, ['join nexo_live_live_1 audience']);
      await cubit.close();
    });

    /// Cerrar la pantalla libera la cámara: un host que cerró el studio no
    /// puede quedar transmitiendo.
    test('closing releases the engine', () async {
      final engine = _FakeEngine();
      final cubit = LiveMediaCubit(engine);
      await cubit.join('live-1', LiveMediaRole.host);

      await cubit.close();

      expect(engine.calls.last, 'dispose');
    });
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
      final cubit = LiveMediaCubit(SimulatedLiveMediaEngine());
      addTearDown(cubit.close);

      await pump(tester, cubit, LiveMediaRole.audience);

      expect(find.byKey(const Key('fallback')), findsOneWidget);
      expect(find.byKey(const Key('live-video-status')), findsNothing);
    });

    testWidgets('the audience waits for the host, then sees the host', (
      tester,
    ) async {
      final engine = _FakeEngine();
      final cubit = LiveMediaCubit(engine);
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
      final cubit = LiveMediaCubit(engine);
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
      final cubit = LiveMediaCubit(engine);
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
