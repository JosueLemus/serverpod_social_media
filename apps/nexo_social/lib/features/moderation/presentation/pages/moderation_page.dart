import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/layout/nexo_page.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../domain/entities/moderation_action.dart';
import '../bloc/moderation_cubit.dart';

/// Moderation console. Desktop-first, but it degrades to one column on a
/// phone so a moderator is not blocked while away from a desk.
class ModerationPage extends StatelessWidget {
  const ModerationPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<ModerationCubit>()..load(),
    child: const _ModerationView(),
  );
}

class _ModerationView extends StatelessWidget {
  const _ModerationView();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ModerationCubit, ModerationState>(
        builder: (context, state) => NexoPage(
          title: 'Moderación',
          onRefresh: context.read<ModerationCubit>().load,
          children: [
            if (state.isLoading)
              const FeedSkeleton(count: 2)
            else ...[
              _SectionTitle('Cola de reportes', badge: state.reports.length),
              if (state.reports.isEmpty)
                const _EmptyQueue()
              else
                for (final (index, report) in state.reports.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Enter(
                      key: ValueKey(report.id),
                      index: index,
                      child: _ReportCard(report: report),
                    ),
                  ),
              const SizedBox(height: AppSpacing.md),
              const _SectionTitle('Registro de auditoría'),
              if (state.actions.isEmpty)
                Text(
                  'Todavía no se ha registrado ninguna acción.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                for (final action in state.actions) _AuditRow(action: action),
            ],
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label, {this.badge});

  final String label;
  final int? badge;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        if (badge != null && badge! > 0) ...[
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: const BoxDecoration(
              color: AppColors.error,
              borderRadius: AppRadii.large,
            ),
            child: Text(
              '$badge',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'No hay reportes pendientes.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final ModerationReport report;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ModerationCubit>();
    return Card(
      key: Key('report-${report.id}'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SeverityTag(severity: report.severity),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '${report.reason} · ${RelativeTime.format(report.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '“${report.content}”',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(report.author, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.md),
            // Wrap, not Row: three buttons and a long author handle overflow a
            // Row on a narrow window, and an overflowing action bar hides the
            // action a moderator needs.
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                FilledButton.tonal(
                  key: Key('hide-${report.id}'),
                  onPressed: () =>
                      cubit.resolve(report, ModerationType.hideComment),
                  child: const Text('Ocultar'),
                ),
                OutlinedButton(
                  key: Key('mute-${report.id}'),
                  onPressed: () =>
                      cubit.resolve(report, ModerationType.muteUser),
                  child: const Text('Silenciar'),
                ),
                OutlinedButton(
                  key: Key('ban-${report.id}'),
                  onPressed: () =>
                      cubit.resolve(report, ModerationType.banUser),
                  child: const Text('Expulsar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SeverityTag extends StatelessWidget {
  const _SeverityTag({required this.severity});

  final ReportSeverity severity;

  Color get _color => switch (severity) {
    ReportSeverity.high => AppColors.error,
    ReportSeverity.medium => AppColors.warning,
    ReportSeverity.low => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 3),
    decoration: BoxDecoration(color: _color, borderRadius: AppRadii.large),
    child: Text(
      severity.label.toUpperCase(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: .5,
      ),
    ),
  );
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.action});

  final ModerationAction action;

  @override
  Widget build(BuildContext context) => Padding(
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
                '${action.type.label} · ${action.target}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${action.actor} · ${action.reason} · ${RelativeTime.format(action.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
