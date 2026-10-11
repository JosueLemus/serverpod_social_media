import 'dart:async';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// La bandeja de `AUTH_SOURCE=mock` y de los tests: una semilla en memoria.
///
/// No hay servidor que empuje avisos, así que [watch] sólo emite lo que se
/// entrega con [deliver] — que es como los tests simulan un aviso en vivo.
class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository({List<AppNotification>? seed, this.featuredSeed})
    : _items = [...(seed ?? _seed())];

  final List<AppNotification> _items;
  final FeaturedActivity? featuredSeed;
  final _incoming = StreamController<AppNotification>.broadcast();
  final _unread = StreamController<int>.broadcast();

  int get _unreadCount => _items.where((item) => !item.read).length;

  /// Un aviso nuevo, como si lo hubiera mandado el servidor.
  void deliver(AppNotification notification) {
    _items.insert(0, notification);
    _incoming.add(notification);
  }

  @override
  Future<NotificationFeedPage> list({String? cursor}) async =>
      NotificationFeedPage(items: List.unmodifiable(_items));

  @override
  Future<int> unreadCount() async => _unreadCount;

  @override
  Future<int> markRead(List<String> ids) async {
    for (var index = 0; index < _items.length; index++) {
      if (ids.contains(_items[index].id)) {
        _items[index] = _items[index].copyWith(read: true);
      }
    }
    _unread.add(_unreadCount);
    return _unreadCount;
  }

  @override
  Future<int> markAllRead() async {
    for (var index = 0; index < _items.length; index++) {
      _items[index] = _items[index].copyWith(read: true);
    }
    _unread.add(0);
    return 0;
  }

  @override
  Stream<AppNotification> watch() => _incoming.stream;

  @override
  Stream<int> unreadChanges() => _unread.stream;

  @override
  Future<FeaturedActivity?> featured() async => featuredSeed ?? _seedFeatured;

  static const _seedFeatured = FeaturedActivity(
    title: 'Masterclass: Diseño de Arquitectura de Sistemas',
    detail: 'Con Lucas Vance y 3 ponentes de la comunidad',
    startsIn: Duration(minutes: 45),
    participants: ['Lucas Vance', 'Elena Vega', 'Carlos Méndez'],
  );

  static DateTime _ago(Duration elapsed) => DateTime.now().subtract(elapsed);

  static List<AppNotification> _seed() => [
    AppNotification(
      id: '1',
      type: NotificationType.liveReminder,
      actor: 'Elena Vega',
      actorUsername: 'elena_ux',
      subject: 'Masterclass de Diseño Mobile',
      showId: 'live-1',
      createdAt: _ago(const Duration(minutes: 12)),
    ),
    AppNotification(
      id: '2',
      type: NotificationType.membership,
      actor: 'Carlos Méndez',
      actorUsername: 'carlos_mendez',
      quote: '¡Listo para colaborar en el roadmap!',
      createdAt: _ago(const Duration(hours: 2)),
    ),
    AppNotification(
      id: '3',
      type: NotificationType.comment,
      actor: 'Elena Vega',
      actorUsername: 'elena_ux',
      subject: 'Tokens de diseño en Flutter',
      quote:
          '¿Qué opinas de esta arquitectura modular para optimizar las '
          're-renderizaciones en chats masivos?',
      postId: 'post-1',
      createdAt: _ago(const Duration(hours: 4)),
    ),
    AppNotification(
      id: '4',
      type: NotificationType.follow,
      actor: 'Tomás Ríos',
      actorUsername: 'tomas',
      createdAt: _ago(const Duration(hours: 9)),
    ),
    AppNotification(
      id: '5',
      type: NotificationType.like,
      actor: 'Carlos Méndez',
      actorUsername: 'carlos_mendez',
      subject: 'Rediseñando la experiencia de micro-comunidades',
      postId: 'post-2',
      createdAt: _ago(const Duration(days: 3)),
      read: true,
    ),
    AppNotification(
      id: '6',
      type: NotificationType.moderation,
      createdAt: _ago(const Duration(days: 9)),
      read: true,
    ),
  ];
}
