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
enum LiveMediaIssue { permissionDenied, unavailable }

class LiveMediaState extends Equatable {
  const LiveMediaState({
    this.phase = LiveMediaPhase.idle,
    this.remoteUids = const [],
    this.issue,
  });

  final LiveMediaPhase phase;

  /// Quienes publican video en el canal, en orden de llegada. Para la
  /// audiencia, el primero es el host.
  final List<int> remoteUids;
  final LiveMediaIssue? issue;

  @override
  List<Object?> get props => [phase, remoteUids, issue];
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
  /// Agora (proyecto sin certificado); en producción lo emite el servidor.
  Future<void> join({
    required String channel,
    required LiveMediaRole role,
    String token = '',
  });

  Future<void> leave();

  /// La cámara propia, para el host.
  Widget localView();

  /// El video de [uid] en [channel], para la audiencia.
  Widget remoteView(String channel, int uid);

  Future<void> dispose();
}
