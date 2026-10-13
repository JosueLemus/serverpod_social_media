import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/sticker.dart';
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

/// En qué está la cola. Un fallo no es una cola vacía: la tarjeta decía "No
/// hay reportes pendientes" cuando en realidad no había podido leerla.
enum _QueueStatus { loading, unreadable, clear, pending }

class _Card extends StatelessWidget {
  const _Card({required this.isOperator});

  final bool isOperator;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: StickerCard(
      key: const Key('staff-shortcut'),
      child: _CardBody(isOperator: isOperator),
    ),
  );
}

/// El contenido, aparte para leer el tema **dentro** de la [StickerCard]: ahí
/// el texto es tinta y el CTA es relleno de tinta.
class _CardBody extends StatelessWidget {
  const _CardBody({required this.isOperator});

  final bool isOperator;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ModerationCubit>().state;
    final pending = state.reports.length;
    final status = state.isLoading
        ? _QueueStatus.loading
        : state.failedToLoad
        ? _QueueStatus.unreadable
        : pending == 0
        ? _QueueStatus.clear
        : _QueueStatus.pending;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
              child: NexoIcon(
                isOperator ? NexoGlyph.console : NexoGlyph.moderation,
                size: 20,
                color: AppColors.sticker,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wrap y no Row: a 320 el título y la insignia no entran
                  // en un renglón, y una fila recortaría la insignia.
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xxs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        isOperator
                            ? 'Sesión de operador'
                            : 'Sesión de moderación',
                        style: text.titleMedium,
                      ),
                      if (pending > 0)
                        // Vinilo con tinta: es un contador, no un fallo, y
                        // el rojo con blanco es la marca de en vivo.
                        StatusBadge(
                          label: '$pending PENDIENTES',
                          color: AppColors.vinylLime,
                          foreground: AppColors.ink,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      _StatusDot(status: status),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          switch (status) {
                            _QueueStatus.loading =>
                              'Leyendo la cola de reportes…',
                            _QueueStatus.unreadable =>
                              'No pudimos leer la cola de reportes.',
                            _QueueStatus.clear => 'No hay reportes pendientes.',
                            _QueueStatus.pending =>
                              pending == 1
                                  ? 'Hay 1 reporte esperando una decisión.'
                                  : 'Hay $pending reportes esperando una '
                                        'decisión.',
                          },
                          // Un fallo se lee en tinta plena, no en gris: es lo
                          // que la tarjeta tiene que decir.
                          style: status == _QueueStatus.unreadable
                              ? text.bodySmall?.copyWith(color: AppColors.ink)
                              : text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (isOperator) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Puedes suspender cuentas, revocar verificaciones y cortar '
            'vivos. Todo queda auditado.',
            style: text.bodySmall,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        FilledButton.icon(
          key: const Key('staff-shortcut-open'),
          onPressed: () =>
              context.go(isOperator ? AppRoutes.admin : AppRoutes.moderation),
          icon: const NexoIcon(NexoGlyph.forward, size: 18),
          iconAlignment: IconAlignment.end,
          label: Text(
            isOperator ? 'Abrir consola de operador' : 'Abrir moderación',
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, AppSizes.buttonHeightDense),
          ),
        ),
      ],
    );
  }
}

/// El estado de la cola en un punto, para leerlo sin leer la frase: verde si
/// está limpia, ámbar si algo espera, rojo si no se pudo leer.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final _QueueStatus status;

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      color: switch (status) {
        _QueueStatus.loading => AppColors.inkSecondary,
        _QueueStatus.unreadable => AppColors.error,
        _QueueStatus.clear => AppColors.tertiary,
        _QueueStatus.pending => AppColors.vinylLime,
      },
      shape: BoxShape.circle,
    ),
  );
}
