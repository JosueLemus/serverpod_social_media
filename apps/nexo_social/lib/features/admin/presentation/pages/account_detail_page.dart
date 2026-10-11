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
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/nexo_mascot.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/sticker.dart';
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
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                  ),
                  icon: const NexoIcon(NexoGlyph.back, size: 18),
                  label: const Text('Consola'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (state.isLoading)
                const AdminRowsSkeleton(rows: 2)
              else if (detail == null)
                AppEmptyView(
                  mascot: NexoMascot.search,
                  title: 'No pudimos abrir la ficha',
                  message: (state.issue ?? AdminIssue.other).message,
                  actionLabel: 'Volver a la consola',
                  onAction: () => context.go(AppRoutes.admin),
                )
              else ...[
                _Summary(user: detail.user),
                _Facts(detail: detail),
                _Actions(user: detail.user, isWorking: state.isWorking),
                _History(sanctions: detail.sanctions),
              ],
            ],
          );
        },
      );
}

/// Quién es, como el único objeto destacado de la ficha: un sticker con el
/// corte del logo. Todo lo demás va plano sobre el liner, para que el ojo
/// llegue primero a la persona y después a los datos.
class _Summary extends StatelessWidget {
  const _Summary({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    // Dentro del sticker el tema ya es tinta, pero sólo para un contexto que
    // esté *adentro*: leer el textTheme acá arriba trae el claro del liner, y
    // el nombre salía blanco sobre blanco. Por eso el Builder.
    return StickerCard(
      child: Builder(
        builder: (context) {
          final text = Theme.of(context).textTheme;
          return Row(
            children: [
              UserAvatar(name: user.name, size: 60),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.headlineSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AccountBadges(user: user),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// La identidad técnica de la cuenta, en filas planas sobre el liner con
/// filetes: es una lectura, no un objeto, así que no lleva caja.
class _Facts extends StatelessWidget {
  const _Facts({required this.detail});

  final AccountDetail detail;

  @override
  Widget build(BuildContext context) {
    final user = detail.user;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Datos de la cuenta'),
        _Fact(glyph: NexoGlyph.mention, label: 'Correo', value: user.email),
        const _FactDivider(),
        _Fact(glyph: NexoGlyph.hashtag, label: 'Id', value: user.id),
        const _FactDivider(),
        _Fact(
          glyph: NexoGlyph.clock,
          label: 'Alta',
          value: RelativeTime.format(detail.joinedAt),
        ),
        const _FactDivider(),
        _Fact(
          glyph: NexoGlyph.flag,
          label: 'Reportes abiertos',
          value: '${detail.openReports}',
        ),
      ],
    );
  }
}

class _FactDivider extends StatelessWidget {
  const _FactDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 20 + AppSpacing.sm);
}

class _Fact extends StatelessWidget {
  const _Fact({required this.glyph, required this.label, required this.value});

  final NexoGlyph glyph;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          NexoIcon(glyph, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          // La etiqueta puede bajar de renglón ("Reportes / abiertos" a
          // 320); el valor se corta con elipsis. Ninguno de los dos empuja al
          // otro fuera de la fila.
          Flexible(
            flex: 2,
            child: Text(
              label,
              maxLines: 2,
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 3,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: text.labelMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
    // El baneo es el candado cerrado del todo (relleno); la suspensión, el
    // contorno: la misma diferencia que en el historial.
    final ban = OutlinedButton.icon(
      key: const Key('account-ban'),
      onPressed: isWorking ? null : () => unawaited(_ban(context)),
      style: AdminButtons.destructiveOutline,
      icon: const NexoIcon(NexoGlyph.lock, size: 18, filled: true),
      label: const Text('Banear'),
    );
    final buttons = <Widget>[
      if (sanctionable && user.status == AccountStatus.active) ...[
        FilledButton.icon(
          key: const Key('account-suspend'),
          onPressed: isWorking ? null : () => unawaited(_suspend(context)),
          style: AdminButtons.destructiveFill,
          icon: const NexoIcon(NexoGlyph.lock, size: 18),
          label: const Text('Suspender'),
        ),
        ban,
      ],
      if (sanctionable && user.status == AccountStatus.suspended) ...[
        // Restaurar es la acción segura de la ficha: el sticker blanco.
        FilledButton(
          key: const Key('account-restore'),
          onPressed: isWorking ? null : () => unawaited(cubit.restore()),
          style: AdminButtons.safe,
          child: const Text('Restaurar'),
        ),
        ban,
      ],
      if (user.isCreator && user.isVerified)
        OutlinedButton.icon(
          key: const Key('account-revoke'),
          onPressed: isWorking ? null : () => unawaited(_revoke(context)),
          style: AdminButtons.destructiveOutline,
          icon: const NexoIcon(NexoGlyph.verified, size: 18),
          label: const Text('Revocar verificación'),
        ),
      if (user.isCreator && !user.isVerified)
        OutlinedButton.icon(
          key: const Key('account-verify'),
          onPressed: isWorking
              ? null
              : () => unawaited(cubit.setVerification(verified: true)),
          style: AdminButtons.quiet,
          icon: const NexoIcon(NexoGlyph.verified, size: 18),
          label: const Text('Verificar'),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Acciones'),
        if (user.status == AccountStatus.banned)
          const _Notice(
            glyph: NexoGlyph.lock,
            text:
                'Cuenta baneada de forma permanente. No hay acciones '
                'disponibles.',
          )
        else if (buttons.isEmpty)
          const _Notice(
            glyph: NexoGlyph.console,
            text: 'Las cuentas de operador no se sancionan desde la consola.',
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

/// Por qué no hay botones: una línea en gris con su glifo, plana sobre el
/// liner. Se lee, pero no invita a tocar.
class _Notice extends StatelessWidget {
  const _Notice({required this.glyph, required this.text});

  final NexoGlyph glyph;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      NexoIcon(glyph, size: 18, color: AppColors.textSecondary),
      const SizedBox(width: AppSpacing.xs),
      Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
    ],
  );
}

class _History extends StatelessWidget {
  const _History({required this.sanctions});

  final List<Sanction> sanctions;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Historial de sanciones'),
        const SizedBox(height: AppSpacing.xs),
        if (sanctions.isEmpty)
          Row(
            children: [
              const NexoIcon(
                NexoGlyph.clock,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text('Sin sanciones previas.', style: text.bodySmall),
              ),
            ],
          )
        else
          for (final (index, sanction) in sanctions.indexed)
            // Lo vigente lleva el color de su tipo; lo que ya terminó queda
            // en gris. La lista es append-only: nada se borra, se apaga.
            AdminTimelineNode(
              key: Key('sanction-${sanction.id}'),
              glyph: sanction.kind.glyph,
              filled: sanction.kind.glyphFilled,
              tone: sanction.isActiveAt(now)
                  ? sanction.kind.color
                  : AppColors.textSecondary,
              title: '${sanction.kind.label} · ${sanction.reason.label}',
              badge: sanction.isActiveAt(now)
                  ? StatusBadge(
                      label: 'Vigente',
                      color: sanction.kind.color,
                      foreground: sanction.kind.foreground,
                    )
                  : null,
              meta:
                  '${sanction.createdBy} · '
                  '${RelativeTime.format(sanction.createdAt)}',
              isLast: index == sanctions.length - 1,
            ),
      ],
    );
  }
}
