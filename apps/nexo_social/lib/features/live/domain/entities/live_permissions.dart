import 'live_session.dart';

/// Lo que alguien puede hacer dentro de un vivo (SDD 0011, §3).
enum LiveAction {
  /// Hablar y prender la cámara. Además del rol, requiere estar en el
  /// escenario.
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

/// La tabla de permisos de una sala: el **espejo** de `LivePermissions` del
/// servidor (`modules/live/services/live_permissions.dart`).
///
/// Existe para que la app ofrezca **sólo** lo que el servidor acepta: un botón
/// para una acción ilegal es una petición que se rechaza después de que el
/// usuario ya se comprometió. `live_permissions_contract_test.dart` lee los
/// dos archivos y falla si los bloques entre marcas se separan, así que una
/// regla nueva se escribe en los dos lados o en ninguno.
///
/// En el contrato el invitado se llama `cohost` (SDD 0011, S2); la copy dice
/// "Invitado".
abstract final class LivePermissions {
  /// Quién puede hacer cada acción.
  // permisos:inicio
  static const allowed = <LiveAction, Set<LiveRole>>{
    LiveAction.speak: {LiveRole.host, LiveRole.moderator, LiveRole.cohost},
    LiveAction.raiseHand: {LiveRole.moderator, LiveRole.audience},
    LiveAction.leaveStage: {LiveRole.moderator, LiveRole.cohost},
    LiveAction.approveRequest: {LiveRole.host, LiveRole.moderator},
    LiveAction.inviteToStage: {LiveRole.host},
    LiveAction.removeFromStage: {LiveRole.host},
    LiveAction.muteMic: {LiveRole.host, LiveRole.moderator},
    LiveAction.assignModerator: {LiveRole.host},
    LiveAction.hideChat: {LiveRole.host, LiveRole.moderator},
    LiveAction.deleteChat: {LiveRole.host, LiveRole.moderator},
    LiveAction.pinChat: {LiveRole.host, LiveRole.moderator},
    LiveAction.highlightQuestion: {
      LiveRole.host,
      LiveRole.moderator,
      LiveRole.cohost,
    },
    LiveAction.muteChat: {LiveRole.host, LiveRole.moderator},
    LiveAction.kick: {LiveRole.host, LiveRole.moderator},
    LiveAction.ban: {LiveRole.host},
    LiveAction.chat: {
      LiveRole.host,
      LiveRole.moderator,
      LiveRole.cohost,
      LiveRole.audience,
    },
    LiveAction.react: {
      LiveRole.host,
      LiveRole.moderator,
      LiveRole.cohost,
      LiveRole.audience,
    },
    LiveAction.end: {LiveRole.host},
  };
  // permisos:fin

  /// Las acciones que recaen **sobre otra persona**: exigen rango estrictamente
  /// mayor que el de ella.
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
  static int rank(LiveRole role) => switch (role) {
    LiveRole.host => 3,
    LiveRole.moderator => 2,
    LiveRole.cohost => 1,
    LiveRole.audience => 0,
  };

  /// Si [actor] puede hacer [action]. Para una acción [targeted], [target] es
  /// el rol de la persona sobre la que recae; sin él, `false`.
  static bool can(LiveRole actor, LiveAction action, {LiveRole? target}) {
    if (!(allowed[action]?.contains(actor) ?? false)) return false;
    if (!targeted.contains(action)) return true;
    return target != null && rank(actor) > rank(target);
  }

  /// Si el rol tiene la acción en su repertorio, sin mirar sobre quién. Es lo
  /// que decide si un control se **dibuja**; [can] decide si se ofrece para
  /// una persona en particular.
  static bool hasAction(LiveRole role, LiveAction action) =>
      allowed[action]?.contains(role) ?? false;

  /// Las acciones que [actor] puede hacer sobre alguien con rol [target]: lo
  /// que lista la hoja de una persona.
  static List<LiveAction> on(LiveRole actor, LiveRole target) => [
    for (final action in LiveAction.values)
      if (targeted.contains(action) && can(actor, action, target: target))
        action,
  ];
}
