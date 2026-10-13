import 'package:equatable/equatable.dart';

import 'live_session.dart';

/// Alguien en el escenario: tiene micrófono y, si quiere, cámara.
class LiveSpeaker extends Equatable {
  const LiveSpeaker({
    required this.userId,
    required this.name,
    required this.role,
    this.username = '',
    this.avatarUrl,
    this.micMuted = false,
    this.cameraOn = false,
    this.isMe = false,
  });

  final String userId;
  final String name;

  /// Sin `@`. Vacío si la fuente no lo sabe.
  final String username;
  final String? avatarUrl;
  final LiveRole role;
  final bool micMuted;
  final bool cameraOn;

  /// Es la cuenta de la sesión. Lo decide el repositorio, que es quien sabe
  /// quién es "yo".
  final bool isMe;

  @override
  List<Object?> get props => [
    userId,
    name,
    username,
    avatarUrl,
    role,
    micMuted,
    cameraOn,
    isMe,
  ];
}

/// Alguien que pidió la palabra.
class LiveHand extends Equatable {
  const LiveHand({
    required this.userId,
    required this.name,
    required this.raisedAt,
    this.username = '',
    this.avatarUrl,
    this.isMe = false,
  });

  final String userId;
  final String name;
  final String username;
  final String? avatarUrl;
  final DateTime raisedAt;
  final bool isMe;

  @override
  List<Object?> get props => [
    userId,
    name,
    username,
    avatarUrl,
    raisedAt,
    isMe,
  ];
}

/// El escenario de una sala (SDD 0011): el host primero y después los
/// invitados por orden de llegada, y la cola de pedidos de palabra.
class LiveStage extends Equatable {
  const LiveStage({this.speakers = const [], this.hands = const []});

  static const empty = LiveStage();

  final List<LiveSpeaker> speakers;

  /// Del pedido más viejo al más nuevo.
  final List<LiveHand> hands;

  bool get meOnStage => speakers.any((s) => s.isMe);
  bool get myHandRaised => hands.any((h) => h.isMe);
  LiveSpeaker? get me => speakers.where((s) => s.isMe).firstOrNull;

  @override
  List<Object?> get props => [speakers, hands];
}
