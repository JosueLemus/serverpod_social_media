import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/layout/nexo_page.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/live_session.dart';
import '../bloc/live_room_cubit.dart';
import '../utils/live_room_issue_ui.dart';
import '../utils/live_status_ui.dart';

/// El panel del host. Pensado para escritorio, donde un creador corre la
/// sesión con teclado y espacio, pero degrada a una columna en teléfono.
class CreatorStudioPage extends StatelessWidget {
  const CreatorStudioPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => LiveRoomCubit(sl(), sl())..load('live-2'),
    child: const _StudioView(),
  );
}

class _StudioView extends StatelessWidget {
  const _StudioView();

  @override
  Widget build(BuildContext context) =>
      BlocListener<LiveRoomCubit, LiveRoomState>(
        // El rechazo del servidor. El botón de iniciar no se esconde para un
        // creador desverificado: esconderlo sería la UI decidiendo un permiso,
        // que es justo lo que la demo tiene que refutar.
        listenWhen: (previous, current) =>
            current.issue != null &&
            previous.issueSerial != current.issueSerial,
        listener: (context, state) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.issue!.message))),
        child: BlocBuilder<LiveRoomCubit, LiveRoomState>(
          builder: (context, state) {
            final session = state.session;
            return NexoPage(
              section: 'Studio',
              title: 'Creator Studio',
              subtitle: 'Controla tu transmisión, tus invitados y tu comunidad',
              children: [
                if (state.isLoading)
                  const FeedSkeleton(count: 1)
                else if (session == null)
                  AppEmptyView(
                    icon: Icons.videocam_outlined,
                    title: 'Sin sesiones programadas',
                    message: 'Programa un vivo para verlo aquí.',
                    actionLabel: 'Ver vivos',
                    onAction: () => context.go(AppRoutes.explore),
                  )
                else ...[
                  Enter(
                    child: _BroadcastBar(session: session, state: state),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Enter(index: 1, child: _StudioMetrics(state: state)),
                  const SizedBox(height: AppSpacing.sm),
                  Enter(index: 2, child: _StagePreview(session: session)),
                  const SizedBox(height: AppSpacing.sm),
                  const Enter(index: 3, child: _StudioControls()),
                  Enter(
                    index: 4,
                    child: _GuestRequests(guests: state.pendingGuests),
                  ),
                  Enter(index: 5, child: _AuditTrail(entries: state.audit)),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            );
          },
        ),
      );
}

/// Estado de emisión y la única acción destructiva de la pantalla.
class _BroadcastBar extends StatelessWidget {
  const _BroadcastBar({required this.session, required this.state});

  final LiveSession session;
  final LiveRoomState state;

  /// `mm:ss` con relleno. Un contador que salta de "9:5" a "10:15" no se lee
  /// como un reloj.
  static String _clock(Duration elapsed) {
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${elapsed.inHours.toString().padLeft(2, '0')}:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LiveRoomCubit>();
    final onAir = session.status.isOnAir;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            StatusBadge(
              label: onAir
                  ? 'REC ${_clock(state.elapsed)}'
                  : session.status.label,
              color: session.status.color,
              pulse: onAir,
            ),
            if (onAir)
              const _MetaChip(icon: Icons.hd_rounded, label: '1080p 60fps'),
            // Sin Spacer: un Spacer es un Expanded, y dentro de un Wrap
            // revienta ("Incorrect use of ParentDataWidget") y pinta la caja
            // roja de error en debug.
            // Sólo se ofrecen las transiciones que el backend acepta desde
            // este estado. La máquina de estados es del servidor, y un botón
            // para una transición ilegal es una petición que se rechaza
            // después de que el usuario ya se comprometió.
            if (session.status == LiveStatus.scheduled)
              FilledButton.icon(
                key: const Key('studio-start'),
                onPressed: () => cubit.transition(LiveStatus.live),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Iniciar vivo'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, AppSizes.buttonHeightDense),
                ),
              ),
            if (onAir)
              FilledButton.icon(
                key: const Key('studio-end'),
                onPressed: () => cubit.transition(LiveStatus.recorded),
                icon: const Icon(Icons.power_settings_new_rounded, size: 17),
                label: const Text('Finalizar vivo'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  minimumSize: const Size(0, AppSizes.buttonHeightDense),
                ),
              ),
            if (session.status == LiveStatus.recorded)
              OutlinedButton.icon(
                key: const Key('studio-publish'),
                onPressed: () => cubit.transition(LiveStatus.published),
                icon: const Icon(Icons.publish_outlined, size: 17),
                label: const Text('Publicar replay'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, AppSizes.buttonHeightDense),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: AppColors.textSecondary),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _StudioMetrics extends StatelessWidget {
  const _StudioMetrics({required this.state});

  final LiveRoomState state;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _Metric(
          icon: Icons.visibility_outlined,
          value: compactCount(state.session?.viewers ?? 0),
          label: 'Espectadores',
        ),
      ),
      const SizedBox(width: AppSpacing.xs),
      Expanded(
        child: _Metric(
          icon: Icons.person_add_alt_1_outlined,
          value: '+${state.newSubscribers}',
          label: 'Nuevos subs',
          color: AppColors.tertiary,
        ),
      ),
      const SizedBox(width: AppSpacing.xs),
      Expanded(
        child: _Metric(
          icon: Icons.volunteer_activism_outlined,
          // Simulado y dicho en la pantalla: una demo de pagos que parece un
          // cobro real es lo único que un mock de pagos no puede hacer.
          value: '\$${state.donationsUsd}',
          label: 'Donaciones (mock)',
          color: AppColors.primaryDeep,
        ),
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
    this.color = AppColors.textPrimary,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 5),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 17, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}

class _StagePreview extends StatelessWidget {
  const _StagePreview({required this.session});

  final LiveSession session;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: AppRadii.medium,
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDeep, AppColors.stageDark],
              ),
            ),
          ),
          const Center(
            child: Icon(
              Icons.videocam_rounded,
              color: Colors.white38,
              size: 40,
            ),
          ),
          Positioned(
            top: AppSpacing.xs,
            left: AppSpacing.xs,
            child: Row(
              children: [
                const StatusBadge(
                  label: 'Estudio principal',
                  color: AppColors.stageScrim,
                ),
                if (session.status.isOnAir) ...[
                  const SizedBox(width: 6),
                  const StatusBadge(label: 'On air', pulse: true),
                ],
              ],
            ),
          ),
          const Positioned(
            bottom: AppSpacing.xs,
            left: AppSpacing.xs,
            child: StatusBadge(
              label: 'Transmisión simulada',
              color: AppColors.stageScrim,
              icon: Icons.info_outline_rounded,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Controles de emisión. Sin estado porque no hay medios que controlar
/// todavía: se activan cuando `LiveMediaGateway` exista.
class _StudioControls extends StatelessWidget {
  const _StudioControls();

  static const _controls = [
    (Icons.flip_camera_ios_outlined, 'Girar'),
    (Icons.mic_off_outlined, 'Silenciar'),
    (Icons.graphic_eq_rounded, 'Filtro EQ'),
    (Icons.card_giftcard_rounded, 'Regalos'),
  ];

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      for (final (icon, label) in _controls)
        Column(
          children: [
            IconButton.filledTonal(
              onPressed: () {},
              icon: Icon(icon, size: 19),
              tooltip: '$label · disponible con Agora',
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
    ],
  );
}

class _GuestRequests extends StatelessWidget {
  const _GuestRequests({required this.guests});

  final List<String> guests;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionHeader(
        title: 'Solicitudes para unirse',
        hint: guests.isEmpty ? null : '${guests.length} en cola',
        icon: Icons.group_add_outlined,
      ),
      if (guests.isEmpty)
        Text(
          'Nadie está esperando aprobación.',
          style: Theme.of(context).textTheme.bodySmall,
        )
      else
        Card(
          child: Column(
            children: [
              for (final (index, guest) in guests.indexed) ...[
                if (index > 0) const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      UserAvatar(name: guest, size: 38),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              guest,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'Pide emitir cámara y micrófono',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      // Aprobar es lo que el backend convierte en un token de
                      // broadcaster. El cliente nunca decide volverse
                      // emisor por su cuenta.
                      SizedBox(
                        height: 34,
                        child: FilledButton(
                          key: Key('approve-$guest'),
                          onPressed: () =>
                              context.read<LiveRoomCubit>().approveGuest(guest),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 34),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                          ),
                          child: const Text('Aceptar'),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Rechazar',
                        onPressed: () =>
                            context.read<LiveRoomCubit>().approveGuest(guest),
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
    ],
  );
}

class _AuditTrail extends StatelessWidget {
  const _AuditTrail({required this.entries});

  final List<String> entries;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionHeader(
        title: 'Registro de auditoría',
        icon: Icons.verified_user_outlined,
      ),
      if (entries.isEmpty)
        Text(
          'Sin acciones registradas en esta sesión.',
          style: Theme.of(context).textTheme.bodySmall,
        )
      else
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 15,
                          color: AppColors.tertiary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            entry,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
    ],
  );
}
