import 'dart:async';

import 'package:flutter/widgets.dart';

import 'live_media_engine.dart';

/// Sin proveedor de video. Se une "al instante" y no hay nadie publicando,
/// así que la pantalla dibuja el escenario simulado, que dice que lo es.
class SimulatedLiveMediaEngine implements LiveMediaEngine {
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
  }) async {
    if (!_states.isClosed) {
      _states.add(const LiveMediaState(phase: LiveMediaPhase.connected));
    }
  }

  @override
  Future<void> leave() async {
    if (!_states.isClosed) _states.add(const LiveMediaState());
  }

  @override
  Widget localView() => const SizedBox.shrink();

  @override
  Widget remoteView(String channel, int uid) => const SizedBox.shrink();

  @override
  Future<void> dispose() => _states.close();
}
