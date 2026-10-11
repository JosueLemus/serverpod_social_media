import 'package:equatable/equatable.dart';

import 'live_comment.dart';
import 'live_session.dart';

/// Lo que llega de una sala en tiempo real (`LiveRepository.watch`).
///
/// El primero siempre es un [LiveRoomSnapshot]: trae todo, así que una
/// reconexión resincroniza la sala sin pedir nada aparte. Los demás son
/// cambios puntuales que la sala aplica encima.
sealed class LiveRoomEvent extends Equatable {
  const LiveRoomEvent();
}

/// La sala entera. También lo emite el mock en cada cambio, porque no sabe
/// decir qué cambió.
class LiveRoomSnapshot extends LiveRoomEvent {
  const LiveRoomSnapshot({
    required this.session,
    required this.role,
    required this.comments,
  });

  final LiveSession session;

  /// Calculado para quien mira: es el único evento que trae el rol.
  final LiveRole role;
  final List<LiveComment> comments;

  @override
  List<Object?> get props => [session, role, comments];
}

/// El vivo cambió de estado (empezó, terminó, lo cortó un operador).
class LiveSessionChanged extends LiveRoomEvent {
  const LiveSessionChanged(this.session);

  final LiveSession session;

  @override
  List<Object?> get props => [session];
}

class LiveViewersChanged extends LiveRoomEvent {
  const LiveViewersChanged(this.viewers);

  final int viewers;

  @override
  List<Object?> get props => [viewers];
}

class LiveCommentAdded extends LiveRoomEvent {
  const LiveCommentAdded(this.comment);

  final LiveComment comment;

  @override
  List<Object?> get props => [comment];
}

/// Un comentario se ocultó para todos. Llega también a quien lo ocultó.
class LiveCommentHidden extends LiveRoomEvent {
  const LiveCommentHidden(this.commentId);

  final String commentId;

  @override
  List<Object?> get props => [commentId];
}
