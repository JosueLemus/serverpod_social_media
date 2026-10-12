import 'dart:async';

import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/features/notifications/domain/entities/app_notification.dart';
import 'package:nexo_social/features/notifications/domain/repositories/notification_repository.dart';

/// Un repositorio que el test maneja a mano: páginas por cursor, un stream
/// por suscripción (para poder cortarlo) y fallos a pedido.
class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({
    Map<String?, NotificationFeedPage>? pages,
    this.unread = 0,
  }) : pages = pages ?? {null: const NotificationFeedPage(items: [])};

  final Map<String?, NotificationFeedPage> pages;
  int unread;
  bool failMarks = false;
  bool failList = false;
  final markedIds = <List<String>>[];
  int markAllCalls = 0;
  int listCalls = 0;

  /// Una por cada `watch()`: así un test corta la conexión actual y ve si la
  /// pantalla se vuelve a suscribir.
  final watchers = <StreamController<AppNotification>>[];
  final _unread = StreamController<int>.broadcast();

  StreamController<AppNotification> get current => watchers.last;

  @override
  Future<NotificationFeedPage> list({String? cursor}) async {
    listCalls++;
    if (failList) throw const NetworkFailure('offline');
    return pages[cursor] ?? const NotificationFeedPage(items: []);
  }

  @override
  Future<int> unreadCount() async => unread;

  @override
  Future<int> markRead(List<String> ids) async {
    if (failMarks) throw const ServerFailure('boom');
    markedIds.add(ids);
    unread = (unread - ids.length).clamp(0, 1 << 20);
    _unread.add(unread);
    return unread;
  }

  @override
  Future<int> markAllRead() async {
    if (failMarks) throw const ServerFailure('boom');
    markAllCalls++;
    unread = 0;
    _unread.add(0);
    return 0;
  }

  @override
  Stream<AppNotification> watch() {
    final controller = StreamController<AppNotification>();
    watchers.add(controller);
    return controller.stream;
  }

  @override
  Stream<int> unreadChanges() => _unread.stream;

  @override
  Future<FeaturedActivity?> featured() async => null;
}

AppNotification notification(
  String id, {
  NotificationType type = NotificationType.follow,
  Duration ago = const Duration(minutes: 5),
  bool read = false,
  String? actorUsername = 'tomas',
  String? showId,
}) => AppNotification(
  id: id,
  type: type,
  actor: 'Tomás Ríos',
  actorUsername: actorUsername,
  showId: showId,
  createdAt: DateTime.now().subtract(ago),
  read: read,
);
