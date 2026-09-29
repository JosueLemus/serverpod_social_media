import 'package:equatable/equatable.dart';

import '../../../moderation/domain/entities/moderation_action.dart';

/// Toda acción que la consola audita. Un conjunto cerrado: el filtro de la
/// auditoría y la consulta del backend necesitan saber de antemano qué
/// valores existen.
enum AuditAction {
  reportFiled('Reporte recibido', AuditEntity.report),
  reportDismissed('Reporte descartado', AuditEntity.report),
  commentHidden('Comentario oculto', AuditEntity.comment),
  userMuted('Usuario silenciado', AuditEntity.account),
  userKicked('Usuario expulsado del vivo', AuditEntity.account),
  accountSuspended('Cuenta suspendida', AuditEntity.account),
  accountBanned('Cuenta baneada', AuditEntity.account),
  accountRestored('Cuenta restaurada', AuditEntity.account),
  verificationGranted('Verificación otorgada', AuditEntity.account),
  verificationRevoked('Verificación revocada', AuditEntity.account),
  liveStarted('Vivo iniciado', AuditEntity.live),
  liveEnded('Vivo finalizado', AuditEntity.live),
  liveForceEnded('Vivo finalizado por operador', AuditEntity.live);

  const AuditAction(this.label, this.entity);

  final String label;
  final AuditEntity entity;
}

enum AuditEntity {
  account('Cuenta'),
  comment('Comentario'),
  report('Reporte'),
  live('Vivo');

  const AuditEntity(this.label);

  final String label;
}

/// Lo que un operador puede ver de un registro de auditoría. Es un DTO
/// propio y no el `AuditLog` del servidor, que es `serverOnly`: decidir qué
/// campos viajan es decidir qué puede ver un operador.
class AuditEntry extends Equatable {
  const AuditEntry({
    required this.id,
    required this.actor,
    required this.action,
    required this.entityId,
    required this.target,
    required this.createdAt,
    this.reason,
  });

  final String id;

  /// El handle de quien actuó. Nunca vacío.
  final String actor;
  final AuditAction action;
  final String entityId;

  /// Sobre qué se actuó, en forma legible: `@troll_99`, un título de vivo.
  final String target;
  final ModerationReason? reason;
  final DateTime createdAt;

  AuditEntity get entity => action.entity;

  @override
  List<Object?> get props => [
    id,
    actor,
    action,
    entityId,
    target,
    reason,
    createdAt,
  ];
}

class AuditFilter extends Equatable {
  const AuditFilter({this.actor, this.action, this.entity, this.since});

  /// Handle, sin `@`. Coincide por prefijo.
  final String? actor;
  final AuditAction? action;
  final AuditEntity? entity;
  final DateTime? since;

  bool get isEmpty =>
      (actor == null || actor!.isEmpty) &&
      action == null &&
      entity == null &&
      since == null;

  @override
  List<Object?> get props => [actor, action, entity, since];
}
