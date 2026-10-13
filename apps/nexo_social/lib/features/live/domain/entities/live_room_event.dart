import 'package:equatable/equatable.dart';

import 'live_comment.dart';
import 'live_moderation.dart';
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
    this.pinned,
    this.highlighted,
    this.myMute,
    this.exclusion,
  });

  final LiveSession session;

  /// Calculado para quien mira: es el único evento que trae el rol.
  final LiveRole role;
  final List<LiveComment> comments;
  final LiveStage stage;

  /// El mensaje fijado y la pregunta destacada, si hay.
  final LiveComment? pinned;
  final LiveComment? highlighted;

  /// El silencio vigente de quien mira.
  final LiveChatMute? myMute;

  /// Si quien mira fue expulsado o baneado. El servidor no lo manda —a un
  /// expulsado le rechaza la conexión—; el mock, que emite la sala entera en
  /// cada cambio, sí.
  final LiveSanctionKind? exclusion;

  @override
  List<Object?> get props => [
    session,
    role,
    comments,
    stage,
    pinned,
    highlighted,
    myMute,
    exclusion,
  ];
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

/// Una sanción a alguien de la sala. Se publica igual para todos; la sala la
/// aplica a sí misma sólo si [isMine].
class LiveSanctioned extends LiveRoomEvent {
  const LiveSanctioned({
    required this.userId,
    required this.kind,
    required this.isMine,
    this.until,
  });

  final String userId;
  final LiveSanctionKind kind;
  final bool isMine;

  /// Hasta cuándo dura un silencio. Null: el resto del vivo. Un `until` ya
  /// pasado es un silencio levantado.
  final DateTime? until;

  @override
  List<Object?> get props => [userId, kind, isMine, until];
}

/// Un comentario se borró para todos. A diferencia de oculto, no vuelve.
class LiveCommentDeleted extends LiveRoomEvent {
  const LiveCommentDeleted(this.commentId);

  final String commentId;

  @override
  List<Object?> get props => [commentId];
}

/// Un comentario oculto volvió al chat.
class LiveCommentRestored extends LiveRoomEvent {
  const LiveCommentRestored(this.comment);

  final LiveComment comment;

  @override
  List<Object?> get props => [comment];
}

/// Cambió el mensaje fijado. Null: se despegó.
class LivePinnedChanged extends LiveRoomEvent {
  const LivePinnedChanged(this.comment);

  final LiveComment? comment;

  @override
  List<Object?> get props => [comment];
}

/// Cambió la pregunta destacada. Null: se quitó.
class LiveHighlightChanged extends LiveRoomEvent {
  const LiveHighlightChanged(this.comment);

  final LiveComment? comment;

  @override
  List<Object?> get props => [comment];
}
