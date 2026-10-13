import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/nexo_mascot.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/sticker.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/moderation_action.dart';
import '../bloc/moderation_cubit.dart';

/// La cola de reportes y su auditoría. La usan la pantalla del moderador y la
/// consola del operador: una sola cola, así las dos resuelven igual.
///
/// Es una `Column` y no una lista: vive dentro de un `NexoPage`, que ya es el
/// scroll, y un scrollable adentro de otro no tiene altura acotada.
class ReportQueueSection extends StatelessWidget {
  const ReportQueueSection({super.key, this.showAudit = true});

  final bool showAudit;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ModerationCubit, ModerationState>(
        builder: (context, state) {
          if (state.isLoading) return const FeedSkeleton(count: 2);
          // Sin cola que mostrar, un fallo de lectura no es "no hay
          // reportes": es la pantalla de error, con su reintento.
          final loadIssue = state.loadIssue;
          if (state.failedToLoad) return _LoadFailed(issue: loadIssue!);
          final actionIssue = state.actionIssue;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (loadIssue != null)
                _IssueBanner(
                  key: const Key('moderation-stale'),
                  message: _staleMessage(loadIssue),
                ),
              if (actionIssue != null)
                _IssueBanner(
                  key: const Key('moderation-issue'),
                  message: _actionMessage(actionIssue),
                ),
              _SectionTitle(
                'Cola de reportes',
                glyph: NexoGlyph.flag,
                count: state.reports.length,
              ),
              if (state.reports.isEmpty)
                const _EmptyQueue()
              else
                for (final (index, report) in state.reports.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    // Sólo aparece: la tarjeta lleva los botones con los que se
                    // resuelve, y una traslación dejaría el hit test corrido
                    // mientras dura.
                    child: EnterStatic(
                      key: ValueKey(report.id),
                      index: index,
                      child: _ReportCard(report: report),
                    ),
                  ),
              if (showAudit) ...[
                const SizedBox(height: AppSpacing.lg),
                const _SectionTitle(
                  'Registro de auditoría',
                  glyph: NexoGlyph.moderation,
                  detail:
                      'Cada acción queda registrada con quién, qué y cuándo.',
                ),
                if (state.actions.isEmpty)
                  Text(
                    'Todavía no se ha registrado ninguna acción.',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  for (final (index, action) in state.actions.indexed) ...[
                    if (index > 0) const Divider(height: AppSpacing.md),
                    _AuditRow(action: action),
                  ],
              ],
            ],
          );
        },
      );
}

/// Lo que se le dice al moderador cuando una acción no se aplicó.
String _actionMessage(ModerationIssue issue) => switch (issue) {
  ModerationIssue.forbidden =>
    'Tu cuenta no tiene permisos para esta acción de moderación.',
  ModerationIssue.conflict =>
    'Ese reporte ya no está abierto: alguien lo resolvió antes.',
  ModerationIssue.other => 'No pudimos completar la acción.',
};

/// Lo que se le dice cuando la relectura falló pero queda la cola anterior.
String _staleMessage(ModerationIssue issue) => switch (issue) {
  ModerationIssue.forbidden =>
    'Tu cuenta ya no tiene permisos de moderación: la cola puede estar '
        'desactualizada.',
  ModerationIssue.conflict || ModerationIssue.other =>
    'No pudimos actualizar la cola. Lo que ves puede estar desactualizado.',
};

/// La cola no se pudo leer y no hay nada anterior que mostrar.
class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.issue});

  final ModerationIssue issue;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ModerationCubit>();
    void retry() => unawaited(cubit.load());
    return KeyedSubtree(
      key: const Key('moderation-load-error'),
      child: issue == ModerationIssue.forbidden
          ? AppEmptyView(
              mascot: NexoMascot.lock,
              title: 'Sin acceso a la cola',
              message:
                  'Tu cuenta no tiene permisos de moderación. Si te los '
                  'acaban de dar, vuelve a intentarlo.',
              actionLabel: 'Reintentar',
              onAction: retry,
            )
          : AppErrorView(onRetry: retry),
    );
  }
}

class _IssueBanner extends StatelessWidget {
  const _IssueBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadii.medium,
      border: Border.all(color: AppColors.error, width: 1.5),
    ),
    child: Row(
      children: [
        const _GlyphDisc(
          NexoGlyph.moderation,
          size: 32,
          background: AppColors.error,
          foreground: AppColors.sticker,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(
    this.label, {
    required this.glyph,
    this.count,
    this.detail,
  });

  final String label;
  final NexoGlyph glyph;
  final int? count;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NexoIcon(glyph, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Flexible(child: Text(label, style: text.titleLarge)),
              if (count != null && count! > 0) ...[
                const SizedBox(width: AppSpacing.xs),
                // Un vinilo con tinta: es un contador, no una alerta, y el
                // rojo con blanco es la marca de en vivo.
                StatusBadge(
                  label: '$count',
                  color: AppColors.vinylLime,
                  foreground: AppColors.ink,
                ),
              ],
            ],
          ),
          if (detail != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(detail!, style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          const MascotIllustration(NexoMascot.shield, size: 128),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No hay reportes pendientes.',
            textAlign: TextAlign.center,
            style: text.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Los reportes nuevos entran solos a la cola.',
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final ModerationReport report;

  /// Cuánto asoma la insignia por encima del borde de la tarjeta.
  static const _badgeOverhang = 10.0;

  @override
  Widget build(BuildContext context) => Stack(
    key: Key('report-${report.id}'),
    clipBehavior: Clip.none,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: _badgeOverhang),
        // Un reporte es un objeto sobre la mesa: el sticker del logo, con el
        // contenido en tinta.
        child: StickerCard(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: _ReportBody(report: report),
        ),
      ),
      // Pegada encima de la esquina, apenas torcida: la severidad es lo
      // primero que se lee del reporte.
      Positioned(
        top: 0,
        left: AppSpacing.md,
        child: _SeverityTag(severity: report.severity, tilt: -.05),
      ),
    ],
  );
}

/// El contenido del reporte. Un widget aparte para leer el tema **dentro** de
/// la [StickerCard], que lo invierte a tinta: leído desde afuera, el texto
/// saldría claro sobre blanco.
class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});

  final ModerationReport report;

  /// Expulsar no se deshace desde la cola: se confirma, nombrando a quién.
  /// En un tap, al lado de "Ocultar", era la sanción más grave a un dedo
  /// de distancia de la más leve.
  Future<void> _confirmBan(BuildContext context) async {
    final cubit = context.read<ModerationCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('¿Expulsar a ${report.author}?'),
        content: Text(
          'La cuenta pierde el acceso a la comunidad y el reporte se cierra. '
          'Queda registrado en la auditoría.',
          style: Theme.of(
            dialogContext,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            key: const Key('ban-cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('ban-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.sticker,
              overlayColor: AppColors.sticker,
            ),
            child: const Text('Expulsar'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.resolve(report, ModerationType.banUser);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ModerationCubit>();
    // Mientras una acción corre, ninguna otra: el primer tap ya decidió.
    final working = context.select<ModerationCubit, bool>(
      (cubit) => cubit.state.isWorking,
    );
    final text = Theme.of(context).textTheme;
    const dense = Size(0, AppSizes.buttonHeightDense);
    const densePadding = EdgeInsets.symmetric(horizontal: AppSpacing.md);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            UserAvatar(name: _handleName(report.author), size: 32),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall,
                  ),
                  Text(
                    '${report.reason.label} · '
                    '${RelativeTime.format(report.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('“${report.content}”', style: text.bodyLarge),
        const SizedBox(height: AppSpacing.md),
        // Wrap, not Row: the buttons and a long author handle overflow a
        // Row on a narrow window, and an overflowing action bar hides the
        // action a moderator needs.
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            // Dentro de la tarjeta el CTA del tema es relleno de tinta.
            FilledButton.icon(
              key: Key('hide-${report.id}'),
              onPressed: working
                  ? null
                  : () => unawaited(
                      cubit.resolve(report, ModerationType.hideComment),
                    ),
              style: FilledButton.styleFrom(
                minimumSize: dense,
                padding: densePadding,
              ),
              icon: const NexoIcon(NexoGlyph.hidden, size: 18),
              label: const Text('Ocultar'),
            ),
            TextButton(
              key: Key('dismiss-${report.id}'),
              onPressed: working
                  ? null
                  : () => unawaited(cubit.dismiss(report)),
              style: TextButton.styleFrom(
                minimumSize: dense,
                padding: densePadding,
              ),
              child: const Text('Descartar'),
            ),
          ],
        ),
        // Sólo donde quien tiene el reporte puede aplicarlo (F10).
        if (report.canSanctionAuthor) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Sancionar al autor',
            style: text.labelSmall?.copyWith(color: AppColors.inkSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OutlinedButton.icon(
                key: Key('mute-${report.id}'),
                onPressed: working
                    ? null
                    : () => unawaited(
                        cubit.resolve(report, ModerationType.muteUser),
                      ),
                style: OutlinedButton.styleFrom(
                  minimumSize: dense,
                  padding: densePadding,
                ),
                icon: const NexoIcon(NexoGlyph.micOff, size: 18),
                label: Text('Silenciar ${MuteDuration.oneDay.label}'),
              ),
              // Destructiva: relleno de error con texto blanco, nunca el
              // relleno del CTA.
              FilledButton.icon(
                key: Key('ban-${report.id}'),
                onPressed: working
                    ? null
                    : () => unawaited(_confirmBan(context)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.sticker,
                  overlayColor: AppColors.sticker,
                  minimumSize: dense,
                  padding: densePadding,
                ),
                icon: const NexoIcon(NexoGlyph.lock, size: 18),
                label: const Text('Expulsar'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// El avatar dibuja la inicial: con el `@` delante, todos saldrían con "@".
  static String _handleName(String handle) =>
      handle.startsWith('@') ? handle.substring(1) : handle;
}

class _SeverityTag extends StatelessWidget {
  const _SeverityTag({required this.severity, this.tilt = 0});

  final ReportSeverity severity;
  final double tilt;

  /// Alta es la única en rojo: es lo que puede dañar a alguien. Las demás van
  /// en vinilo, porque el ámbar promete "cuidado" y una severidad media no es
  /// una advertencia.
  Color get _color => switch (severity) {
    ReportSeverity.high => AppColors.secondary,
    ReportSeverity.medium => AppColors.vinylLime,
    ReportSeverity.low => AppColors.vinylCyan,
  };

  @override
  Widget build(BuildContext context) => StatusBadge(
    label: severity.label,
    color: _color,
    foreground: AppColors.ink,
    tilt: tilt,
  );
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.action});

  final ModerationAction action;

  NexoGlyph get _glyph => switch (action.type) {
    ModerationType.hideComment => NexoGlyph.hidden,
    ModerationType.muteUser => NexoGlyph.micOff,
    ModerationType.banUser => NexoGlyph.lock,
    ModerationType.report => NexoGlyph.flag,
    ModerationType.dismissReport => NexoGlyph.close,
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final when = RelativeTime.format(action.createdAt);

    // Un comentario oculto es el dorso del sticker: el lado del liner hacia
    // arriba, sin troquel ni línea de corte (la punteada es "programado"), y
    // con el motivo impreso. La auditoría no borra lo que audita.
    if (action.type == ModerationType.hideComment) {
      return StickerFrame(
        edge: StickerEdge.none,
        fill: AppColors.linerHigh,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NexoIcon(
                NexoGlyph.hidden,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.type.label,
                      style: text.titleSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'De ${action.target} · Motivo: ${action.reason.label}',
                      style: text.bodySmall,
                    ),
                    Text(
                      'Oculto por ${action.actor} · $when',
                      style: text.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GlyphDisc(_glyph, size: 32),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${action.type.label} · ${action.target}',
                style: text.titleSmall,
              ),
              Text(
                '${action.actor} · ${action.reason.label} · $when',
                style: text.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Un glifo dentro de un disco: el ícono de una fila de herramienta.
class _GlyphDisc extends StatelessWidget {
  const _GlyphDisc(
    this.glyph, {
    this.size = 36,
    this.background = AppColors.linerHigh,
    this.foreground = AppColors.textSecondary,
  });

  final NexoGlyph glyph;
  final double size;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: background, shape: BoxShape.circle),
    child: NexoIcon(glyph, size: size * .52, color: foreground),
  );
}
