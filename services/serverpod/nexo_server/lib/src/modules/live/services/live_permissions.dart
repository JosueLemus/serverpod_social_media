import '../../../generated/protocol.dart';

/// Lo que alguien puede hacer dentro de un vivo (SDD 0011, §3).
enum LiveAction {
  /// Hablar y prender la cámara. Además del rol, requiere estar en el
  /// escenario: eso lo decide el servicio, no esta tabla (S5).
  speak,
  raiseHand,
  leaveStage,
  approveRequest,
  inviteToStage,
  removeFromStage,
  muteMic,
  assignModerator,
  hideChat,
  deleteChat,
  pinChat,
  highlightQuestion,
  muteChat,
  kick,
  ban,
  chat,
  react,
  end,
}

/// La tabla de permisos de una sala. Reglas puras: no tocan la base.
///
/// Tiene un **espejo** en la app (`features/live/domain/entities/
/// live_permissions.dart`) y un test de contrato que lee los dos archivos y
/// falla si se separan: la app sólo ofrece lo que esta tabla acepta. Por eso
/// los dos bloques entre marcas se escriben con el mismo formato.
abstract final class LivePermissions {
  /// Quién puede hacer cada acción.
  // permisos:inicio
  static const allowed = <LiveAction, Set<LiveShowRole>>{
    LiveAction.speak: {
      LiveShowRole.host,
      LiveShowRole.moderator,
      LiveShowRole.cohost,
    },
    LiveAction.raiseHand: {LiveShowRole.moderator, LiveShowRole.audience},
    LiveAction.leaveStage: {LiveShowRole.moderator, LiveShowRole.cohost},
    LiveAction.approveRequest: {LiveShowRole.host, LiveShowRole.moderator},
    LiveAction.inviteToStage: {LiveShowRole.host},
    LiveAction.removeFromStage: {LiveShowRole.host},
    LiveAction.muteMic: {LiveShowRole.host, LiveShowRole.moderator},
    LiveAction.assignModerator: {LiveShowRole.host},
    LiveAction.hideChat: {LiveShowRole.host, LiveShowRole.moderator},
    LiveAction.deleteChat: {LiveShowRole.host, LiveShowRole.moderator},
    LiveAction.pinChat: {LiveShowRole.host, LiveShowRole.moderator},
    LiveAction.highlightQuestion: {
      LiveShowRole.host,
      LiveShowRole.moderator,
      LiveShowRole.cohost,
    },
    LiveAction.muteChat: {LiveShowRole.host, LiveShowRole.moderator},
    LiveAction.kick: {LiveShowRole.host, LiveShowRole.moderator},
    LiveAction.ban: {LiveShowRole.host},
    LiveAction.chat: {
      LiveShowRole.host,
      LiveShowRole.moderator,
      LiveShowRole.cohost,
      LiveShowRole.audience,
    },
    LiveAction.react: {
      LiveShowRole.host,
      LiveShowRole.moderator,
      LiveShowRole.cohost,
      LiveShowRole.audience,
    },
    LiveAction.end: {LiveShowRole.host},
  };
  // permisos:fin

  /// Las acciones que recaen **sobre otra persona**: exigen rango estrictamente
  /// mayor que el de ella (S1).
  // rango:inicio
  static const targeted = <LiveAction>{
    LiveAction.approveRequest,
    LiveAction.inviteToStage,
    LiveAction.removeFromStage,
    LiveAction.muteMic,
    LiveAction.assignModerator,
    LiveAction.hideChat,
    LiveAction.deleteChat,
    LiveAction.muteChat,
    LiveAction.kick,
    LiveAction.ban,
  };
  // rango:fin

  /// Host > moderador > invitado > oyente.
  static int rank(LiveShowRole role) => switch (role) {
    LiveShowRole.host => 3,
    LiveShowRole.moderator => 2,
    LiveShowRole.cohost => 1,
    LiveShowRole.audience => 0,
  };

  /// Si [actor] puede hacer [action]. Para una acción [targeted], [target] es
  /// el rol de la persona sobre la que recae; sin él, la respuesta es `false`:
  /// una acción sobre alguien sin saber sobre quién no se autoriza.
  static bool can(
    LiveShowRole actor,
    LiveAction action, {
    LiveShowRole? target,
  }) {
    if (!(allowed[action]?.contains(actor) ?? false)) return false;
    if (!targeted.contains(action)) return true;
    return target != null && rank(actor) > rank(target);
  }
}
