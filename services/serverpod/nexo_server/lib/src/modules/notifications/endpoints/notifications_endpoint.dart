import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../../shared/auth/auth_context.dart';
import '../services/notification_service.dart';

/// Los avisos de la cuenta de la sesión. Desde Flutter:
/// `client.notifications`. Todo exige sesión.
class NotificationsEndpoint extends Endpoint {
  static const _notifications = NotificationService();

  /// De la más nueva a la más vieja.
  Future<NotificationPage> list(
    Session session, {
    PageCursor? after,
    int? limit,
  }) => _notifications.list(session, after: after, limit: limit);

  Future<int> unreadCount(Session session) =>
      _notifications.unreadCount(session);

  /// Marca [ids] como leídos (sólo los propios). Devuelve los que quedan.
  Future<int> markRead(Session session, List<int> ids) =>
      _notifications.markRead(session, ids);

  /// Marca todos como leídos. Devuelve 0.
  Future<int> markAllRead(Session session) =>
      _notifications.markAllRead(session);

  /// Cada aviso nuevo, en el momento: el badge de Actividad cambia sin
  /// recargar.
  Stream<NotificationView> watch(Session session) {
    // La sesión se valida y el canal se abre antes de cualquier `await`,
    // igual que `live.watch`: lo que llega mientras tanto no se pierde.
    final userId = session.requireUserId;
    return session.messages.createStream<NotificationView>(
      NotificationChannels.user(userId),
    );
  }
}
