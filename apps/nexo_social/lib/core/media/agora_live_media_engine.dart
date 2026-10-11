import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import 'live_media_engine.dart';

/// Video real con Agora.
///
/// El motor nativo de Agora es uno por proceso, así que se crea en el primer
/// [join] y se libera en [dispose]. El host publica cámara y micrófono; la
/// audiencia se suscribe a lo que publiquen los demás.
class AgoraLiveMediaEngine implements LiveMediaEngine {
  AgoraLiveMediaEngine(this._appId);

  final String _appId;
  RtcEngine? _engine;
  final _states = StreamController<LiveMediaState>.broadcast();
  var _remoteUids = <int>[];
  var _phase = LiveMediaPhase.idle;
  var _micMuted = false;
  Timer? _joinTimeout;

  /// Cuánto se espera a que Agora confirme la entrada al canal. Un App ID
  /// inválido o una red bloqueada no siempre devuelven error —en web,
  /// `initialize` puede no terminar nunca—: sin tope, la sala se quedaba en
  /// "Conectando el video…" para siempre.
  static const joinTimeout = Duration(seconds: 10);

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
    final isHost = role == LiveMediaRole.host;
    _emit(const LiveMediaState(phase: LiveMediaPhase.joining));
    // Antes de cualquier await: si uno de ellos no vuelve, el tope igual
    // corre.
    _joinTimeout?.cancel();
    _joinTimeout = Timer(joinTimeout, () {
      if (_phase == LiveMediaPhase.joining) _fail();
    });

    // En el teléfono el sistema pide permiso de cámara y micrófono; en web
    // lo pide el navegador cuando Agora abre la cámara.
    if (isHost && _needsRuntimePermissions) {
      final granted = await [
        Permission.camera,
        Permission.microphone,
      ].request();
      if (granted.values.any((status) => !status.isGranted)) {
        _emit(
          const LiveMediaState(
            phase: LiveMediaPhase.failed,
            issue: LiveMediaIssue.permissionDenied,
          ),
        );
        return;
      }
    }

    try {
      final engine = await _ensureEngine();
      await engine.setClientRole(
        role: isHost
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
      );
      if (isHost) await engine.startPreview();
      await engine.joinChannel(
        token: token,
        channelId: channel,
        // El del token: un token firmado para un uid no vale para otro.
        uid: uid,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: isHost
              ? ClientRoleType.clientRoleBroadcaster
              : ClientRoleType.clientRoleAudience,
          publishCameraTrack: isHost,
          publishMicrophoneTrack: isHost,
          autoSubscribeVideo: true,
          autoSubscribeAudio: true,
        ),
      );
    } on Object catch (error) {
      debugPrint('Agora join failed: $error');
      _fail();
    }
  }

  void _fail() => _emit(
    const LiveMediaState(
      phase: LiveMediaPhase.failed,
      issue: LiveMediaIssue.unavailable,
    ),
  );

  @override
  Future<void> leave() async {
    _joinTimeout?.cancel();
    _remoteUids = [];
    final engine = _engine;
    if (engine != null) {
      try {
        // El silencio es de esta transmisión: el próximo vivo arranca con
        // micrófono, no mudo sin que nadie lo note.
        if (_micMuted) await engine.muteLocalAudioStream(false);
        await engine.stopPreview();
        await engine.leaveChannel();
      } on Object catch (error) {
        debugPrint('Agora leave failed: $error');
      }
    }
    _micMuted = false;
    _emit(const LiveMediaState());
  }

  @override
  Future<LiveMediaIssue?> preparePublish() async {
    if (!_needsRuntimePermissions) return null;
    final statuses = await [Permission.camera, Permission.microphone].request();
    if (statuses.values.every((status) => status.isGranted)) return null;
    return statuses.values.any((status) => status.isPermanentlyDenied)
        ? LiveMediaIssue.permissionBlocked
        : LiveMediaIssue.permissionDenied;
  }

  @override
  Future<void> openPermissionSettings() async {
    await openAppSettings();
  }

  @override
  Future<void> switchCamera() async {
    final engine = _engine;
    if (engine == null) return;
    try {
      await engine.switchCamera();
    } on Object catch (error) {
      debugPrint('Agora switchCamera failed: $error');
    }
  }

  @override
  Future<void> setMicrophoneMuted({required bool muted}) async {
    final engine = _engine;
    if (engine == null) return;
    try {
      await engine.muteLocalAudioStream(muted);
      _micMuted = muted;
      _emit(
        LiveMediaState(
          phase: _phase,
          remoteUids: List.unmodifiable(_remoteUids),
        ),
      );
    } on Object catch (error) {
      debugPrint('Agora mute failed: $error');
    }
  }

  @override
  Widget localView() {
    final engine = _engine;
    if (engine == null) return const SizedBox.shrink();
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: engine,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  @override
  Widget remoteView(String channel, int uid) {
    final engine = _engine;
    if (engine == null) return const SizedBox.shrink();
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: engine,
        canvas: VideoCanvas(uid: uid),
        connection: RtcConnection(channelId: channel),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _joinTimeout?.cancel();
    final engine = _engine;
    _engine = null;
    if (engine != null) {
      try {
        await engine.leaveChannel();
        await engine.release();
      } on Object catch (error) {
        debugPrint('Agora release failed: $error');
      }
    }
    await _states.close();
  }

  Future<RtcEngine> _ensureEngine() async {
    final existing = _engine;
    if (existing != null) return existing;

    final engine = createAgoraRtcEngine();
    await engine.initialize(
      RtcEngineContext(
        appId: _appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );
    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) => _emit(
          LiveMediaState(
            phase: LiveMediaPhase.connected,
            remoteUids: List.unmodifiable(_remoteUids),
          ),
        ),
        onUserJoined: (connection, remoteUid, elapsed) {
          if (!_remoteUids.contains(remoteUid)) {
            _remoteUids = [..._remoteUids, remoteUid];
          }
          _emitConnected();
        },
        onUserOffline: (connection, remoteUid, reason) {
          _remoteUids = _remoteUids.where((uid) => uid != remoteUid).toList();
          _emitConnected();
        },
        onError: (error, message) {
          debugPrint('Agora error: $error $message');
          // Un error antes de entrar al canal es un fallo de conexión. Ya
          // adentro, Agora reintenta solo y no se corta la sala por eso.
          if (_phase == LiveMediaPhase.joining) _fail();
        },
      ),
    );
    await engine.enableVideo();
    _engine = engine;
    return engine;
  }

  void _emitConnected() => _emit(
    LiveMediaState(
      phase: LiveMediaPhase.connected,
      remoteUids: List.unmodifiable(_remoteUids),
    ),
  );

  /// Toda emisión lleva el silencio vigente: si no, el próximo evento del
  /// canal (alguien que entra) lo pisaría con `false` y el botón diría
  /// "Silenciar" con el micrófono apagado.
  void _emit(LiveMediaState state) {
    _phase = state.phase;
    if (state.phase != LiveMediaPhase.joining) _joinTimeout?.cancel();
    if (!_states.isClosed) {
      _states.add(
        state.micMuted == _micMuted
            ? state
            : LiveMediaState(
                phase: state.phase,
                remoteUids: state.remoteUids,
                issue: state.issue,
                micMuted: _micMuted,
              ),
      );
    }
  }

  static bool get _needsRuntimePermissions =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}
