import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/layout/nexo_page.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/nexo_mascot.dart';
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
    create: (_) => sl<ActivityCubit>()..load(),
    child: const _ActivityView(),
  );
}

class _ActivityView extends StatelessWidget {
  const _ActivityView();

  /// Tocar un aviso lo marca leído y lleva a lo que nombra. La navegación la
  /// decide la View: el estado es dato, nunca una orden de ir a algún lado.
  void _open(BuildContext context, AppNotification item) {
    unawaited(context.read<ActivityCubit>().markRead(item.id));
    switch (item.destination) {
      case NotificationDestination.live:
        // `go`, no `push`: la sala vive en el branch de Explorar, y empujarla
        // desde Actividad la dejaría en un Navigator que no está en pantalla.
        context.go(AppRoutes.liveRoom(item.showId!));
      case NotificationDestination.actorProfile:
        // El perfil ajeno es una ruta raíz sobre el shell: se apila.
        unawaited(context.push(AppRoutes.profileOf(item.actorUsername!)));
      case NotificationDestination.post:
        // La publicación es una ruta raíz sobre el shell: se apila.
        unawaited(context.push(AppRoutes.post(item.postId!)));
      case NotificationDestination.ownProfile:
        context.go(AppRoutes.profile);
      case null:
        break;
    }
  }

  static String _issueMessage(ActivityIssue issue) => switch (issue) {
    ActivityIssue.markFailed =>
      'No pudimos marcar la actividad como leída. Inténtalo de nuevo.',
    ActivityIssue.loadMoreFailed =>
      'No pudimos cargar la actividad anterior. Inténtalo de nuevo.',
  };

  @override
  Widget build(BuildContext context) =>
      BlocListener<ActivityCubit, ActivityState>(
        listenWhen: (previous, current) =>
            current.issue != null &&
            previous.issueSerial != current.issueSerial,
        listener: (context, state) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_issueMessage(state.issue!)))),
        child: BlocBuilder<ActivityCubit, ActivityState>(
          builder: (context, state) {
            final cubit = context.read<ActivityCubit>();
            return NexoPage(
              section: 'Actividad',
              title: 'Actividad',
              subtitle: 'Mantente al tanto de tus creadores y comunidad',
              onRefresh: cubit.load,
              titleActions: [
                if (state.unreadCount > 0)
                  TextButton(
                    key: const Key('activity-mark-all'),
                    onPressed: () => unawaited(cubit.markAllRead()),
                    child: const Text('Marcar leídas'),
                  ),
              ],
              children: switch (state.status) {
                ActivityStatus.loading => const [_ActivitySkeleton()],
                ActivityStatus.failure => [AppErrorView(onRetry: cubit.load)],
                ActivityStatus.ready => _content(context, state, cubit),
              },
            );
          },
        ),
      );

  List<Widget> _content(
    BuildContext context,
    ActivityState state,
    ActivityCubit cubit,
  ) => [
    _FilterRow(selected: state.filter, onSelected: cubit.filterBy),
    if (state.reconnecting) ...[
      const SizedBox(height: AppSpacing.xs),
      const Align(
        alignment: Alignment.centerLeft,
        child: StatusBadge(
          key: Key('activity-reconnecting'),
          label: 'Reconectando',
          color: AppColors.linerHigh,
          foreground: AppColors.textSecondary,
        ),
      ),
    ],
    if (state.featured != null && state.filter == null) ...[
      const SizedBox(height: AppSpacing.lg),
      // Sólo aparece: lleva el CTA del recordatorio, y una traslación dejaría
      // el hit test corrido mientras dura.
      EnterStatic(
        child: FeaturedActivityCard(
          featured: state.featured!,
          onToggleReminder: cubit.toggleReminder,
        ),
      ),
    ],
    if (state.visible.isEmpty)
      state.filter == null
          ? AppEmptyView(
              mascot: NexoMascot.bell,
              title: 'Todo tranquilo',
              message:
                  'Cuando alguien te siga, reaccione a lo que publicas o '
                  'salga en vivo, aparece aquí.',
              actionLabel: 'Explorar',
              onAction: () => context.go(AppRoutes.explore),
            )
          : AppEmptyView(
              mascot: NexoMascot.bell,
              title: 'Nada por aquí',
              message: 'No hay actividad para este filtro.',
              actionLabel: 'Ver todo',
              onAction: () => cubit.filterBy(null),
            )
    else
      ..._buckets(context, state),
    if (state.hasMore)
      Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        // Cargando más, la forma de lo que viene y no un spinner: una
        // ruedita al pie de una lista se lee igual cuando tarda que cuando
        // se colgó.
        child: state.loadingMore
            ? const _ActivitySkeleton(rows: 2, withFilters: false)
            : Center(
                child: OutlinedButton(
                  key: const Key('activity-load-more'),
                  onPressed: () => unawaited(cubit.loadMore()),
                  child: const Text('Ver anteriores'),
                ),
              ),
      ),
    const SizedBox(height: AppSpacing.md),
  ];

  List<Widget> _buckets(BuildContext context, ActivityState state) {
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
          // Un contador en vinilo lima con tinta: es una cuenta, no una
          // alerta, y el rojo es la marca de en vivo.
          action: unread > 0
              ? StatusBadge(
                  label: '$unread nuevas',
                  color: AppColors.vinylLime,
                  foreground: AppColors.ink,
                )
              : null,
        ),
      );
      for (final (position, item) in items.indexed) {
        if (position > 0) widgets.add(const Divider(height: 1));
        widgets.add(
          // Sólo aparece: la fila entera se toca.
          EnterStatic(
            key: ValueKey(item.id),
            index: index++,
            child: _NotificationRow(
              notification: item,
              onTap: () => _open(context, item),
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

/// Un aviso, plano sobre el liner. Las filas se separan por filetes: una
/// bandeja es una lista densa, y una tarjeta por aviso la convertía en una
/// pila de cajas.
class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final action = notification.actionLabel;
    final unread = !notification.read;
    final badge = notification.type.badge;
    return InkWell(
      key: Key('activity-${notification.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
                  // siguiente. Compartiendo línea, la insignia le come el
                  // ancho al nombre y lo trunca — y el nombre es lo que
                  // identifica de quién es el aviso.
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.actorLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        RelativeTime.format(notification.createdAt),
                        style: text.bodySmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          key: Key('activity-unread-${notification.id}'),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (badge != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StatusBadge(
                        label: badge,
                        color: notification.type.color,
                        foreground: notification.type.foreground,
                        pulse:
                            notification.type == NotificationType.liveReminder,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  // Sin leer se distingue por el punto **y** por el peso y el
                  // tono del texto. Sólo el color dejaría todo el significado
                  // en algo invisible para quien no separa los dos tonos.
                  Text(
                    notification.sentence,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      color: unread
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (notification.quote != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _Quote(text: notification.quote!),
                  ],
                  if (action != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    OutlinedButton(
                      key: Key('activity-action-${notification.id}'),
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, AppSizes.buttonHeightDense),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        textStyle: text.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(action),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar del actor con el disco del tipo de evento pegado encima.
///
/// El disco va sobre el avatar y no en una columna propia: con siete tipos,
/// una columna de íconos convierte la lista en una tabla.
class _ActorAvatar extends StatelessWidget {
  const _ActorAvatar({required this.notification});

  final AppNotification notification;

  /// El lugar del avatar. Al aire el foil suma su anillo alrededor del
  /// sticker, así que la cara se achica para que todas las filas alineen el
  /// texto en la misma columna.
  static const _slot = 48.0;

  @override
  Widget build(BuildContext context) {
    final onAir = notification.type == NotificationType.liveReminder;
    return SizedBox.square(
      dimension: _slot,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: UserAvatar(
              name: notification.actorLabel,
              imageUrl: notification.actorAvatarUrl,
              size: onAir ? 40 : 44,
              onAir: onAir,
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: _TypeDisc(type: notification.type),
          ),
        ],
      ),
    );
  }
}

/// El tipo de aviso como un sticker chico: glifo de tinta sobre el vinilo del
/// tipo, con su troquel blanco, y un aro del liner que lo despega del avatar
/// (pegado al troquel del avatar, los dos blancos se fundían en uno).
class _TypeDisc extends StatelessWidget {
  const _TypeDisc({required this.type});

  final NotificationType type;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(1.5),
    decoration: const BoxDecoration(
      color: AppColors.background,
      shape: BoxShape.circle,
    ),
    child: Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: AppColors.sticker,
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 18,
        height: 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: type.color, shape: BoxShape.circle),
        child: NexoIcon(
          type.glyph,
          filled: true,
          size: 11,
          color: AppColors.ink,
        ),
      ),
    ),
  );
}

/// El comentario citado, en su propia superficie: dentro de la frase no se
/// distinguiría del evento.
class _Quote extends StatelessWidget {
  const _Quote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: const BoxDecoration(
      color: AppColors.linerHigh,
      borderRadius: AppRadii.medium,
    ),
    child: Text(
      '“$text”',
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
    ),
  );
}

/// La carga con la forma de la bandeja: filtros, y filas de avatar y dos
/// líneas separadas por filetes. Un esqueleto de post con media le
/// prometería a la pantalla un contenido que no va a tener.
class _ActivitySkeleton extends StatelessWidget {
  const _ActivitySkeleton({this.rows = 5, this.withFilters = true});

  final int rows;
  final bool withFilters;

  @override
  Widget build(BuildContext context) => PulsingSkeleton(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (withFilters) ...[
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final width in [56.0, 88.0, 104.0])
                ClipRRect(
                  borderRadius: AppRadii.pill,
                  child: AppSkeleton(width: width, height: AppSizes.chipHeight),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const AppSkeleton(width: 72, height: 20),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (var index = 0; index < rows; index++) ...[
          if (index > 0) const Divider(height: 1),
          const _SkeletonRow(),
        ],
      ],
    ),
  );
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipOval(child: AppSkeleton(width: 44, height: 44)),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton(width: 120, height: 14),
              SizedBox(height: 6),
              AppSkeleton(height: 12),
              SizedBox(height: AppSpacing.xxs),
              AppSkeleton(width: 140, height: 12),
            ],
          ),
        ),
      ],
    ),
  );
}
