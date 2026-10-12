import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

/// Qué hace la cuenta en el canal de video. El host publica cámara y
/// micrófono; la audiencia sólo se suscribe.
///
/// Hoy lo elige la pantalla (el studio es host, la sala es audiencia). Con
/// la etapa B del SDD 0005 lo decide el servidor al emitir el token, y el
/// cliente no puede pedir ser publicador.
enum LiveMediaRole { host, audience }

enum LiveMediaPhase { idle, joining, connected, failed }

/// Por qué no se pudo conectar. La View lo traduce; el texto del proveedor
/// nunca se pinta.
///
/// [permissionBlocked] es el "no volver a preguntar": el sistema ya no
/// muestra el diálogo y la única salida son los ajustes del teléfono.
enum LiveMediaIssue { permissionDenied, permissionBlocked, unavailable }

class LiveMediaState extends Equatable {
  const LiveMediaState({
    this.phase = LiveMediaPhase.idle,
    this.remoteUids = const [],
    this.issue,
    this.micMuted = false,
  });

  final LiveMediaPhase phase;

  /// Quienes publican video en el canal, en orden de llegada. Para la
  /// audiencia, el primero es el host.
  final List<int> remoteUids;
  final LiveMediaIssue? issue;

  /// El host apagó su micrófono. Lo lleva el motor, que es quien lo aplica:
  /// un flag en la pantalla podría decir "silenciado" mientras se sigue
  /// transmitiendo audio.
  final bool micMuted;

  @override
  List<Object?> get props => [phase, remoteUids, issue, micMuted];
}

/// El video de un vivo, sin importar quién lo transmite.
///
/// Dos implementaciones: Agora (`AGORA_APP_ID` definido) y la simulada, que
/// dibuja lo de siempre. `injection.dart` elige; las pantallas no saben cuál
/// es. Vive en `core/` y no en `domain/` porque devuelve widgets: la vista
/// del video es del proveedor.
abstract interface class LiveMediaEngine {
  /// Si no hay video real. La pantalla muestra el escenario simulado.
  bool get isSimulated;

  Stream<LiveMediaState> get states;

  /// Se une a [channel]. [token] vacío sólo sirve en el modo de prueba de
  /// Agora (proyecto sin certificado); en producción lo emite el servidor
  /// junto con [uid], que tiene que ser el mismo para el que se firmó (0
  /// deja que Agora asigne uno).
  Future<void> join({
    required String channel,
    required LiveMediaRole role,
    String token = '',
    int uid = 0,
  });

  Future<void> leave();

  /// Pide cámara y micrófono **antes** de salir al aire. `null` si quedaron
  /// concedidos. Va antes de iniciar el vivo en el servidor: pedirlos recién
  /// al entrar al canal deja un vivo al aire sin cámara si la persona dice
  /// que no.
  Future<LiveMediaIssue?> preparePublish();

  /// Los ajustes del sistema de esta app, para cuando el permiso quedó
  /// bloqueado y el diálogo ya no aparece.
  Future<void> openPermissionSettings();

  /// Alterna entre la cámara frontal y la trasera.
  Future<void> switchCamera();

  /// Deja de mandar audio sin salir del canal. El nuevo valor llega por
  /// [states] en `micMuted`.
  Future<void> setMicrophoneMuted({required bool muted});

  /// La cámara propia, para el host.
  Widget localView();

  /// El video de [uid] en [channel], para la audiencia.
  Widget remoteView(String channel, int uid);

  Future<void> dispose();
}
