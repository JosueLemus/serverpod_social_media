import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/layout/nexo_page.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/live_session.dart';
import '../bloc/live_media_cubit.dart';
import '../bloc/live_room_cubit.dart';
import '../utils/live_room_issue_ui.dart';
import '../utils/live_status_ui.dart';
import '../widgets/live_chat.dart';
import '../widgets/live_media_sync.dart';
import '../widgets/live_video_surface.dart';

/// El panel del host. Pensado para escritorio, donde un creador corre la
/// sesión con teclado y espacio, pero degrada a una columna en teléfono.
///
/// Abre el show del host en sesión (ver `pickStudioShow`); [showId] viene de
/// `?show=` y elige uno puntual entre los suyos.
class CreatorStudioPage extends StatelessWidget {
  const CreatorStudioPage({super.key, this.showId});

  final String? showId;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => LiveRoomCubit(sl(), sl())..loadStudio(requested: showId),
      ),
      BlocProvider(create: (_) => sl<LiveMediaCubit>()),
    ],
    child: const LiveMediaSync(role: LiveMediaRole.host, child: _StudioView()),
  );
}

class _StudioView extends StatelessWidget {
  const _StudioView();

  @override
  Widget build(
    BuildContext context,
  ) => BlocListener<LiveRoomCubit, LiveRoomState>(
    // El rechazo del servidor. El botón de iniciar no se esconde para un
    // creador desverificado: esconderlo sería la UI decidiendo un permiso,
    // que es justo lo que la demo tiene que refutar.
    listenWhen: (previous, current) =>
        current.issue != null && previous.issueSerial != current.issueSerial,
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
              const _StudioEmpty()
            else ...[
              // Todo lo que se toca sólo aparece: una traslación deja los
              // botones corridos mientras dura y los toques caen al vacío.
              EnterStatic(
                child: _BroadcastBar(session: session, state: state),
              ),
              const SizedBox(height: AppSpacing.sm),
              Enter(index: 1, child: _StudioMetrics(state: state)),
              const SizedBox(height: AppSpacing.sm),
              EnterStatic(
                index: 2,
                child: _StagePreview(
                  session: session,
                  comments: state.comments,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              EnterStatic(index: 3, child: _StudioControls(session: session)),
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

/// Un show que ya no vuelve al aire. Desde acá la única forma de transmitir
/// es un vivo nuevo.
bool _isOver(LiveStatus status) =>
    status == LiveStatus.recorded ||
    status == LiveStatus.published ||
    status.isClosed;

/// Pide cámara y micrófono y sólo con los dos concedidos hace [action].
///
/// Va **antes** de tocar el servidor. Pedirlos al entrar al canal, después de
/// iniciar, dejaba un vivo al aire sin cámara si la persona decía que no.
Future<void> _withCameraAndMicrophone(
  BuildContext context,
  Future<void> Function() action,
) async {
  final media = context.read<LiveMediaCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final issue = await media.preparePublish();
  if (issue == null) return action();
  messenger.showSnackBar(
    SnackBar(
      content: const Text('Necesitamos tu cámara y micrófono para transmitir.'),
      // Bloqueado, el sistema ya no muestra el diálogo: volver a tocar
      // "Iniciar" no haría nada, así que se ofrece la única salida.
      action: issue == LiveMediaIssue.permissionBlocked
          ? SnackBarAction(
              label: 'Ajustes',
              onPressed: () => unawaited(media.openPermissionSettings()),
            )
          : null,
    ),
  );
}

/// "Transmitir ahora": un título y al aire, sin programar antes.
Future<void> _goLiveNow(BuildContext context) async {
  final room = context.read<LiveRoomCubit>();
  final auth = context.read<AuthCubit>().state;
  final username = auth is AuthAuthenticated ? auth.user.username : '';
  final title = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _GoLiveSheet(
      initialTitle: username.isEmpty ? '' : 'En vivo con @$username',
    ),
  );
  if (title == null || !context.mounted) return;
  await _withCameraAndMicrophone(context, () => room.goLive(title));
}

/// Sin show propio. Lo primero es salir en vivo ya; programar queda como
/// segunda opción.
class _StudioEmpty extends StatelessWidget {
  const _StudioEmpty();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppEmptyView(
        icon: Icons.videocam_outlined,
        title: 'Todavía no tienes un vivo',
        message:
            'Sal en vivo ahora mismo o programa uno para que tu comunidad '
            'lo tenga en la agenda.',
        actionLabel: 'Transmitir ahora',
        onAction: () => unawaited(_goLiveNow(context)),
      ),
      OutlinedButton.icon(
        key: const Key('studio-schedule'),
        onPressed: () => unawaited(context.push(AppRoutes.scheduleShow)),
        icon: const Icon(Icons.event_outlined, size: 18),
        label: const Text('Programar show'),
      ),
    ],
  );
}

/// El título de un vivo que arranca ya. Dueña de su controller: construirlo
/// en `build` lo recrea en cada tecla y el cursor salta al principio.
class _GoLiveSheet extends StatefulWidget {
  const _GoLiveSheet({required this.initialTitle});

  final String initialTitle;

  @override
  State<_GoLiveSheet> createState() => _GoLiveSheetState();
}

class _GoLiveSheetState extends State<_GoLiveSheet> {
  late final _title = TextEditingController(text: widget.initialTitle);

  /// El mismo tope que programar un show (`ShowDraft.maxTitleLength`).
  static const _maxLength = 100;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(title);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      AppSpacing.md,
      0,
      AppSpacing.md,
      MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Transmitir ahora', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Tu comunidad lo ve aparecer en "En vivo ahora" en cuanto empiezas.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: const Key('go-live-title'),
          controller: _title,
          autofocus: true,
          maxLength: _maxLength,
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            labelText: 'Título del vivo',
            hintText: '¿De qué vas a hablar?',
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ValueListenableBuilder(
          valueListenable: _title,
          builder: (context, value, _) => FilledButton.icon(
            key: const Key('go-live-submit'),
            onPressed: value.text.trim().isEmpty ? null : _submit,
            icon: const Icon(Icons.sensors_rounded, size: 18),
            label: const Text('Transmitir ahora'),
          ),
        ),
      ],
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
                // Cámara y micrófono antes que el servidor: con el orden al
                // revés, decir que no deja un vivo al aire sin imagen.
                onPressed: () => unawaited(
                  _withCameraAndMicrophone(
                    context,
                    () => cubit.transition(LiveStatus.live),
                  ),
                ),
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
            // Un vivo terminado no se reabre: se sale con uno nuevo, como en
            // cualquier red social. Sin esto, después de finalizar el Studio
            // quedaba sin ninguna acción para volver al aire.
            if (_isOver(session.status))
              FilledButton.icon(
                key: const Key('studio-new-live'),
                onPressed: () => unawaited(_goLiveNow(context)),
                icon: const Icon(Icons.sensors_rounded, size: 18),
                label: const Text('Nuevo vivo'),
                style: FilledButton.styleFrom(
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
  const _StagePreview({required this.session, required this.comments});

  final LiveSession session;
  final List<LiveComment> comments;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: AppRadii.medium,
    child: AspectRatio(
      // En el teléfono la cámara es vertical: un escenario 16:9 la recorta a
      // una franja y no deja lugar para el chat encima.
      aspectRatio: AppBreakpoints.of(context).isCompact ? 3 / 4 : 16 / 9,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            LiveVideoSurface(
              role: LiveMediaRole.host,
              fallback: const _SimulatedStage(),
            ),
            // El velo de abajo: el chat va sobre video, y sin él su
            // legibilidad depende de lo que haya en la imagen.
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.stageScrim],
                    stops: [.45, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.xs,
              left: AppSpacing.xs,
              right: AppSpacing.xs,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  const StatusBadge(
                    label: 'Estudio principal',
                    color: AppColors.stageScrim,
                  ),
                  if (session.status.isOnAir)
                    const StatusBadge(label: 'On air', pulse: true),
                  // Sólo cuando lo es: con Agora, la cámara de abajo es real.
                  if (context.read<LiveMediaCubit>().engine.isSimulated)
                    const StatusBadge(
                      label: 'Transmisión simulada',
                      color: AppColors.stageScrim,
                      icon: Icons.info_outline_rounded,
                    ),
                ],
              ),
            ),
            // Lo mismo que ve la audiencia, para que el host pueda contestar
            // y moderar sin salir del Studio.
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.xs,
              child: LiveChatOverlay(
                comments: comments,
                emptyLabel: 'Todavía no hay comentarios',
                maxHeight: constraints.maxHeight * .5,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// El escenario sin video: un degradé con la cámara apagada.
class _SimulatedStage extends StatelessWidget {
  const _SimulatedStage();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primaryDeep, AppColors.stageDark],
      ),
    ),
    child: Center(
      child: Icon(Icons.videocam_rounded, color: Colors.white38, size: 40),
    ),
  );
}

/// Controles de emisión. Girar y silenciar actúan sobre la cámara real; sin
/// video (simulado o fuera del aire) no hay nada que controlar y se
/// deshabilitan. Un botón activo que no responde se lee como una app rota.
class _StudioControls extends StatelessWidget {
  const _StudioControls({required this.session});

  final LiveSession session;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<LiveMediaCubit, LiveMediaState>(
    builder: (context, media) {
      final cubit = context.read<LiveMediaCubit>();
      final live =
          !cubit.engine.isSimulated &&
          session.status.isOnAir &&
          media.phase == LiveMediaPhase.connected;
      final unavailable = cubit.engine.isSimulated
          ? 'Disponible con video real'
          : 'Disponible al aire';
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StudioControl(
            key: const Key('studio-flip'),
            icon: Icons.flip_camera_ios_outlined,
            label: 'Girar',
            tooltip: live ? 'Cambiar de cámara' : unavailable,
            onPressed: live ? () => unawaited(cubit.switchCamera()) : null,
          ),
          _StudioControl(
            key: const Key('studio-mute'),
            icon: media.micMuted ? Icons.mic_rounded : Icons.mic_off_outlined,
            label: media.micMuted ? 'Activar micrófono' : 'Silenciar',
            tooltip: live
                ? (media.micMuted
                      ? 'Tu audiencia no te escucha'
                      : 'Apagar el micrófono')
                : unavailable,
            onPressed: live ? () => unawaited(cubit.toggleMicrophone()) : null,
          ),
          const _StudioControl(
            icon: Icons.graphic_eq_rounded,
            label: 'Filtro EQ',
            tooltip: 'Próximamente',
          ),
          const _StudioControl(
            icon: Icons.card_giftcard_rounded,
            label: 'Regalos',
            tooltip: 'Próximamente',
          ),
        ],
      );
    },
  );
}

class _StudioControl extends StatelessWidget {
  const _StudioControl({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final String tooltip;

  /// Null deshabilita el botón.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        IconButton.filledTonal(
          onPressed: onPressed,
          icon: Icon(icon, size: 19),
          tooltip: tooltip,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    ),
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
                            context.read<LiveRoomCubit>().rejectGuest(guest),
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
