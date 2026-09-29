import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/pills.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../bloc/moderation_cubit.dart';

/// La entrada al trabajo de moderación, en la primera pantalla.
///
/// Sin esto, un operador y un usuario veían exactamente el mismo feed: la
/// consola existía sólo en el rail de escritorio y en un menú ⋮ del perfil,
/// así que en un teléfono no había nada que dijera que la cuenta tenía otro
/// rol. Sólo la ven quienes pueden moderar; para el resto no ocupa lugar.
class StaffShortcutCard extends StatelessWidget {
  const StaffShortcutCard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final user = auth is AuthAuthenticated ? auth.user : null;
    if (user == null || !user.canModerate) return const SizedBox.shrink();

    return BlocProvider(
      create: (_) => sl<ModerationCubit>()..load(),
      child: _Card(isOperator: user.isOperator),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.isOperator});

  final bool isOperator;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ModerationCubit>().state;
    final pending = state.reports.length;
    return Container(
      key: const Key('staff-shortcut'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.neutral,
        borderRadius: AppRadii.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOperator
                    ? Icons.admin_panel_settings_rounded
                    : Icons.shield_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  isOperator ? 'Sesión de operador' : 'Sesión de moderación',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
              if (pending > 0)
                StatusBadge(label: '$pending PENDIENTES', pulse: true),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            state.isLoading
                ? 'Leyendo la cola de reportes…'
                : pending == 0
                ? 'No hay reportes pendientes.'
                : pending == 1
                ? 'Hay 1 reporte esperando una decisión.'
                : 'Hay $pending reportes esperando una decisión.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          if (isOperator) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Puedes suspender cuentas, revocar verificaciones y cortar '
              'vivos. Todo queda auditado.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            key: const Key('staff-shortcut-open'),
            onPressed: () =>
                context.go(isOperator ? AppRoutes.admin : AppRoutes.moderation),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            iconAlignment: IconAlignment.end,
            label: Text(
              isOperator ? 'Abrir consola de operador' : 'Abrir moderación',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.neutral,
              minimumSize: const Size(0, AppSizes.buttonHeightDense),
            ),
          ),
        ],
      ),
    );
  }
}
