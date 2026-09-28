import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

/// Escribe en [AuditLog]. Pasar [transaction] para que el registro se
/// confirme o descarte junto con la acción auditada.
class AuditService {
  const AuditService();

  Future<void> record(
    Session session, {
    required UuidValue? actorId,
    required String action,
    required String entityType,
    required String entityId,
    Map<String, Object?>? metadata,
    Transaction? transaction,
  }) async {
    await AuditLog.db.insertRow(
      session,
      AuditLog(
        actorId: actorId,
        action: action,
        entityType: entityType,
        entityId: entityId,
        metadataJson: metadata == null ? null : jsonEncode(metadata),
      ),
      transaction: transaction,
    );
  }
}
