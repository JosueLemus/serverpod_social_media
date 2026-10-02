import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/media/live_media_engine.dart';

export '../../../../core/media/live_media_engine.dart';

/// El video de una pantalla de vivo: unirse, salir y quién publica.
///
/// Es dueño del motor: cerrar la pantalla sale del canal y libera la cámara.
/// Un vivo que sigue transmitiendo después de que el host cerró el studio es
/// una cámara abierta que nadie ve.
class LiveMediaCubit extends Cubit<LiveMediaState> {
  LiveMediaCubit(this.engine) : super(const LiveMediaState()) {
    _subscription = engine.states.listen(emit);
  }

  final LiveMediaEngine engine;
  late final StreamSubscription<LiveMediaState> _subscription;
  String? _channel;

  /// El canal en el que está la pantalla, para dibujar el video remoto.
  String? get channel => _channel;

  /// Un canal por vivo. Agora acepta letras, números y guion bajo.
  static String channelFor(String liveId) =>
      'nexo_live_${liveId.replaceAll(RegExp('[^A-Za-z0-9_]'), '_')}';

  Future<void> join(String liveId, LiveMediaRole role) async {
    final channel = channelFor(liveId);
    if (_channel == channel && state.phase != LiveMediaPhase.failed) return;
    _channel = channel;
    await engine.join(channel: channel, role: role);
  }

  Future<void> leave() async {
    if (_channel == null) return;
    _channel = null;
    await engine.leave();
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await engine.dispose();
    return super.close();
  }
}
