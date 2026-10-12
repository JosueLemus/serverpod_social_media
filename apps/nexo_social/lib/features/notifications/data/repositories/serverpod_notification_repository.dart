import 'dart:async';

import 'package:nexo_client/nexo_client.dart' as api;

import '../../../../core/network/serverpod_failures.dart';
import '../../../feed/data/repositories/serverpod_post_repository.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// La bandeja contra `notifications` de Serverpod (SDD 0008 §3.3).
///
/// Los avisos los crea el servidor en la misma transacción que la acción que
/// los origina; acá sólo se leen, se marcan y se escuchan.
class ServerpodNotificationRepository implements NotificationRepository {
  ServerpodNotificationRepository(this._client);

  final api.Client _client;
  final _unread = StreamController<int>.broadcast();

  @override
  Future<NotificationFeedPage> list({String? cursor}) => _guard(() async {
    final page = await _client.notifications.list(
      after: ServerpodPostRepository.decodeCursor(cursor),
    );
    return NotificationFeedPage(
      items: [for (final view in page.items) toNotification(view)],
      nextCursor: ServerpodPostRepository.encodeCursor(page.nextCursor),
    );
  });

  @override
  Future<int> unreadCount() => _guard(_client.notifications.unreadCount);

  @override
  Future<int> markRead(List<String> ids) => _guard(() async {
    final remaining = await _client.notifications.markRead([
      for (final id in ids) ?int.tryParse(id),
    ]);
    _unread.add(remaining);
    return remaining;
  });

  @override
  Future<int> markAllRead() => _guard(() async {
    final remaining = await _client.notifications.markAllRead();
    _unread.add(remaining);
    return remaining;
  });

  /// Los errores del stream también salen como [Failure]: quien escucha
  /// decide si reintenta, y para eso necesita saber si fue la red o la
  /// sesión.
  @override
  Stream<AppNotification> watch() => _client.notifications.watch().transform(
    StreamTransformer.fromHandlers(
      handleData: (view, sink) => sink.add(toNotification(view)),
      handleError: (error, stackTrace, sink) =>
          sink.addError(failureFromServer(error), stackTrace),
    ),
  );

  @override
  Stream<int> unreadChanges() => _unread.stream;

  /// Sin evento destacado en el servidor: inventar uno es justo lo que la
  /// auditoría del front marcó.
  @override
  Future<FeaturedActivity?> featured() async => null;

  static AppNotification toNotification(api.NotificationView view) =>
      AppNotification(
        id: '${view.id}',
        type: typeOf(view.kind),
        actor: view.actorName ?? view.actorUsername,
        actorUsername: view.actorUsername,
        actorAvatarUrl: view.actorAvatarUrl,
        subject: view.showTitle ?? view.postExcerpt,
        postId: view.postId?.toString(),
        showId: view.showId?.toString(),
        createdAt: view.createdAt,
        read: view.isRead,
      );

  static NotificationType typeOf(api.NotificationKind kind) => switch (kind) {
    api.NotificationKind.newFollower => NotificationType.follow,
    api.NotificationKind.postLiked => NotificationType.like,
    api.NotificationKind.postCommented => NotificationType.comment,
    api.NotificationKind.liveStarted => NotificationType.liveReminder,
    api.NotificationKind.showStartingSoon => NotificationType.showSoon,
    api.NotificationKind.reportResolved => NotificationType.moderation,
  };

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (error) {
      throw failureFromServer(error);
    }
  }
}
