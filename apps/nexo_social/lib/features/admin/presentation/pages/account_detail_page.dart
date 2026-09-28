import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/layout/nexo_page.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/account_detail.dart';
import '../bloc/account_detail_cubit.dart';
import '../utils/admin_ui.dart';
import '../widgets/reason_sheet.dart';
import 'admin_console_page.dart';

/// La ficha de una cuenta: quién es, qué historial tiene y qué se le puede
/// hacer. El historial va en la misma pantalla que las acciones porque es lo
/// que decide cuál tomar: una primera falta no se trata como una tercera.
class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<AccountDetailCubit>(param1: accountId)..load(),
    child: const _DetailView(),
  );
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<AccountDetailCubit, AccountDetailState>(
        listenWhen: (previous, current) => previous.serial != current.serial,
        listener: (context, state) {
          final message = state.issue?.message ?? state.notice?.message;
          if (message == null || state.detail == null) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
        builder: (context, state) {
          final detail = state.detail;
          return NexoPage(
            section: 'Consola',
            onRefresh: context.read<AccountDetailCubit>().load,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.admin),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Consola'),
                ),
              ),
              if (state.isLoading)
                const FeedSkeleton(count: 1)
              else if (detail == null)
                AppEmptyView(
                  icon: Icons.person_off_outlined,
                  title: 'No pudimos abrir la ficha',
                  message: (state.issue ?? AdminIssue.other).message,
                  actionLabel: 'Volver a la consola',
                  onAction: () => context.go(AppRoutes.admin),
                )
              else ...[
                _Summary(detail: detail),
                const SizedBox(height: AppSpacing.md),
                _Actions(user: detail.user, isWorking: state.isWorking),
                const SizedBox(height: AppSpacing.lg),
                _History(sanctions: detail.sanctions),
              ],
            ],
          );
        },
      );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.detail});

  final AccountDetail detail;

  @override
  Widget build(BuildContext context) {
    final user = detail.user;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(name: user.name, size: 52),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '@${user.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AccountBadges(user: user),
            const SizedBox(height: AppSpacing.sm),
            _Fact(label: 'Correo', value: user.email),
            _Fact(label: 'Id', value: user.id),
            _Fact(label: 'Alta', value: RelativeTime.format(detail.joinedAt)),
            _Fact(label: 'Reportes abiertos', value: '${detail.openReports}'),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xxs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    ),
  );
}

class _Actions extends StatelessWidget {
  const _Actions({required this.user, required this.isWorking});

  final AppUser user;
  final bool isWorking;

  Future<void> _suspend(BuildContext context) async {
    final cubit = context.read<AccountDetailCubit>();
    final reason = await showReasonSheet(
      context,
      title: 'Suspender cuenta',
      detail:
          '@${user.username} queda afuera en este momento: sus sesiones '
          'activas se cierran. Se puede restaurar.',
      confirmLabel: 'Suspender',
    );
    if (reason != null) await cubit.suspend(reason);
  }

  Future<void> _ban(BuildContext context) async {
    final cubit = context.read<AccountDetailCubit>();
    final reason = await showReasonSheet(
      context,
      title: 'Banear cuenta',
      detail:
          'Permanente. @${user.username} no podrá volver a entrar y la '
          'decisión no se deshace desde la consola.',
      confirmLabel: 'Banear de forma permanente',
    );
    if (reason != null) await cubit.ban(reason);
  }

  Future<void> _revoke(BuildContext context) async {
    final cubit = context.read<AccountDetailCubit>();
    final reason = await showReasonSheet(
      context,
      title: 'Revocar verificación',
      detail: '@${user.username} no podrá iniciar vivos.',
      confirmLabel: 'Revocar verificación',
    );
    if (reason != null) {
      await cubit.setVerification(verified: false, reason: reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AccountDetailCubit>();
    // R4: el operador no sanciona a otro operador. El botón no se ofrece, y
    // el servidor lo rechazaría igual.
    final sanctionable = !user.isOperator;
    final buttons = <Widget>[
      if (sanctionable && user.status == AccountStatus.active) ...[
        FilledButton.icon(
          key: const Key('account-suspend'),
          onPressed: isWorking ? null : () => unawaited(_suspend(context)),
          icon: const Icon(Icons.pause_circle_outline_rounded, size: 18),
          label: const Text('Suspender'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
        ),
        OutlinedButton.icon(
          key: const Key('account-ban'),
          onPressed: isWorking ? null : () => unawaited(_ban(context)),
          icon: const Icon(Icons.block_rounded, size: 18),
          label: const Text('Banear'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
        ),
      ],
      if (sanctionable && user.status == AccountStatus.suspended) ...[
        FilledButton.icon(
          key: const Key('account-restore'),
          onPressed: isWorking ? null : () => unawaited(cubit.restore()),
          icon: const Icon(Icons.restart_alt_rounded, size: 18),
          label: const Text('Restaurar'),
        ),
        OutlinedButton.icon(
          key: const Key('account-ban'),
          onPressed: isWorking ? null : () => unawaited(_ban(context)),
          icon: const Icon(Icons.block_rounded, size: 18),
          label: const Text('Banear'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
        ),
      ],
      if (user.isCreator && user.isVerified)
        OutlinedButton.icon(
          key: const Key('account-revoke'),
          onPressed: isWorking ? null : () => unawaited(_revoke(context)),
          icon: const Icon(Icons.remove_moderator_outlined, size: 18),
          label: const Text('Revocar verificación'),
        ),
      if (user.isCreator && !user.isVerified)
        OutlinedButton.icon(
          key: const Key('account-verify'),
          onPressed: isWorking
              ? null
              : () => unawaited(cubit.setVerification(verified: true)),
          icon: const Icon(Icons.verified_outlined, size: 18),
          label: const Text('Verificar'),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Acciones', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        if (user.status == AccountStatus.banned)
          Text(
            'Cuenta baneada de forma permanente. No hay acciones '
            'disponibles.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else if (buttons.isEmpty)
          Text(
            'Las cuentas de operador no se sancionan desde la consola.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: buttons,
          ),
      ],
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.sanctions});

  final List<Sanction> sanctions;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historial de sanciones',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        if (sanctions.isEmpty)
          Text(
            'Sin sanciones previas.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          for (final sanction in sanctions)
            Padding(
              key: Key('sanction-${sanction.id}'),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    sanction.isActiveAt(now)
                        ? Icons.gpp_maybe_outlined
                        : Icons.history_rounded,
                    size: 17,
                    color: sanction.isActiveAt(now)
                        ? AppColors.error
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${sanction.kind.label} · ${sanction.reason.label}'
                          '${sanction.isActiveAt(now) ? ' · vigente' : ''}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${sanction.createdBy} · '
                          '${RelativeTime.format(sanction.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
