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
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/nexo_mascot.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/sticker.dart';
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
              const SizedBox(height: AppSpacing.md),
              EnterStatic(
                index: 1,
                child: _StagePreview(
                  session: session,
                  comments: state.comments,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              EnterStatic(index: 2, child: _StudioControls(session: session)),
              const SizedBox(height: AppSpacing.md),
              Enter(index: 3, child: _StudioMetrics(state: state)),
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

/// Los números del Studio: la cara display con cifras tabulares, para que un
/// contador que cambia no haga bailar lo que tiene al lado.
TextStyle? _figures(BuildContext context) => Theme.of(context)
    .textTheme
    .titleLarge
    ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

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

/// Salir al aire es la única acción roja del Studio: el rojo de sticker es la
/// marca de "en vivo", y el botón que lo enciende la lleva.
ButtonStyle _goLiveStyle() => FilledButton.styleFrom(
  backgroundColor: AppColors.secondary,
  foregroundColor: AppColors.sticker,
  disabledBackgroundColor: AppColors.linerHigh,
  disabledForegroundColor: AppColors.textTertiary,
  minimumSize: const Size(0, AppSizes.buttonHeightDense),
);

/// Sin show propio. Lo primero es salir en vivo ya; programar queda como
/// segunda opción.
class _StudioEmpty extends StatelessWidget {
  const _StudioEmpty();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppEmptyView(
        mascot: NexoMascot.mic,
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
        icon: const NexoIcon(NexoGlyph.calendar, size: 18),
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
        Row(
          children: [
            const MascotIllustration(NexoMascot.mic, size: 56),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transmitir ahora',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Tu comunidad lo ve aparecer en "En vivo ahora" en cuanto '
                    'empiezas.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
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
            style: _goLiveStyle().copyWith(
              minimumSize: const WidgetStatePropertyAll(
                Size(0, AppSizes.buttonHeight),
              ),
            ),
            icon: const NexoIcon(NexoGlyph.live, size: 18),
            label: const Text('Transmitir ahora'),
          ),
        ),
      ],
    ),
  );
}

/// Qué show se opera, en qué estado está y las transiciones que admite.
class _BroadcastBar extends StatelessWidget {
  const _BroadcastBar({required this.session, required this.state});

  final LiveSession session;
  final LiveRoomState state;

  /// `hh:mm:ss` con relleno. Un contador que salta de "9:5" a "10:15" no se
  /// lee como un reloj.
  static String _clock(Duration elapsed) {
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${elapsed.inHours.toString().padLeft(2, '0')}:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LiveRoomCubit>();
    final status = session.status;
    final onAir = status.isOnAir;
    const dense = Size(0, AppSizes.buttonHeightDense);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusBadge(
              label: status.label,
              color: status.color,
              foreground: status.foreground,
              pulse: onAir,
            ),
            if (onAir)
              Text(
                _clock(state.elapsed),
                key: const Key('studio-clock'),
                style: _figures(context),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          session.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        // Sin Spacer: un Spacer es un Expanded, y dentro de un Wrap revienta
        // ("Incorrect use of ParentDataWidget") y pinta la caja roja de error
        // en debug.
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            // Sólo se ofrecen las transiciones que el backend acepta desde
            // este estado. La máquina de estados es del servidor, y un botón
            // para una transición ilegal es una petición que se rechaza
            // después de que el usuario ya se comprometió.
            if (status == LiveStatus.scheduled)
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
                style: _goLiveStyle(),
                icon: const NexoIcon(NexoGlyph.live, size: 18),
                label: const Text('Salir al aire'),
              ),
            if (onAir)
              OutlinedButton(
                key: const Key('studio-end'),
                onPressed: () => cubit.transition(LiveStatus.recorded),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.6),
                  minimumSize: dense,
                ),
                child: const Text('Finalizar vivo'),
              ),
            if (status == LiveStatus.recorded)
              FilledButton.icon(
                key: const Key('studio-publish'),
                onPressed: () => cubit.transition(LiveStatus.published),
                style: FilledButton.styleFrom(minimumSize: dense),
                icon: const NexoIcon(NexoGlyph.play, filled: true, size: 18),
                label: const Text('Publicar replay'),
              ),
            // Un vivo terminado no se reabre: se sale con uno nuevo, como en
            // cualquier red social. Sin esto, después de finalizar el Studio
            // quedaba sin ninguna acción para volver al aire. Mientras el
            // replay espera publicarse, esa es la acción principal y ésta
            // queda en segundo plano: dos botones rellenos no jerarquizan.
            if (_isOver(status))
              status == LiveStatus.recorded
                  ? OutlinedButton.icon(
                      key: const Key('studio-new-live'),
                      onPressed: () => unawaited(_goLiveNow(context)),
                      style: OutlinedButton.styleFrom(minimumSize: dense),
                      icon: const NexoIcon(NexoGlyph.live, size: 18),
                      label: const Text('Nuevo vivo'),
                    )
                  : FilledButton.icon(
                      key: const Key('studio-new-live'),
                      onPressed: () => unawaited(_goLiveNow(context)),
                      style: _goLiveStyle(),
                      icon: const NexoIcon(NexoGlyph.live, size: 18),
                      label: const Text('Nuevo vivo'),
                    ),
          ],
        ),
      ],
    );
  }
}

class _StudioMetrics extends StatelessWidget {
  const _StudioMetrics({required this.state});

  final LiveRoomState state;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadii.medium,
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Expanded(
          child: _Metric(
            glyph: NexoGlyph.community,
            value: compactCount(state.session?.viewers ?? 0),
            label: 'Espectadores',
          ),
        ),
        const _MetricRule(),
        // Sin módulo de billing no hay dato: "—" y "(mock)" en la etiqueta.
        // Un número inventado en el panel del host se lee como una métrica
        // real.
        Expanded(
          child: _Metric(
            key: const Key('studio-subs'),
            glyph: NexoGlyph.crown,
            value: _orDash(state.newSubscribers, (value) => '+$value'),
            label: 'Nuevos subs (mock)',
          ),
        ),
        const _MetricRule(),
        Expanded(
          child: _Metric(
            key: const Key('studio-donations'),
            glyph: NexoGlyph.star,
            value: _orDash(state.donationsUsd, (value) => '\$$value'),
            label: 'Donaciones (mock)',
          ),
        ),
      ],
    ),
  );
}

/// El filete entre dos métricas del mismo panel.
class _MetricRule extends StatelessWidget {
  const _MetricRule();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 1,
    height: 52,
    child: ColoredBox(color: AppColors.border),
  );
}

/// El valor de una métrica, o "—" cuando no hay de dónde sacarlo.
String _orDash(int? value, String Function(int value) format) =>
    value == null ? '—' : format(value);

class _Metric extends StatelessWidget {
  const _Metric({
    super.key,
    required this.glyph,
    required this.value,
    required this.label,
  });

  final NexoGlyph glyph;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    child: Column(
      children: [
        NexoIcon(glyph, size: 18, color: AppColors.textSecondary),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _figures(context),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

/// El escenario del host, cortado con el borde de su estado: holo al aire,
/// punteado mientras está programado, troquel cuando ya terminó.
class _StagePreview extends StatelessWidget {
  const _StagePreview({required this.session, required this.comments});

  final LiveSession session;
  final List<LiveComment> comments;

  @override
  Widget build(BuildContext context) {
    final simulated = context.read<LiveMediaCubit>().engine.isSimulated;
    return StickerFrame(
      edge: session.status.edge,
      child: AspectRatio(
        // En el teléfono la cámara es vertical: un escenario 16:9 la recorta
        // a una franja y no deja lugar para el chat encima.
        aspectRatio: AppBreakpoints.of(context).isCompact ? 3 / 4 : 16 / 9,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            fit: StackFit.expand,
            children: [
              LiveVideoSurface(
                role: LiveMediaRole.host,
                // Sólo cuando lo es: con Agora, la cámara de abajo es real.
                fallback: LiveStagePlaceholder(
                  size: 72,
                  alignment: const Alignment(0, -.45),
                  caption: simulated ? 'Transmisión simulada' : null,
                ),
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
              if (session.status.isOnAir)
                const Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: StatusBadge(label: 'En vivo', pulse: true, tilt: -.05),
                ),
              // Lo mismo que ve la audiencia, para que el host pueda contestar
              // y moderar sin salir del Studio.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _StudioChat(
                  comments: comments,
                  hostId: session.hostId,
                  canWrite: session.status.isOnAir,
                  maxHeight: constraints.maxHeight * .45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El chat sobre el escenario y, al aire, el campo para que el host conteste.
///
/// Es dueño de su controller: construirlo en `build` lo recrearía con cada
/// comentario que llega y el cursor saltaría al principio a mitad de frase.
class _StudioChat extends StatefulWidget {
  const _StudioChat({
    required this.comments,
    required this.hostId,
    required this.canWrite,
    required this.maxHeight,
  });

  final List<LiveComment> comments;
  final String hostId;
  final bool canWrite;
  final double maxHeight;

  @override
  State<_StudioChat> createState() => _StudioChatState();
}

class _StudioChatState extends State<_StudioChat> {
  final _composer = TextEditingController();

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  void _send() {
    unawaited(context.read<LiveRoomCubit>().sendComment(_composer.text));
    _composer.clear();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      LiveChatOverlay(
        comments: widget.comments,
        hostId: widget.hostId,
        emptyLabel: 'Todavía no hay comentarios',
        maxHeight: widget.maxHeight,
      ),
      if (widget.canWrite)
        LiveChatComposer(
          controller: _composer,
          onSend: _send,
          fieldKey: const Key('studio-comment-field'),
          sendKey: const Key('studio-send'),
          // La página del Studio sí se acomoda al teclado.
          liftAboveKeyboard: false,
        )
      else
        const SizedBox(height: AppSpacing.xs),
    ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StudioControl(
            key: const Key('studio-flip'),
            icon: const NexoIcon(NexoGlyph.flipCamera),
            label: 'Girar',
            tooltip: live ? 'Cambiar de cámara' : unavailable,
            onPressed: live ? () => unawaited(cubit.switchCamera()) : null,
          ),
          // El ícono dice el estado (micrófono tachado = no te escuchan) y la
          // etiqueta, lo que hace tocarlo. Silenciado, el disco se despega en
          // blanco: un estado que la audiencia sufre no puede pasar
          // desapercibido para el host.
          _StudioControl(
            key: const Key('studio-mute'),
            icon: NexoIcon(media.micMuted ? NexoGlyph.micOff : NexoGlyph.mic),
            label: media.micMuted ? 'Activar micrófono' : 'Silenciar',
            selected: media.micMuted,
            tooltip: live
                ? (media.micMuted
                      ? 'Tu audiencia no te escucha'
                      : 'Apagar el micrófono')
                : unavailable,
            onPressed: live ? () => unawaited(cubit.toggleMicrophone()) : null,
          ),
          const _StudioControl(
            icon: NexoIcon(NexoGlyph.equalizer),
            label: 'Filtro EQ',
            tooltip: 'Próximamente',
          ),
          const _StudioControl(
            icon: NexoIcon(NexoGlyph.gift),
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
    this.selected = false,
  });

  final Widget icon;
  final String label;
  final String tooltip;

  /// Null deshabilita el botón.
  final VoidCallback? onPressed;

  /// Encendido: el disco pasa a sticker blanco con el glifo en tinta.
  final bool selected;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        IconButton.filled(
          onPressed: onPressed,
          icon: icon,
          iconSize: 22,
          tooltip: tooltip,
          style: IconButton.styleFrom(
            fixedSize: const Size.square(52),
            backgroundColor: selected ? AppColors.sticker : AppColors.linerHigh,
            foregroundColor: selected ? AppColors.ink : AppColors.textPrimary,
            disabledBackgroundColor: AppColors.linerHigh,
            disabledForegroundColor: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

/// Quién pidió subir a la transmisión. Aprobar es el sticker blanco; rechazar,
/// el contorno: las dos se ofrecen, pero una es la que el host suele querer.
class _GuestRequests extends StatelessWidget {
  const _GuestRequests({required this.guests});

  final List<String> guests;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionHeader(
        title: 'Solicitudes para unirse',
        action: guests.isEmpty
            ? null
            : StatusBadge(
                label: '${guests.length} en cola',
                color: AppColors.vinylLime,
                foreground: AppColors.ink,
              ),
      ),
      if (guests.isEmpty)
        Text(
          'Nadie está esperando aprobación.',
          style: Theme.of(context).textTheme.bodySmall,
        )
      else
        for (final (index, guest) in guests.indexed) ...[
          if (index > 0) const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(name: guest, size: 44),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guest,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Pide emitir cámara y micrófono',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // Debajo del nombre y no a su lado: a 320 dos botones
                      // junto al avatar dejan al nombre sin lugar.
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          // Aprobar es lo que el backend convierte en un token
                          // de broadcaster. El cliente nunca decide volverse
                          // emisor por su cuenta.
                          FilledButton(
                            key: Key('approve-$guest'),
                            onPressed: () => context
                                .read<LiveRoomCubit>()
                                .approveGuest(guest),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(
                                0,
                                AppSizes.buttonHeightDense,
                              ),
                            ),
                            child: const Text('Aceptar'),
                          ),
                          OutlinedButton(
                            onPressed: () => context
                                .read<LiveRoomCubit>()
                                .rejectGuest(guest),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(
                                0,
                                AppSizes.buttonHeightDense,
                              ),
                            ),
                            child: const Text('Rechazar'),
                          ),
                        ],
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

/// Lo que se hizo en la sesión. Append-only: la auditoría que borra lo que
/// audita no prueba nada.
class _AuditTrail extends StatelessWidget {
  const _AuditTrail({required this.entries});

  final List<String> entries;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionHeader(title: 'Registro de auditoría'),
      if (entries.isEmpty)
        Text(
          'Sin acciones registradas en esta sesión.',
          style: Theme.of(context).textTheme.bodySmall,
        )
      else
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.medium,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (final (index, entry) in entries.indexed) ...[
                if (index > 0) const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const NexoIcon(
                        NexoGlyph.moderation,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          entry,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
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
