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
  reports('Reportes', NexoGlyph.flag),
  accounts('Cuentas', NexoGlyph.profile),
  creators('Creadores', NexoGlyph.verified),
  lives('Vivos', NexoGlyph.live),
  audit('Auditoría', NexoGlyph.clock);

  const AdminSection(this.label, this.glyph);

  final String label;
  final NexoGlyph glyph;
}

/// La consola del operador. Funciona en teléfono y en escritorio: las
/// "tablas" son filas sobre el liner, así que a 320 bajan de renglón en vez
/// de recortar la columna de acciones.
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
              const AdminRowsSkeleton(rows: 4)
            else if (state.isForbidden)
              const _Forbidden()
            else ...[
              _SectionPicker(
                selected: _section,
                onSelected: _select,
                lives: state.lives.length,
                creators: state.creators.length,
              ),
              const SizedBox(height: AppSpacing.lg),
              switch (_section) {
                AdminSection.reports => const ReportQueueSection(
                  showAudit: false,
                ),
                AdminSection.accounts => _AccountsSection(state: state),
                AdminSection.creators => _CreatorsSection(state: state),
                AdminSection.lives => _LivesSection(lives: state.lives),
                AdminSection.audit => const _AuditSection(),
              },
              const SizedBox(height: AppSpacing.xl),
              const _ResetDemo(),
            ],
          ],
        ),
      );
}

/// Vuelve la demo a la semilla, para grabar el recorrido otra vez (SDD 0007,
/// F13). Pide confirmación: borra sanciones y auditoría de la consola.
///
/// Es destructivo, así que va contorneado en rojo y nunca como sticker
/// blanco: el sticker blanco es la acción segura de la pantalla.
class _ResetDemo extends StatelessWidget {
  const _ResetDemo();

  Future<void> _confirm(BuildContext context) async {
    final cubit = context.read<AdminConsoleCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Reiniciar los datos de la demo?'),
        content: Text(
          'Las cuentas, las sanciones, los reportes del chat y la auditoría '
          'de la consola vuelven a su estado inicial. Las publicaciones y las '
          'cuentas del servidor no cambian.',
          style: Theme.of(
            dialogContext,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('admin-reset-demo-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            style: AdminButtons.destructiveFill,
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.resetDemo();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Divider(),
      const SizedBox(height: AppSpacing.md),
      Text(
        'Vuelve cuentas, sanciones y auditoría a su estado inicial para '
        'grabar el recorrido otra vez.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: AppSpacing.sm),
      OutlinedButton(
        key: const Key('admin-reset-demo'),
        onPressed: () => unawaited(_confirm(context)),
        style: AdminButtons.destructiveOutline,
        child: const Text('Reiniciar datos de la demo'),
      ),
    ],
  );
}

/// El servidor dijo que no. Se muestra aunque el guard ya debería haber
/// sacado a esta cuenta: es la prueba de que el permiso no depende de que
/// la ruta esté escondida.
class _Forbidden extends StatelessWidget {
  const _Forbidden();

  @override
  Widget build(BuildContext context) => AppEmptyView(
    mascot: NexoMascot.lock,
    title: 'Acceso restringido',
    message: AdminIssue.forbidden.message,
    actionLabel: 'Volver al inicio',
    onAction: () => context.go(AppRoutes.feed),
  );
}

class _SectionPicker extends StatelessWidget {
  const _SectionPicker({
    required this.selected,
    required this.onSelected,
    required this.lives,
    required this.creators,
  });

  final AdminSection selected;
  final ValueChanged<AdminSection> onSelected;
  final int lives;
  final int creators;

  /// La cuenta de cada sección va en su chip, no en una franja de cifras
  /// aparte: el número vive junto a lo que se toca para verlo. Cero no se
  /// imprime; un "0" en un chip se lee como un contador roto.
  int? _countFor(AdminSection section, int pending) {
    final count = switch (section) {
      AdminSection.reports => pending,
      AdminSection.lives => lives,
      AdminSection.creators => creators,
      AdminSection.accounts || AdminSection.audit => 0,
    };
    return count > 0 ? count : null;
  }

  @override
  Widget build(BuildContext context) {
    final pending = context.select<ModerationCubit, int>(
      (cubit) => cubit.state.reports.length,
    );
    // Una sola fila que scrollea, no un Wrap: con las cuentas en los chips,
    // un Wrap a 320 dejaba "Vivos" y "Auditoría" varados en un segundo
    // renglón. Sin recorte, los chips pasan por debajo del margen hasta el
    // borde de la pantalla: en reposo el primero queda alineado con el
    // contenido, y al scrollear la fila llega al borde como una plancha.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (index, section) in AdminSection.values.indexed) ...[
            if (index > 0) const SizedBox(width: AppSpacing.xs),
            FilterPill(
              key: Key('admin-section-${section.name}'),
              label: section.label,
              selected: section == selected,
              count: _countFor(section, pending),
              onTap: () => onSelected(section),
            ),
          ],
        ],
      ),
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
      const SizedBox(height: AppSpacing.sm),
      if (state.accounts.isEmpty)
        _QuietLine(
          glyph: NexoGlyph.search,
          text: 'Ninguna cuenta coincide con "${state.query}".',
        )
      else
        for (final (index, user) in state.accounts.indexed) ...[
          if (index > 0) const _RowDivider(),
          EnterStatic(
            key: ValueKey(user.id),
            index: index,
            child: _AccountTile(user: user),
          ),
        ],
    ],
  );
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: Key('account-${user.username}'),
        borderRadius: AppRadii.medium,
        // push y no go: la ficha vive en el mismo branch, y volver tiene que
        // devolver a la búsqueda con lo que se había escrito.
        onTap: () => unawaited(context.push(AppRoutes.adminAccount(user.id))),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
                      style: text.titleSmall,
                    ),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AccountBadges(user: user),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const NexoIcon(
                NexoGlyph.forward,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Estado, verificación y rol. Un `Wrap`: tres insignias en una fila no
/// entran a 320, y lo que se recortaría es justo el estado de la cuenta.
///
/// El estado va siempre, también "Activa": en una consola la ausencia de una
/// insignia no se lee como "todo bien", se lee como "no cargó".
class AccountBadges extends StatelessWidget {
  const AccountBadges({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.xs,
    runSpacing: AppSpacing.xxs,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      StatusBadge(
        label: user.status.label,
        color: user.status.color,
        foreground: user.status.foreground,
      ),
      if (user.isCreator)
        StatusBadge(
          label: user.verification.label,
          color: user.verification.color,
          foreground: user.verification.foreground,
        ),
      _RoleTag(role: user.role),
    ],
  );
}

/// El rol no es un estado: es el scope de la cuenta. Va impreso en gris y no
/// como insignia, para que el ojo encuentre primero lo que cambia.
///
/// El gris sale del tema y no de un token: sobre el liner es el gris claro,
/// y dentro de un `StickerCard` el tema se da vuelta y pasa a gris tinta.
class _RoleTag extends StatelessWidget {
  const _RoleTag({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NexoIcon(role.glyph, size: 13, color: muted),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          role.label,
          style: theme.textTheme.labelSmall?.copyWith(color: muted),
        ),
      ],
    );
  }
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
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'La verificación es lo que permite iniciar un vivo. Revocarla lo '
          'impide desde el servidor, aunque el creador vea el botón.',
          style: text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.creators.isEmpty)
          const _QuietLine(
            glyph: NexoGlyph.verified,
            text: 'No hay creadores registrados.',
          ),
        for (final (index, creator) in state.creators.indexed) ...[
          if (index > 0) const _RowDivider(),
          Padding(
            key: Key('creator-${creator.username}'),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                UserAvatar(name: creator.name, size: 40),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${creator.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      StatusBadge(
                        label: creator.verification.label,
                        color: creator.verification.color,
                        foreground: creator.verification.foreground,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Revocar es destructivo: contorno rojo. Verificar es la
                // acción segura de la fila: el sticker blanco.
                creator.isVerified
                    ? OutlinedButton(
                        key: Key('revoke-${creator.username}'),
                        onPressed: () => unawaited(_toggle(context, creator)),
                        style: AdminButtons.destructiveOutline,
                        child: const Text('Revocar'),
                      )
                    : FilledButton(
                        key: Key('verify-${creator.username}'),
                        onPressed: () => unawaited(_toggle(context, creator)),
                        style: AdminButtons.safe,
                        child: const Text('Verificar'),
                      ),
              ],
            ),
          ),
        ],
      ],
    );
  }
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
      return const _QuietLine(
        glyph: NexoGlyph.live,
        text: 'No hay vivos al aire en este momento.',
      );
    }
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, live) in lives.indexed) ...[
          if (index > 0) const _RowDivider(),
          Padding(
            key: Key('admin-live-${live.id}'),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Al aire: el holo es la marca de "está pasando ahora".
                UserAvatar(name: live.hostName, size: 40, onAir: true),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
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
                            style: text.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(live.title, style: text.titleSmall),
                      Text(live.hostName, style: text.bodySmall),
                      const SizedBox(height: AppSpacing.sm),
                      FilledButton(
                        key: Key('force-end-${live.id}'),
                        onPressed: () => unawaited(_end(context, live)),
                        style: AdminButtons.destructiveFill,
                        child: const Text('Finalizar vivo'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
              const SizedBox(height: AppSpacing.lg),
              if (state.isLoading)
                const AdminRowsSkeleton()
              else if (state.issue != null)
                AppErrorView(onRetry: () => unawaited(cubit.load(filter)))
              else if (state.entries.isEmpty)
                _QuietLine(
                  glyph: NexoGlyph.clock,
                  text: filter.isEmpty
                      ? 'Todavía no hay acciones registradas.'
                      : 'Ninguna acción coincide con el filtro.',
                )
              else ...[
                for (final (index, entry) in state.entries.indexed)
                  AuditEntryTile(
                    entry: entry,
                    isLast: !state.hasMore && index == state.entries.length - 1,
                  ),
                if (state.hasMore)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: state.isLoadingMore
                          ? null
                          : () => unawaited(cubit.loadMore()),
                      child: const Text('Cargar más'),
                    ),
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
  const AuditEntryTile({super.key, required this.entry, this.isLast = false});

  final AuditEntry entry;

  /// La última fila no dibuja el hilo hacia abajo: no hay nada después.
  final bool isLast;

  @override
  Widget build(BuildContext context) => AdminTimelineNode(
    key: Key('audit-${entry.id}'),
    glyph: entry.action.glyph,
    filled: entry.action.glyphFilled,
    tone: entry.action.tone,
    title: '${entry.action.label} · ${entry.target}',
    meta: [
      entry.actor,
      if (entry.reason != null) entry.reason!.label,
      RelativeTime.format(entry.createdAt),
    ].join(' · '),
    isLast: isLast,
  );
}

// -----------------------------------------------------------------------------
// Piezas compartidas con la ficha de cuenta
// -----------------------------------------------------------------------------

/// Un nodo de la línea de tiempo de la consola: el glifo en su ficha redonda,
/// el hilo hacia el siguiente y dos renglones de texto. Va directo sobre el
/// liner: un registro de auditoría hecho de tarjetas se lee como una pila de
/// avisos, no como una secuencia.
class AdminTimelineNode extends StatelessWidget {
  const AdminTimelineNode({
    super.key,
    required this.glyph,
    required this.title,
    required this.meta,
    this.tone = AppColors.textSecondary,
    this.filled = false,
    this.badge,
    this.isLast = false,
  });

  final NexoGlyph glyph;
  final String title;
  final String meta;
  final Color tone;
  final bool filled;

  /// Insignia junto al título, como "Vigente". Baja de renglón si no entra.
  final Widget? badge;
  final bool isLast;

  static const _node = 30.0;
  static const _thread = 1.5;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Stack(
      children: [
        if (!isLast)
          const Positioned(
            top: _node + AppSpacing.xxs,
            bottom: 0,
            left: (_node - _thread) / 2,
            width: _thread,
            child: ColoredBox(color: AppColors.border),
          ),
        Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: _node,
                height: _node,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.linerHigh,
                  shape: BoxShape.circle,
                ),
                child: NexoIcon(glyph, size: 15, color: tone, filled: filled),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xxs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(title, style: text.titleSmall),
                          ?badge,
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        style: text.bodySmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// La carga de la consola, con la forma de sus filas: avatar y dos
/// renglones. El esqueleto del feed dibuja un post con media, y una consola
/// que carga mostrando posts promete otra pantalla.
class AdminRowsSkeleton extends StatelessWidget {
  const AdminRowsSkeleton({super.key, this.rows = 3});

  final int rows;

  @override
  Widget build(BuildContext context) => PulsingSkeleton(
    child: Column(
      children: [
        for (var index = 0; index < rows; index++)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                ClipOval(child: AppSkeleton(height: 40, width: 40)),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeleton(width: 140, height: 14),
                      SizedBox(height: 6),
                      AppSkeleton(width: 90, height: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// Una línea en gris con su glifo: lo que se dice cuando una lista está
/// vacía dentro de una sección. Más chico que un estado vacío con el gato,
/// porque la sección sigue siendo útil (el buscador, los filtros).
class _QuietLine extends StatelessWidget {
  const _QuietLine({required this.glyph, required this.text});

  final NexoGlyph glyph;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NexoIcon(glyph, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}

/// Filete entre filas, alineado con el texto y no con el avatar.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 40 + AppSpacing.sm);
}
