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
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../live/domain/entities/live_session.dart';
import '../../../moderation/presentation/bloc/moderation_cubit.dart';
import '../../../moderation/presentation/widgets/report_queue.dart';
import '../../domain/entities/audit_entry.dart';
import '../bloc/admin_console_cubit.dart';
import '../bloc/audit_log_cubit.dart';
import '../utils/admin_ui.dart';
import '../widgets/reason_sheet.dart';

/// Las secciones de la consola. Una consola, no un dashboard: cada una hace
/// algo, y ninguna muestra un número que nadie generó.
enum AdminSection {
  reports('Reportes', Icons.flag_outlined),
  accounts('Cuentas', Icons.people_outline_rounded),
  creators('Creadores', Icons.verified_outlined),
  lives('Vivos', Icons.sensors_rounded),
  audit('Auditoría', Icons.history_rounded);

  const AdminSection(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// La consola del operador. Funciona en teléfono y en escritorio: las
/// "tablas" son listas de tarjetas, así que a 320 bajan de renglón en vez de
/// recortar la columna de acciones.
class AdminConsolePage extends StatelessWidget {
  const AdminConsolePage({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => sl<AdminConsoleCubit>()..load()),
      BlocProvider(create: (_) => sl<ModerationCubit>()..load()),
      BlocProvider(create: (_) => sl<AuditLogCubit>()..load()),
    ],
    child: const _ConsoleView(),
  );
}

class _ConsoleView extends StatefulWidget {
  const _ConsoleView();

  @override
  State<_ConsoleView> createState() => _ConsoleViewState();
}

class _ConsoleViewState extends State<_ConsoleView> {
  var _section = AdminSection.reports;

  void _select(AdminSection section) {
    setState(() => _section = section);
    // La auditoría no escucha en vivo (una tabla que se reordena mientras se
    // lee mueve la fila que se miraba), así que se relee al entrar.
    if (section == AdminSection.audit) {
      final audit = context.read<AuditLogCubit>();
      unawaited(audit.load(audit.state.filter));
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<AdminConsoleCubit, AdminConsoleState>(
        listenWhen: (previous, current) => previous.serial != current.serial,
        listener: (context, state) {
          final message = state.issue?.message ?? state.notice?.message;
          if (message == null || state.isForbidden) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
        builder: (context, state) => NexoPage(
          section: 'Consola',
          title: 'Consola de operador',
          subtitle: 'Cada acción queda registrada con quién, qué y cuándo',
          onRefresh: context.read<AdminConsoleCubit>().load,
          children: [
            if (state.isLoading)
              const FeedSkeleton(count: 2)
            else if (state.isForbidden)
              const _Forbidden()
            else ...[
              _SectionPicker(selected: _section, onSelected: _select),
              const SizedBox(height: AppSpacing.md),
              switch (_section) {
                AdminSection.reports => const ReportQueueSection(
                  showAudit: false,
                ),
                AdminSection.accounts => _AccountsSection(state: state),
                AdminSection.creators => _CreatorsSection(state: state),
                AdminSection.lives => _LivesSection(lives: state.lives),
                AdminSection.audit => const _AuditSection(),
              },
            ],
          ],
        ),
      );
}

/// El servidor dijo que no. Se muestra aunque el guard ya debería haber
/// sacado a esta cuenta: es la prueba de que el permiso no depende de que
/// la ruta esté escondida.
class _Forbidden extends StatelessWidget {
  const _Forbidden();

  @override
  Widget build(BuildContext context) => AppEmptyView(
    icon: Icons.lock_outline_rounded,
    title: 'Acceso restringido',
    message: AdminIssue.forbidden.message,
    actionLabel: 'Volver al inicio',
    onAction: () => context.go(AppRoutes.feed),
  );
}

class _SectionPicker extends StatelessWidget {
  const _SectionPicker({required this.selected, required this.onSelected});

  final AdminSection selected;
  final ValueChanged<AdminSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final pending = context.select<ModerationCubit, int>(
      (cubit) => cubit.state.reports.length,
    );
    // Wrap y no una fila con scroll: cinco secciones a 320 bajan de renglón,
    // y una fila scrolleable esconde justo la última — la auditoría.
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final section in AdminSection.values)
          FilterPill(
            key: Key('admin-section-${section.name}'),
            label: section.label,
            selected: section == selected,
            count: section == AdminSection.reports && pending > 0
                ? pending
                : null,
            onTap: () => onSelected(section),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Cuentas
// -----------------------------------------------------------------------------

class _AccountsSection extends StatelessWidget {
  const _AccountsSection({required this.state});

  final AdminConsoleState state;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SearchField(
        key: const Key('admin-account-search'),
        hint: 'Buscar por correo, usuario o id',
        onChanged: (query) =>
            unawaited(context.read<AdminConsoleCubit>().search(query)),
      ),
      const SizedBox(height: AppSpacing.md),
      if (state.accounts.isEmpty)
        Text(
          'Ninguna cuenta coincide con "${state.query}".',
          style: Theme.of(context).textTheme.bodySmall,
        )
      else
        for (final (index, user) in state.accounts.indexed)
          EnterStatic(
            key: ValueKey(user.id),
            index: index,
            child: _AccountTile(user: user),
          ),
    ],
  );
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: InkWell(
      key: Key('account-${user.username}'),
      borderRadius: AppRadii.medium,
      // push y no go: la ficha vive en el mismo branch, y volver tiene que
      // devolver a la búsqueda con lo que se había escrito.
      onTap: () => unawaited(context.push(AppRoutes.adminAccount(user.id))),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            UserAvatar(name: user.name, size: 40),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  AccountBadges(user: user),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Rol, estado y verificación. Un `Wrap`: tres insignias en una fila no
/// entran a 320, y lo que se recortaría es justo el estado de la cuenta.
class AccountBadges extends StatelessWidget {
  const AccountBadges({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.xxs,
    runSpacing: AppSpacing.xxs,
    children: [
      StatusBadge(
        label: user.role.label.toUpperCase(),
        color: AppColors.primarySurface,
        foreground: AppColors.textOnBrandSurface,
      ),
      if (!user.isActive)
        StatusBadge(
          label: user.status.label.toUpperCase(),
          color: user.status.color,
        ),
      if (user.isCreator)
        StatusBadge(
          label: user.verification.label.toUpperCase(),
          color: user.verification.color,
          icon: user.isVerified ? Icons.verified_rounded : null,
        ),
    ],
  );
}

// -----------------------------------------------------------------------------
// Creadores
// -----------------------------------------------------------------------------

class _CreatorsSection extends StatelessWidget {
  const _CreatorsSection({required this.state});

  final AdminConsoleState state;

  Future<void> _toggle(BuildContext context, AppUser creator) async {
    final cubit = context.read<AdminConsoleCubit>();
    if (!creator.isVerified) {
      await cubit.setVerification(creator, verified: true);
      return;
    }
    final reason = await showReasonSheet(
      context,
      title: 'Revocar verificación',
      detail:
          '@${creator.username} no podrá iniciar vivos hasta que se le '
          'vuelva a otorgar.',
      confirmLabel: 'Revocar verificación',
    );
    if (reason == null) return;
    await cubit.setVerification(creator, verified: false, reason: reason);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'La verificación es lo que permite iniciar un vivo. Revocarla lo '
        'impide desde el servidor, aunque el creador vea el botón.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: AppSpacing.sm),
      if (state.creators.isEmpty)
        Text(
          'No hay creadores registrados.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      for (final creator in state.creators)
        Card(
          key: Key('creator-${creator.username}'),
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UserAvatar(name: creator.name, size: 36),
                    const SizedBox(width: AppSpacing.xs),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '@${creator.username}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        StatusBadge(
                          label: creator.verification.label.toUpperCase(),
                          color: creator.verification.color,
                          icon: creator.isVerified
                              ? Icons.verified_rounded
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
                creator.isVerified
                    ? OutlinedButton(
                        key: Key('revoke-${creator.username}'),
                        onPressed: () => unawaited(_toggle(context, creator)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          minimumSize: const Size(
                            0,
                            AppSizes.buttonHeightDense,
                          ),
                        ),
                        child: const Text('Revocar'),
                      )
                    : FilledButton(
                        key: Key('verify-${creator.username}'),
                        onPressed: () => unawaited(_toggle(context, creator)),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(
                            0,
                            AppSizes.buttonHeightDense,
                          ),
                        ),
                        child: const Text('Verificar'),
                      ),
              ],
            ),
          ),
        ),
    ],
  );
}

// -----------------------------------------------------------------------------
// Vivos
// -----------------------------------------------------------------------------

class _LivesSection extends StatelessWidget {
  const _LivesSection({required this.lives});

  final List<LiveSession> lives;

  Future<void> _end(BuildContext context, LiveSession live) async {
    final cubit = context.read<AdminConsoleCubit>();
    final reason = await showReasonSheet(
      context,
      title: 'Finalizar vivo',
      detail:
          '"${live.title}" se corta para toda la audiencia. La sala le dirá '
          'que lo terminó el equipo de Nexo.',
      confirmLabel: 'Finalizar ahora',
    );
    if (reason == null) return;
    await cubit.forceEndLive(live, reason);
  }

  @override
  Widget build(BuildContext context) {
    if (lives.isEmpty) {
      return Text(
        'No hay vivos al aire en este momento.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final live in lives)
          Card(
            key: Key('admin-live-${live.id}'),
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xxs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const StatusBadge(label: 'EN VIVO', pulse: true),
                      Text(
                        '${live.viewers} espectadores',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    live.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    live.hostName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.icon(
                    key: Key('force-end-${live.id}'),
                    onPressed: () => unawaited(_end(context, live)),
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: const Text('Finalizar vivo'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      minimumSize: const Size(0, AppSizes.buttonHeightDense),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Auditoría
// -----------------------------------------------------------------------------

class _AuditSection extends StatelessWidget {
  const _AuditSection();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AuditLogCubit, AuditLogState>(
        builder: (context, state) {
          final cubit = context.read<AuditLogCubit>();
          final filter = state.filter;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SearchField(
                key: const Key('audit-actor'),
                hint: 'Filtrar por actor (@usuario)',
                onChanged: (actor) => unawaited(
                  cubit.load(
                    AuditFilter(
                      actor: actor,
                      entity: filter.entity,
                      action: filter.action,
                      since: filter.since,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  FilterPill(
                    label: 'Todo',
                    selected: filter.entity == null,
                    onTap: () =>
                        unawaited(cubit.load(AuditFilter(actor: filter.actor))),
                  ),
                  for (final entity in AuditEntity.values)
                    FilterPill(
                      key: Key('audit-entity-${entity.name}'),
                      label: entity.label,
                      selected: filter.entity == entity,
                      onTap: () => unawaited(
                        cubit.load(
                          AuditFilter(actor: filter.actor, entity: entity),
                        ),
                      ),
                    ),
                  FilterPill(
                    label: 'Últimas 24 h',
                    selected: filter.since != null,
                    onTap: () => unawaited(
                      cubit.load(
                        AuditFilter(
                          actor: filter.actor,
                          entity: filter.entity,
                          since: filter.since == null
                              ? DateTime.now().subtract(
                                  const Duration(hours: 24),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (state.isLoading)
                const FeedSkeleton(count: 1)
              else if (state.issue != null)
                AppErrorView(onRetry: () => unawaited(cubit.load(filter)))
              else if (state.entries.isEmpty)
                Text(
                  filter.isEmpty
                      ? 'Todavía no hay acciones registradas.'
                      : 'Ninguna acción coincide con el filtro.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else ...[
                for (final entry in state.entries) AuditEntryTile(entry: entry),
                if (state.hasMore)
                  TextButton(
                    onPressed: state.isLoadingMore
                        ? null
                        : () => unawaited(cubit.loadMore()),
                    child: const Text('Cargar más'),
                  ),
              ],
            ],
          );
        },
      );
}

/// Una fila de auditoría en dos renglones: qué y sobre quién, y quién y
/// cuándo. Seis columnas no entran en un teléfono; dos renglones sí.
class AuditEntryTile extends StatelessWidget {
  const AuditEntryTile({super.key, required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) => Padding(
    key: Key('audit-${entry.id}'),
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.verified_user_outlined,
          size: 17,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.action.label} · ${entry.target}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                [
                  entry.actor,
                  if (entry.reason != null) entry.reason!.label,
                  RelativeTime.format(entry.createdAt),
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
