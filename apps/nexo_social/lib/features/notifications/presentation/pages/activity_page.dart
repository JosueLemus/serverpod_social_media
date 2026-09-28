import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/layout/nexo_page.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/app_notification.dart';
import '../bloc/activity_cubit.dart';
import '../utils/notification_type_ui.dart';
import '../widgets/featured_activity_card.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ActivityCubit(),
    child: const _ActivityView(),
  );
}

class _ActivityView extends StatelessWidget {
  const _ActivityView();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ActivityCubit, ActivityState>(
        builder: (context, state) {
          final cubit = context.read<ActivityCubit>();
          return NexoPage(
            section: 'Actividad',
            title: 'Actividad',
            subtitle: 'Mantente al tanto de tus creadores y comunidad',
            titleActions: [
              if (state.unreadCount > 0)
                TextButton.icon(
                  key: const Key('activity-mark-all'),
                  onPressed: cubit.markAllRead,
                  icon: const Icon(Icons.done_all_rounded, size: 17),
                  label: const Text('Leídas'),
                ),
            ],
            children: [
              _FilterRow(selected: state.filter, onSelected: cubit.filterBy),
              if (state.featured != null && state.filter == null) ...[
                const SizedBox(height: AppSpacing.md),
                Enter(
                  child: FeaturedActivityCard(
                    featured: state.featured!,
                    onToggleReminder: cubit.toggleReminder,
                  ),
                ),
              ],
              if (state.visible.isEmpty)
                AppEmptyView(
                  icon: Icons.notifications_none_rounded,
                  title: 'Nada por aquí',
                  message: 'No hay actividad para este filtro.',
                  actionLabel: 'Ver todo',
                  onAction: () => cubit.filterBy(null),
                )
              else
                ..._buckets(context, state, cubit),
              const SizedBox(height: AppSpacing.md),
            ],
          );
        },
      );

  List<Widget> _buckets(
    BuildContext context,
    ActivityState state,
    ActivityCubit cubit,
  ) {
    // Un índice corrido entre franjas: el escalonado se lee como una sola
    // secuencia y no como tres que arrancan de nuevo.
    var index = 0;
    final widgets = <Widget>[];

    for (final bucket in ActivityBucket.values) {
      final items = state.inBucket(bucket);
      if (items.isEmpty) continue;

      final unread = state.unreadIn(bucket);
      widgets.add(
        SectionHeader(
          title: bucket.label,
          hint: unread > 0 ? '$unread nuevas' : null,
        ),
      );
      for (final item in items) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Enter(
              key: ValueKey(item.id),
              index: index++,
              child: _NotificationTile(
                notification: item,
                onTap: () => cubit.markRead(item.id),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onSelected});

  final NotificationType? selected;
  final ValueChanged<NotificationType?> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppSizes.chipHeight,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        FilterPill(
          key: const Key('activity-filter-all'),
          label: 'Todo',
          selected: selected == null,
          onTap: () => onSelected(null),
        ),
        for (final type in NotificationType.values) ...[
          const SizedBox(width: AppSpacing.xs),
          FilterPill(
            key: Key('activity-filter-${type.name}'),
            // La etiqueta del enum, nunca `type.name`: eso imprime el
            // identificador de Dart ("liveReminder") en la pantalla.
            label: type.label,
            selected: selected == type,
            onTap: () => onSelected(type),
          ),
        ],
      ],
    ),
  );
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    // Sin leer se distingue por superficie **y** por el punto. Sólo el color
    // dejaría todo el significado en algo invisible para quien no separa
    // estos dos azules.
    color: notification.read ? AppColors.surface : AppColors.primarySurface,
    child: InkWell(
      key: Key('activity-${notification.id}'),
      onTap: onTap,
      borderRadius: AppRadii.medium,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActorAvatar(notification: notification),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y hora en una línea; la insignia baja a la
                  // siguiente junto al detalle. Compartiendo línea, la
                  // insignia le come el ancho al nombre y lo trunca — y el
                  // nombre es lo que identifica de quién es la notificación.
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.actor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        RelativeTime.format(notification.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (!notification.read) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryDeep,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (notification.type.badge != null) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StatusBadge(
                        label: notification.type.badge!,
                        color: notification.type.color,
                        pulse:
                            notification.type == NotificationType.liveReminder,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    notification.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.35,
                      fontWeight: notification.read
                          ? FontWeight.w400
                          : FontWeight.w500,
                    ),
                  ),
                  if (notification.quote != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _Quote(text: notification.quote!),
                  ],
                  if (notification.detail != null ||
                      notification.type.actionLabel != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        if (notification.detail != null)
                          Expanded(
                            child: Text(
                              notification.detail!,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          )
                        else
                          const Spacer(),
                        if (notification.type.actionLabel != null)
                          SizedBox(
                            height: 32,
                            child: OutlinedButton(
                              key: Key('activity-action-${notification.id}'),
                              onPressed: onTap,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 32),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: Text(notification.type.actionLabel!),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Avatar del actor con una insignia del tipo de evento.
///
/// La insignia va sobre el avatar y no en una columna propia: con seis tipos,
/// una columna de íconos convierte la lista en una tabla.
class _ActorAvatar extends StatelessWidget {
  const _ActorAvatar({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      UserAvatar(name: notification.actor, size: 42),
      Positioned(
        right: -2,
        bottom: -2,
        child: Container(
          width: 19,
          height: 19,
          decoration: BoxDecoration(
            color: notification.type.color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surface, width: 2),
          ),
          child: Icon(notification.type.icon, size: 10, color: Colors.white),
        ),
      ),
    ],
  );
}

class _Quote extends StatelessWidget {
  const _Quote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.xs),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadii.small,
      border: Border.all(color: AppColors.border),
    ),
    child: Text(
      '"$text"',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontStyle: FontStyle.italic,
        color: AppColors.textPrimary,
        height: 1.35,
      ),
    ),
  );
}
