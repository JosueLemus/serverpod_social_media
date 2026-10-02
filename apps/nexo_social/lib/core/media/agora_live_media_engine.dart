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
        uid: 0,
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
        await engine.stopPreview();
        await engine.leaveChannel();
      } on Object catch (error) {
        debugPrint('Agora leave failed: $error');
      }
    }
    _emit(const LiveMediaState());
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

  void _emit(LiveMediaState state) {
    _phase = state.phase;
    if (state.phase != LiveMediaPhase.joining) _joinTimeout?.cancel();
    if (!_states.isClosed) _states.add(state);
  }

  static bool get _needsRuntimePermissions =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}
