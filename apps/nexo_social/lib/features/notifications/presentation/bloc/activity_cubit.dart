import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_notification.dart';

class ActivityState extends Equatable {
  const ActivityState({
    required this.items,
    required this.featured,
    this.filter,
  });

  final List<AppNotification> items;
  final FeaturedActivity? featured;

  /// Null es "todo". Un enum nullable en vez de un miembro centinela para que
  /// los switch exhaustivos sobre NotificationType sigan siendo exhaustivos.
  final NotificationType? filter;

  List<AppNotification> get visible => filter == null
      ? items
      : items.where((item) => item.type == filter).toList();

  int get unreadCount => items.where((item) => !item.read).length;

  /// Cuántas de las visibles están sin leer. Es lo que muestra el encabezado
  /// de cada franja, y tiene que respetar el filtro: contar todas diría "3
  /// nuevas" sobre una lista donde no se ve ninguna.
  int unreadIn(ActivityBucket bucket, {DateTime? now}) => visible
      .where((item) => !item.read && item.bucket(now: now) == bucket)
      .length;

  List<AppNotification> inBucket(ActivityBucket bucket, {DateTime? now}) =>
      visible.where((item) => item.bucket(now: now) == bucket).toList();

  ActivityState copyWith({
    List<AppNotification>? items,
    FeaturedActivity? featured,
    NotificationType? filter,
    bool clearFilter = false,
  }) => ActivityState(
    items: items ?? this.items,
    featured: featured ?? this.featured,
    filter: clearFilter ? null : (filter ?? this.filter),
  );

  @override
  List<Object?> get props => [items, featured, filter];
}

class ActivityCubit extends Cubit<ActivityState> {
  ActivityCubit()
    : super(ActivityState(items: _seed(), featured: _seedFeatured()));

  static DateTime _ago(Duration elapsed) => DateTime.now().subtract(elapsed);

  static FeaturedActivity _seedFeatured() => const FeaturedActivity(
    title: 'Masterclass: Diseño de Arquitectura de Sistemas',
    detail: 'Con Lucas Vance y 3 ponentes de la comunidad',
    startsIn: Duration(minutes: 45),
    participants: ['Lucas Vance', 'Elena Vega', 'Carlos Méndez'],
  );

  static List<AppNotification> _seed() => [
    AppNotification(
      id: '1',
      type: NotificationType.liveReminder,
      actor: 'Sofía Streamer',
      title: 'Ha iniciado un live: "Debate en vivo: Figma Make vs Real Code"',
      detail: '842 espectadores',
      createdAt: _ago(const Duration(minutes: 12)),
    ),
    AppNotification(
      id: '2',
      type: NotificationType.membership,
      actor: 'Carlos Méndez',
      title:
          'Se unió a tu comunidad exclusiva y desbloqueó el pase de mentoría',
      quote: '¡Listo para colaborar en el roadmap!',
      createdAt: _ago(const Duration(hours: 2)),
    ),
    AppNotification(
      id: '3',
      type: NotificationType.comment,
      actor: 'Elena Vega',
      title: 'Te mencionó en un comentario del hilo #ArquitecturaFrontend',
      quote:
          '¿Qué opinas de esta arquitectura modular para optimizar las '
          're-renderizaciones en chats masivos?',
      createdAt: _ago(const Duration(hours: 4)),
    ),
    AppNotification(
      id: '4',
      type: NotificationType.follow,
      actor: 'Marcos Dev',
      title: 'Y 3 personas más comenzaron a seguirte',
      createdAt: _ago(const Duration(hours: 9)),
    ),
    AppNotification(
      id: '5',
      type: NotificationType.like,
      actor: 'Comunidad Nexo',
      title: 'A 142 personas les gustó tu publicación sobre Design Tokens',
      detail: '+139 creadores',
      createdAt: _ago(const Duration(days: 3)),
      read: true,
    ),
    AppNotification(
      id: '6',
      type: NotificationType.moderation,
      actor: 'Trust & Safety',
      title: 'Se resolvió un reporte en tu último directo',
      createdAt: _ago(const Duration(days: 9)),
      read: true,
    ),
  ];

  void filterBy(NotificationType? type) => emit(
    type == null
        ? state.copyWith(clearFilter: true)
        : state.copyWith(filter: type),
  );

  void markRead(String id) => emit(
    state.copyWith(
      items: [
        for (final item in state.items)
          item.id == id ? item.copyWith(read: true) : item,
      ],
    ),
  );

  /// Marca todas, no sólo las visibles: con un filtro activo, saltar las
  /// ocultas deja un badge que el usuario cree haber limpiado.
  void markAllRead() => emit(
    state.copyWith(
      items: [for (final item in state.items) item.copyWith(read: true)],
    ),
  );

  void toggleReminder() {
    final featured = state.featured;
    if (featured == null) return;
    emit(
      state.copyWith(
        featured: featured.copyWith(reminderSet: !featured.reminderSet),
      ),
    );
  }
}
