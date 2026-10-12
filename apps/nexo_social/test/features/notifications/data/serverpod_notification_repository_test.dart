import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_client/nexo_client.dart' as api;
import 'package:nexo_social/features/notifications/data/repositories/serverpod_notification_repository.dart';
import 'package:nexo_social/features/notifications/domain/entities/app_notification.dart';

void main() {
  final createdAt = DateTime.utc(2026, 10, 11, 20);

  test('un aviso de vivo trae el show para abrir la sala', () {
    final notification = ServerpodNotificationRepository.toNotification(
      api.NotificationView(
        id: 7,
        kind: api.NotificationKind.liveStarted,
        actorId: api.UuidValue.fromString(
          '01a12c4d-5408-760b-8bc2-03c7b5e24f14',
        ),
        actorUsername: 'elena_ux',
        actorName: 'Elena Vega',
        actorAvatarUrl: 'https://cdn/elena.webp',
        showId: 5,
        showTitle: 'Masterclass',
        isRead: false,
        createdAt: createdAt,
      ),
    );

    expect(
      notification,
      AppNotification(
        id: '7',
        type: NotificationType.liveReminder,
        actor: 'Elena Vega',
        actorUsername: 'elena_ux',
        actorAvatarUrl: 'https://cdn/elena.webp',
        subject: 'Masterclass',
        showId: '5',
        createdAt: createdAt,
      ),
    );
  });

  test('un like trae el comienzo del post y su id', () {
    final notification = ServerpodNotificationRepository.toNotification(
      api.NotificationView(
        id: 8,
        kind: api.NotificationKind.postLiked,
        actorUsername: 'tomas',
        postId: 42,
        postExcerpt: 'Tokens de diseño',
        isRead: true,
        createdAt: createdAt,
      ),
    );

    expect(notification.type, NotificationType.like);
    // Sin nombre visible, el username identifica igual.
    expect(notification.actor, 'tomas');
    expect(notification.postId, '42');
    expect(notification.subject, 'Tokens de diseño');
    expect(notification.read, isTrue);
  });

  test('un aviso del sistema no tiene actor', () {
    final notification = ServerpodNotificationRepository.toNotification(
      api.NotificationView(
        id: 9,
        kind: api.NotificationKind.reportResolved,
        isRead: false,
        createdAt: createdAt,
      ),
    );

    expect(notification.actor, isNull);
    expect(notification.type, NotificationType.moderation);
  });

  test('cada tipo del servidor tiene su tipo en la app', () {
    expect(
      {
        for (final kind in api.NotificationKind.values)
          kind: ServerpodNotificationRepository.typeOf(kind),
      },
      {
        api.NotificationKind.newFollower: NotificationType.follow,
        api.NotificationKind.postLiked: NotificationType.like,
        api.NotificationKind.postCommented: NotificationType.comment,
        api.NotificationKind.liveStarted: NotificationType.liveReminder,
        api.NotificationKind.showStartingSoon: NotificationType.showSoon,
        api.NotificationKind.reportResolved: NotificationType.moderation,
      },
    );
  });
}
