import 'package:equatable/equatable.dart';

import 'live_comment.dart';
import 'live_session.dart';
import 'live_stage.dart';

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
    this.stage = LiveStage.empty,
  });

  final LiveSession session;

  /// Calculado para quien mira: es el único evento que trae el rol.
  final LiveRole role;
  final List<LiveComment> comments;
  final LiveStage stage;

  @override
  List<Object?> get props => [session, role, comments, stage];
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

/// El escenario cambió: alguien subió, bajó, pidió la palabra o silenció.
class LiveStageChanged extends LiveRoomEvent {
  const LiveStageChanged(this.stage);

  final LiveStage stage;

  @override
  List<Object?> get props => [stage];
}

/// Cambió el rol de alguien en la sala. Se publica igual para todos; la sala
/// sólo lo aplica si [isMine].
class LiveRoleChanged extends LiveRoomEvent {
  const LiveRoleChanged({
    required this.userId,
    required this.role,
    required this.isMine,
  });

  final String userId;
  final LiveRole role;
  final bool isMine;

  @override
  List<Object?> get props => [userId, role, isMine];
}
