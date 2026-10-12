import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/media/live_media_engine.dart';
import '../../domain/entities/live_media_grant.dart';
import '../../domain/repositories/live_repository.dart';

export '../../../../core/media/live_media_engine.dart';

/// El video de una pantalla de vivo: unirse, salir y quién publica.
///
/// Es dueño del motor: cerrar la pantalla sale del canal y libera la cámara.
/// Un vivo que sigue transmitiendo después de que el host cerró el studio es
/// una cámara abierta que nadie ve.
class LiveMediaCubit extends Cubit<LiveMediaState> {
  LiveMediaCubit(this.engine, this._repository)
    : super(const LiveMediaState()) {
    _subscription = engine.states.listen(emit);
  }

  final LiveMediaEngine engine;

  /// De donde sale la credencial del canal: el token y el rol los emite el
  /// servidor.
  final LiveRepository _repository;
  late final StreamSubscription<LiveMediaState> _subscription;
  String? _channel;

  /// El canal en el que está la pantalla, para dibujar el video remoto.
  String? get channel => _channel;

  /// Un canal por vivo. Agora acepta letras, números y guion bajo.
  static String channelFor(String liveId) =>
      'nexo_live_${liveId.replaceAll(RegExp('[^A-Za-z0-9_]'), '_')}';

  /// Entra al canal de [liveId] con la credencial que emite el servidor.
  ///
  /// [role] es lo que la pantalla quiere; manda el servidor. Si no la deja
  /// publicar, entra como audiencia: el cliente nunca decide volverse
  /// emisor (D9 del SDD 0004).
  Future<void> join(String liveId, LiveMediaRole role) async {
    final channel = channelFor(liveId);
    if (_channel == channel && state.phase != LiveMediaPhase.failed) return;
    _channel = channel;
    emit(const LiveMediaState(phase: LiveMediaPhase.joining));

    final LiveMediaGrant grant;
    try {
      grant = await _repository.mediaToken(liveId);
    } on Failure {
      if (isClosed || _channel != channel) return;
      emit(
        const LiveMediaState(
          phase: LiveMediaPhase.failed,
          issue: LiveMediaIssue.unavailable,
        ),
      );
      return;
    }
    // Se salió (o cambió de vivo) mientras llegaba el token.
    if (isClosed || _channel != channel) return;

    _channel = grant.channel;
    await engine.join(
      channel: grant.channel,
      role: role == LiveMediaRole.host && grant.isPublisher
          ? LiveMediaRole.host
          : LiveMediaRole.audience,
      token: grant.token,
      uid: grant.uid,
    );
  }

  Future<void> leave() async {
    if (_channel == null) return;
    _channel = null;
    await engine.leave();
  }

  /// Cámara y micrófono antes de salir al aire. `null` si se puede
  /// transmitir; si no, el motivo para que la View lo explique.
  Future<LiveMediaIssue?> preparePublish() => engine.preparePublish();

  Future<void> openPermissionSettings() => engine.openPermissionSettings();

  Future<void> switchCamera() => engine.switchCamera();

  /// El nuevo valor lo confirma el motor por su stream: si Agora no pudo
  /// silenciar, el botón no miente.
  Future<void> toggleMicrophone() =>
      engine.setMicrophoneMuted(muted: !state.micMuted);

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await engine.dispose();
    return super.close();
  }
}
