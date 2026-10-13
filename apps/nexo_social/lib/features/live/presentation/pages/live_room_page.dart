import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/nexo_mascot.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/media_stage_theme.dart';
import '../../../../core/widgets/sticker.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../profile/presentation/bloc/follow_cubit.dart';
import '../../../profile/presentation/utils/profile_notice_ui.dart';
import '../../domain/entities/live_moderation.dart';
import '../../domain/entities/live_permissions.dart';
import '../../domain/entities/live_session.dart';
import '../../domain/entities/live_stage.dart';
import '../bloc/live_media_cubit.dart';
import '../bloc/live_room_cubit.dart';
import '../utils/live_navigation.dart';
import '../utils/live_role_ui.dart';
import '../utils/live_room_issue_ui.dart';
import '../utils/live_status_ui.dart';
import '../widgets/live_chat.dart';
import '../widgets/live_host_end_sheet.dart';
import '../widgets/live_media_sync.dart';
import '../widgets/live_person_sheet.dart';
import '../widgets/live_reactions.dart';
import '../widgets/live_video_surface.dart';

/// La sala tipo podcast (SDD 0011, Etapa 4).
///
/// Es la única pantalla inmersiva de la app: el video del escenario ocupa todo
/// y el chrome flota encima. **Audio primero** (S3): la cámara es opcional,
/// así que la pantalla cambia su foco cuando alguien la prende, pero por
/// defecto se parece a un episodio de podcast en vivo — un host, invitados y
/// oyentes que piden la palabra.
class LiveRoomPage extends StatelessWidget {
  const LiveRoomPage({super.key, required this.liveId});

  final String liveId;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) =>
            LiveRoomCubit(sl(), sl(), subscriptions: sl())..load(liveId),
      ),
      BlocProvider(create: (_) => sl<LiveMediaCubit>()),
    ],
    child: BlocListener<LiveRoomCubit, LiveRoomState>(
      // El host no mira su propio vivo como audiencia: llega acá desde una
      // notificación o un enlace, y lo que busca es su Studio.
      // Un replay propio sí se mira como cualquiera.
      //
      // Antes de irse deja de escuchar: el branch de Inicio conserva esta
      // página montada, y seguía contando al host como espectador de sí
      // mismo.
      listenWhen: (previous, current) =>
          previous.role != current.role &&
          current.role == LiveRole.host &&
          !current.handedOff &&
          (current.session?.status.isOnAir == true ||
              current.session?.status == LiveStatus.scheduled),
      listener: (context, state) {
        context.read<LiveRoomCubit>().handOffToStudio();
        context.go(studioRouteFor(state.session!));
      },
      child: const LiveMediaSync(
        role: LiveMediaRole.audience,
        child: _RoomView(),
      ),
    ),
  );
}

class _RoomView extends StatefulWidget {
  const _RoomView();

  @override
  State<_RoomView> createState() => _RoomViewState();
}

class _RoomViewState extends State<_RoomView> {
  // La vista es dueña del controller; el cubit es dueño de los mensajes.
  final _composer = TextEditingController();
  // Avisado una vez por evento: subir y bajar del escenario se anuncian con un
  // snackbar pegado al cambio de rol, no en cada rebuild.
  LiveRole? _lastRole;

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  /// El campo se limpia sólo si el servidor aceptó el mensaje: borrarlo
  /// antes perdía lo escrito cuando la cuenta estaba silenciada.
  Future<void> _send() async {
    final text = _composer.text;
    final sent = await context.read<LiveRoomCubit>().sendComment(text);
    if (sent && mounted && _composer.text == text) _composer.clear();
  }

  void _leave() => context.go(AppRoutes.feed);

  /// El paywall es una tarea: se empuja sobre el shell. Al volver se
  /// pregunta de nuevo, por si la persona se sumó.
  Future<void> _becomeMember() async {
    final room = context.read<LiveRoomCubit>();
    await context.push(AppRoutes.premium);
    if (mounted) room.refreshAccess();
  }

  void _back() => context.canPop() ? context.pop() : _leave();

  /// El host no sale: elige si termina el vivo o sigue al aire. La misma hoja
  /// se usa desde la X del top bar y desde "Terminar" en la barra de acciones
  /// (D6 del SDD 0011): dos entradas, una sola confirmación — porque la
  /// decisión tiene las mismas consecuencias.
  Future<void> _leaveAsHost(LiveSession session) async {
    final cubit = context.read<LiveRoomCubit>();
    final choice = await showHostEndSheet(context);
    if (choice == HostLeaveChoice.endLive) {
      await cubit.transition(LiveStatus.recorded);
      if (!mounted) return;
      _leave();
    } else if (choice == HostLeaveChoice.leaveOnAir) {
      // "Seguir al aire" no corta la transmisión: sale de la sala y deja al
      // Studio controlándola. El Studio redirect ya corre si el host vuelve a
      // entrar como audiencia (`LiveRoomCubit.load` + listener del rol).
      _leave();
    }
    // null: el host se arrepintió y se queda.
  }


  @override
  Widget build(BuildContext context) =>
      BlocListener<LiveRoomCubit, LiveRoomState>(
        // Un rechazo del servidor se avisa una vez, en el momento. No es parte
        // de lo que la sala dibuja, así que no vive en el builder.
        listenWhen: (previous, current) =>
            current.issue != null &&
            previous.issueSerial != current.issueSerial,
        listener: (context, state) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.issue!.message))),
        child: BlocBuilder<LiveRoomCubit, LiveRoomState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Scaffold(
                backgroundColor: AppColors.stageDark,
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final session = state.session;
            if (state.exclusion != null) {
              return _ExcludedScreen(
                kind: state.exclusion!,
                onLeave: _leave,
              );
            }
            if (session != null && session.endedByModeration) {
              return Scaffold(
                appBar: AppBar(),
                body: AppEmptyView(
                  mascot: NexoMascot.shield,
                  title: 'El vivo terminó',
                  message:
                      'El equipo de Nexo finalizó esta transmisión por no '
                      'cumplir las normas de la comunidad.',
                  actionLabel: 'Ver otros vivos',
                  onAction: _leave,
                ),
              );
            }
            // El host se fue a su Studio: la sala no lo sigue escuchando, y
            // si vuelve a esta pestaña encuentra el camino, no su propio
            // vivo como espectador.
            if (state.handedOff && session != null) {
              return Scaffold(
                appBar: AppBar(),
                body: AppEmptyView(
                  key: const Key('live-handed-off'),
                  mascot: NexoMascot.mic,
                  title: 'Este vivo es tuyo',
                  message: 'Lo manejas desde tu Studio.',
                  actionLabel: 'Ir a mi Studio',
                  onAction: () => context.go(studioRouteFor(session)),
                ),
              );
            }
            if (session == null) {
              // Sin foto y sin `notFound` la sala todavía no llegó: se cortó
              // la conexión antes de la primera foto. Decir "ya no está
              // disponible" ahí mandaba a la gente fuera de un vivo que
              // seguía al aire.
              if (!state.notFound) {
                return Scaffold(
                  key: const Key('live-waiting'),
                  backgroundColor: AppColors.stageDark,
                  appBar: AppBar(),
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppSpacing.md),
                        // Sobre el escenario oscuro en cualquier tema.
                        Text(
                          'Reconectando…',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onMedia,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Scaffold(
                appBar: AppBar(),
                body: AppEmptyView(
                  mascot: NexoMascot.camera,
                  title: 'Este vivo ya no está disponible',
                  message: 'Puede haber terminado o haber sido retirado.',
                  actionLabel: 'Ver otros vivos',
                  onAction: _leave,
                ),
              );
            }
            // "Solo miembros": la sala no entra al escenario. La invitación
            // nombra al host, que es a quien uno se suma.
            if (state.locked) {
              final host = session.hostUsername.isEmpty
                  ? session.hostName
                  : '@${session.hostUsername}';
              return Scaffold(
                appBar: AppBar(),
                body: AppEmptyView(
                  key: const Key('live-members-only'),
                  mascot: NexoMascot.lock,
                  title: 'Vivo solo para miembros',
                  message:
                      'Súmate a la comunidad de $host para ver este vivo y '
                      'participar del chat.',
                  actionLabel: 'Hacerme miembro',
                  onAction: () => unawaited(_becomeMember()),
                ),
              );
            }

            // Snackbars de "subiste" / "bajaste" al escenario. Van una sola
            // vez por transición, no en cada rebuild — el cubit emite por
            // muchas razones y re-anunciar el rol que ya cambió se lee como
            // un bucle.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _announceRoleChange(context, state);
            });

            final ending = _RoomEnding.of(session.status);
            final form = AppBreakpoints.of(context);
            return MediaStageTheme(
              child: Scaffold(
                backgroundColor: AppColors.stageDark,
                // El teclado no debe redimensionar el escenario.
                resizeToAvoidBottomInset: false,
                body: Stack(
                  fit: StackFit.expand,
                  children: [
                    // El video (host) de fondo cuando lo haya; mientras no,
                    // el escenario de stickers.
                    const LiveVideoSurface(
                      role: LiveMediaRole.audience,
                      fallback: ColoredBox(color: AppColors.stageDark),
                    ),
                    const _StageScrim(),
                    if (ending != null)
                      const IgnorePointer(
                        child: ColoredBox(color: AppColors.stageScrim),
                      ),
                    // Las reacciones flotan sobre todo lo demás, dentro del
                    // Stack de la sala: no pueden salir de la pantalla y, al
                    // estar en IgnorePointer, no comen taps del chrome.
                    const LiveReactionsOverlay(),
                    SafeArea(
                      child: Column(
                        children: [
                          _RoomTopBar(
                            session: session,
                            // El host confirma antes de salir; el resto sale
                            // directo. La hoja decide qué pasa con el vivo.
                            onLeave: state.role == LiveRole.host &&
                                    session.status.isOnAir
                                ? () => unawaited(_leaveAsHost(session))
                                : _leave,
                          ),
                          if (state.reconnecting && ending == null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: StatusBadge(
                                  key: const Key('live-reconnecting'),
                                  label: 'RECONECTANDO',
                                  color: AppColors.warning,
                                  foreground: AppColors.ink,
                                  glyph: NexoGlyph.refresh,
                                ),
                              ),
                            ),
                          if (ending != null) ...[
                            const Spacer(),
                            _EndedPanel(
                              session: session,
                              ending: ending,
                              onBack: _back,
                              onMore: _leave,
                            ),
                            const Spacer(),
                          ] else
                            Expanded(
                              child: _LiveBody(
                                session: session,
                                state: state,
                                form: form,
                                composer: _composer,
                                onSend: _send,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

  void _announceRoleChange(BuildContext context, LiveRoomState state) {
    final role = state.role;
    final previous = _lastRole;
    _lastRole = role;
    if (previous == null || previous == role) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final message = switch (role) {
      LiveRole.cohost when previous == LiveRole.audience =>
        'Estás en el escenario. Tu micrófono está abierto.',
      LiveRole.moderator when previous != LiveRole.moderator =>
        'Ahora moderas esta sala.',
      LiveRole.audience when previous == LiveRole.cohost =>
        'Bajaste del escenario.',
      LiveRole.audience when previous == LiveRole.moderator =>
        'Ya no moderas esta sala.',
      _ => null,
    };
    if (message == null) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// El cuerpo entre la barra de arriba y el borde inferior.
///
/// Compact: escenario + chat sobre el video + barra de acciones abajo. Panel
/// lateral del chat en escritorio (expanded): el ancho ya alcanza para
/// mostrarlo todo el tiempo.
class _LiveBody extends StatelessWidget {
  const _LiveBody({
    required this.session,
    required this.state,
    required this.form,
    required this.composer,
    required this.onSend,
  });

  final LiveSession session;
  final LiveRoomState state;
  final FormFactor form;
  final TextEditingController composer;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final highlighted = state.highlightedComment;
    final pinned = state.pinnedComment;
    final chat = _ChatPanel(
      state: state,
      session: session,
      composer: composer,
      onSend: onSend,
      pinned: pinned,
      highlighted: highlighted,
    );
    if (form.isExpanded) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: _StageArea(
                    stage: state.stage,
                    session: session,
                    myRole: state.role,
                  ),
                ),
                _ListeningRow(session: session),
                _ActionBar(state: state, session: session),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 340,
            margin: const EdgeInsets.fromLTRB(
              0,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: chat,
          ),
        ],
      );
    }
    return Column(
      children: [
        Expanded(
          child: _StageArea(
            stage: state.stage,
            session: session,
            myRole: state.role,
          ),
        ),
        _ListeningRow(session: session),
        chat,
        _ActionBar(state: state, session: session),
      ],
    );
  }
}

/// El escenario: el host destacado y la grilla de invitados.
///
/// El host va aparte y más grande para que un vivo con el host solo no se vea
/// como una grilla rota; a partir del primer invitado, aparece la grilla
/// debajo.
class _StageArea extends StatelessWidget {
  const _StageArea({
    required this.stage,
    required this.session,
    required this.myRole,
  });

  final LiveStage stage;
  final LiveSession session;
  final LiveRole myRole;

  @override
  Widget build(BuildContext context) {
    final host = stage.speakers
        .where((s) => s.role == LiveRole.host)
        .firstOrNull;
    final others = stage.speakers.where((s) => s.role != LiveRole.host).toList();
    final hostTile = _StageTile(
      key: const Key('stage-host'),
      speaker: host ??
          LiveSpeaker(
            userId: session.hostId,
            name: session.hostName,
            username: session.hostUsername,
            role: LiveRole.host,
            avatarUrl: session.hostAvatarUrl,
          ),
      size: 128,
      onLongPress: () => _openPersonSheet(
        context,
        host?.userId ?? session.hostId,
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Center(child: hostTile),
            if (others.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _GuestsGrid(
                guests: others,
                onLongPress: (userId) => _openPersonSheet(context, userId),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> _openPersonSheet(
  BuildContext context,
  String userId, {
  LiveComment? comment,
}) async {
  final cubit = context.read<LiveRoomCubit>();
  final state = cubit.state;
  final speaker = state.stage.speakers
      .where((s) => s.userId == userId)
      .firstOrNull;
  final hand = state.stage.hands
      .where((h) => h.userId == userId)
      .firstOrNull;
  // Si no está en el escenario ni pidió palabra, se trata como oyente — pero
  // igual se abre la hoja: desde el chat, es la única forma de aplicarle una
  // sanción a quien escribió un comentario.
  final person = _personFor(
    userId: userId,
    speaker: speaker,
    hand: hand,
    comment: comment,
  );
  if (person == null) return;
  final decision = await showLivePersonSheet(
    context,
    person: person,
    actorRole: state.role,
    comment: comment,
    pinnedIsThis:
        comment != null && state.pinnedComment?.id == comment.id,
    highlightedIsThis:
        comment != null && state.highlightedComment?.id == comment.id,
  );
  if (decision == null) return;
  await _applyDecision(cubit, person.userId, decision);
}

LivePerson? _personFor({
  required String userId,
  required LiveSpeaker? speaker,
  required LiveHand? hand,
  required LiveComment? comment,
}) {
  if (speaker != null) {
    return LivePerson(
      userId: speaker.userId,
      name: speaker.name,
      username: speaker.username,
      avatarUrl: speaker.avatarUrl,
      role: speaker.role,
      onStage: true,
      micMuted: speaker.micMuted,
      isModerator: speaker.role == LiveRole.moderator,
    );
  }
  if (hand != null) {
    return LivePerson(
      userId: hand.userId,
      name: hand.name,
      username: hand.username,
      avatarUrl: hand.avatarUrl,
      role: LiveRole.audience,
      handRaised: true,
    );
  }
  if (comment != null) {
    return LivePerson(
      userId: comment.authorId,
      name: comment.author,
      username: '',
      avatarUrl: comment.authorAvatarUrl,
      role: LiveRole.audience,
    );
  }
  return null;
}

Future<void> _applyDecision(
  LiveRoomCubit cubit,
  String userId,
  LivePersonDecision decision,
) async {
  switch (decision) {
    case ApproveHandDecision():
      await cubit.approveRequest(userId);
    case DenyHandDecision():
      await cubit.denyRequest(userId);
    case InviteToStageDecision():
      await cubit.inviteToStage(userId);
    case RemoveFromStageDecision():
      await cubit.removeFromStage(userId);
    case MuteMicDecision():
      await cubit.muteSpeaker(userId);
    case MuteChatDecision(:final duration):
      await cubit.muteInChat(userId, duration);
    case KickDecision():
      await cubit.kick(userId);
    case BanDecision():
      await cubit.ban(userId);
    case AssignModeratorDecision(:final assign):
      await cubit.assignModerator(assign ? userId : null);
    case HideCommentDecision(:final comment):
      await cubit.hideComment(comment);
    case UnhideCommentDecision(:final comment):
      await cubit.unhideComment(comment.id);
    case DeleteCommentDecision(:final comment):
      await cubit.deleteComment(comment);
    case PinCommentDecision(:final comment):
      await cubit.pinComment(comment);
    case UnpinCommentDecision():
      await cubit.pinComment(null);
    case HighlightCommentDecision(:final comment):
      await cubit.highlightQuestion(comment);
    case UnhighlightCommentDecision():
      await cubit.highlightQuestion(null);
  }
}

class _GuestsGrid extends StatelessWidget {
  const _GuestsGrid({required this.guests, required this.onLongPress});

  final List<LiveSpeaker> guests;
  final ValueChanged<String> onLongPress;

  @override
  Widget build(BuildContext context) {
    final form = AppBreakpoints.of(context);
    final columns = switch (form) {
      FormFactor.compact => 4,
      FormFactor.medium => 5,
      FormFactor.expanded => 6,
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = AppSpacing.xs;
        final slot =
            ((constraints.maxWidth - gap * (columns - 1)) / columns).floorToDouble();
        return Wrap(
          spacing: gap,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: [
            for (final guest in guests)
              SizedBox(
                width: slot,
                child: _StageTile(
                  key: Key('stage-${guest.userId}'),
                  speaker: guest,
                  size: slot - 8,
                  onLongPress: () => onLongPress(guest.userId),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Una ficha del escenario.
///
/// Audio primero: por defecto es un avatar con el nombre. Cuando [speaker]
/// prende la cámara, el tile se vuelve video —el placeholder por ahora, el
/// video real llega con Agora en la Etapa 6—. El anillo que late lo decidirá
/// el indicador de "quién habla" cuando Agora lo emita (Etapa 6); hoy no hay
/// fuente de niveles de audio y **no inventamos uno**: el tile se queda sin
/// anillo salvo el foil del host.
class _StageTile extends StatelessWidget {
  const _StageTile({
    super.key,
    required this.speaker,
    required this.size,
    this.onLongPress,
  });

  final LiveSpeaker speaker;
  final double size;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final avatar = UserAvatar(
      name: speaker.name,
      imageUrl: speaker.avatarUrl,
      size: size,
      // El foil para el host; el resto del escenario queda sin anillo. Cuando
      // Agora emita niveles de audio (Etapa 6), un anillo que late se agrega
      // acá.
      onAir: speaker.role == LiveRole.host,
    );
    return InkWell(
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(size / 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                avatar,
                // El micrófono apagado se pega en la esquina, igual que la
                // insignia de un sticker.
                if (speaker.micMuted)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _IconPill(
                      key: const Key('tile-mic-muted'),
                      glyph: NexoGlyph.micOff,
                      background: AppColors.warning,
                      foreground: AppColors.ink,
                    ),
                  ),
                // La cámara prendida es sólo una marca por ahora: el video
                // real llega con Agora. La demo no finge una transmisión.
                if (speaker.cameraOn && !speaker.micMuted)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _IconPill(
                      key: const Key('tile-camera'),
                      glyph: NexoGlyph.media,
                      background: AppColors.secondary,
                      foreground: AppColors.onSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            speaker.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: text.labelMedium?.copyWith(color: AppColors.onMedia),
          ),
          if (speaker.role != LiveRole.cohost) ...[
            const SizedBox(height: 2),
            StatusBadge(
              label: speaker.role.label,
              color: speaker.role == LiveRole.host
                  ? AppColors.secondary
                  : AppColors.vinylCyan,
              foreground: speaker.role == LiveRole.host
                  ? AppColors.onSecondary
                  : AppColors.ink,
            ),
          ],
        ],
      ),
    );
  }
}

class _IconPill extends StatelessWidget {
  const _IconPill({
    super.key,
    required this.glyph,
    required this.background,
    required this.foreground,
  });

  final NexoGlyph glyph;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: background,
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.stageDark, width: 2),
    ),
    child: NexoIcon(glyph, filled: true, size: 11, color: foreground),
  );
}

/// Debajo del escenario: cuántos oyen. No listamos avatares de oyentes porque
/// el servidor no manda esa lista — inventar nombres sería un dato falso.
class _ListeningRow extends StatelessWidget {
  const _ListeningRow({required this.session});

  final LiveSession session;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          NexoIcon(
            NexoGlyph.community,
            size: 16,
            color: AppColors.onMediaSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            '${compactCount(session.viewers)} escuchando',
            style: text.labelMedium?.copyWith(
              color: AppColors.onMediaSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lo que puede hacer quien está mirando — distinto para cada rol.
///
/// Decide con [state.can] y [state.isOnStage]: la tabla de permisos y el
/// escenario son las dos preguntas que definen qué controles aparecen.
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.state, required this.session});

  final LiveRoomState state;
  final LiveSession session;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LiveRoomCubit>();
    final me = state.stage.me;
    final onStage = state.isOnStage;
    final canRaise = state.can(LiveAction.raiseHand) && !onStage;
    final showHandsQueue = state.can(LiveAction.approveRequest);
    final hands = state.stage.hands;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (onStage && me != null) ...[
            LiveLabeledGlassButton(
              key: const Key('room-mic'),
              // El micrófono prende/apaga con un único control; su estado se
              // lee del color y del glifo, no de dos botones.
              glyph: me.micMuted ? NexoGlyph.micOff : NexoGlyph.mic,
              label: me.micMuted ? 'Prender micrófono' : 'Silenciar',
              onTap: () => unawaited(cubit.toggleMyMic()),
              background: me.micMuted ? AppColors.warning : null,
            ),
            LiveLabeledGlassButton(
              key: const Key('room-camera'),
              glyph: NexoGlyph.media,
              label: me.cameraOn ? 'Apagar cámara' : 'Prender cámara',
              onTap: () => unawaited(cubit.toggleMyCamera()),
              background: me.cameraOn ? AppColors.secondary : null,
            ),
            LiveLabeledGlassButton(
              key: const Key('room-leave-stage'),
              glyph: NexoGlyph.logout,
              label: 'Bajarme',
              onTap: () => unawaited(cubit.leaveStage()),
            ),
          ] else if (canRaise)
            if (state.handRaised)
              LiveLabeledGlassButton(
                key: const Key('room-lower-hand'),
                glyph: NexoGlyph.close,
                label: 'Bajar la mano',
                onTap: () => unawaited(cubit.lowerHand()),
                background: AppColors.warning,
              )
            else
              LiveLabeledGlassButton(
                key: const Key('room-raise-hand'),
                // Reusamos el glifo del micrófono para "pedir la palabra" —
                // el set de íconos no tiene mano todavía—, pero con **texto
                // visible** no se confunde con el micrófono del escenario:
                // ese otro vive adentro de otra rama de este `if` y además
                // dice "Silenciar" o "Prender micrófono". La etiqueta deshace
                // la ambigüedad que tenía la versión sin texto.
                glyph: NexoGlyph.mic,
                label: 'Pedir la palabra',
                onTap: () => unawaited(cubit.raiseHand()),
              ),
          // Reacciones efímeras: todos pueden mandar (D7 del SDD 0011).
          // El permiso vuelve a chequearse en el servidor; acá sólo se
          // dibuja el control cuando el rol lo tiene en su repertorio.
          if (state.can(LiveAction.react))
            LiveLabeledGlassButton(
              key: const Key('room-react'),
              glyph: NexoGlyph.heart,
              label: 'Reaccionar',
              onTap: () => unawaited(_openReactionsSheet(context)),
            ),
          if (showHandsQueue)
            _HandsButton(
              hands: hands,
              onOpen: () => unawaited(_openHandsSheet(context)),
            ),
          if (state.can(LiveAction.end) && session.status.isOnAir)
            LiveLabeledGlassButton(
              key: const Key('room-end'),
              glyph: NexoGlyph.close,
              label: 'Terminar',
              // El host confirma antes de cortar: terminar un vivo tiene
              // consecuencias y no puede ser un tap suelto.
              onTap: () => unawaited(_confirmAndEnd(context)),
              background: AppColors.error,
            ),
        ],
      ),
    );
  }
}

/// El botón "Pedidos" con el contador de manos levantadas. Pintado como todos
/// los controles sobre video: un disco de vidrio con la insignia encima.
class _HandsButton extends StatelessWidget {
  const _HandsButton({required this.hands, required this.onOpen});

  final List<LiveHand> hands;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${hands.length} pedidos de palabra',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('room-hands'),
          onTap: onOpen,
          borderRadius: AppRadii.pill,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.neutral.withValues(alpha: .55),
              borderRadius: AppRadii.pill,
              border: Border.all(
                color: AppColors.onMedia.withValues(alpha: .16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NexoIcon(
                  NexoGlyph.mic,
                  filled: true,
                  size: 18,
                  color: AppColors.onMedia,
                ),
                const SizedBox(width: 6),
                Text(
                  'Pedidos · ${hands.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onMedia,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El tap de "Terminar" en la barra de acciones. Reusa la misma hoja que
/// "Salir" del host, pero con una sola opción: no hay otro resultado del
/// gesto en esta rama.
Future<void> _confirmAndEnd(BuildContext context) async {
  final cubit = context.read<LiveRoomCubit>();
  final choice = await showHostEndSheet(context, endOnly: true);
  if (choice == HostLeaveChoice.endLive) {
    await cubit.transition(LiveStatus.recorded);
  }
}

/// Abre el picker de reacciones. Lo que elija el usuario viaja al cubit
/// (que luego hablará con el servidor); además, lo publicamos localmente al
/// bus para que el emoji flote **ya**, sin esperar el eco. El día que el
/// servidor emita `reaction`, el bus sigue siendo el mismo canal y la
/// publicación local se saca.
Future<void> _openReactionsSheet(BuildContext context) async {
  final cubit = context.read<LiveRoomCubit>();
  await showReactionsSheet(
    context,
    onPick: (kind) {
      LiveReactionBus.instance.publish(kind);
      unawaited(cubit.react(kind));
    },
  );
}

Future<void> _openHandsSheet(BuildContext context) async {
  final cubit = context.read<LiveRoomCubit>();
  final state = cubit.state;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    // El bottom sheet se monta en el navigator raíz: su árbol no cuelga del
    // provider que creó la sala, así que hay que pasarlo con `.value` o la
    // hoja no encuentra el cubit al tocar "Subir al escenario".
    builder: (sheetContext) => BlocProvider.value(
      value: cubit,
      child: _HandsSheet(
        hands: state.stage.hands,
        // Aprobar un pedido es `approveRequest`, no `inviteToStage`: el host
        // y el moderador aprueban, el host además puede invitar directo. La
        // cola es sobre aprobar, así que el gate del botón es ése.
        canApprove: state.can(LiveAction.approveRequest),
      ),
    ),
  );
}

class _HandsSheet extends StatelessWidget {
  const _HandsSheet({required this.hands, required this.canApprove});

  final List<LiveHand> hands;
  final bool canApprove;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LiveRoomCubit>();
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Piden la palabra', style: text.titleLarge),
            Text(
              hands.isEmpty
                  ? 'La cola está vacía.'
                  : '${hands.length} personas quieren subir al escenario.',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (hands.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(
                  child: Text(
                    'Nadie pidió la palabra todavía.',
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              for (final hand in hands)
                _HandRow(
                  key: Key('hand-${hand.userId}'),
                  hand: hand,
                  canApprove: canApprove,
                  onApprove: () async {
                    Navigator.of(context).pop();
                    await cubit.approveRequest(hand.userId);
                  },
                  onDeny: () async {
                    Navigator.of(context).pop();
                    await cubit.denyRequest(hand.userId);
                  },
                ),
          ],
        ),
      ),
    );
  }
}

class _HandRow extends StatelessWidget {
  const _HandRow({
    super.key,
    required this.hand,
    required this.canApprove,
    required this.onApprove,
    required this.onDeny,
  });

  final LiveHand hand;
  final bool canApprove;
  final VoidCallback onApprove;
  final VoidCallback onDeny;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            name: hand.name,
            imageUrl: hand.avatarUrl,
            size: 44,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hand.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium,
                ),
                if (hand.username.isNotEmpty)
                  Text('@${hand.username}', style: text.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (canApprove)
                      FilledButton(
                        key: Key('approve-${hand.userId}'),
                        onPressed: onApprove,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(
                            0,
                            AppSizes.buttonHeightDense,
                          ),
                        ),
                        child: const Text('Subir al escenario'),
                      ),
                    OutlinedButton(
                      key: Key('deny-${hand.userId}'),
                      onPressed: onDeny,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, AppSizes.buttonHeightDense),
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
    );
  }
}

/// El chat con los dos anclajes arriba. En compact va sobre el video; en
/// expanded, en el panel lateral.
class _ChatPanel extends StatelessWidget {
  const _ChatPanel({
    required this.state,
    required this.session,
    required this.composer,
    required this.onSend,
    required this.pinned,
    required this.highlighted,
  });

  final LiveRoomState state;
  final LiveSession session;
  final TextEditingController composer;
  final VoidCallback onSend;
  final LiveComment? pinned;
  final LiveComment? highlighted;

  @override
  Widget build(BuildContext context) {
    final chat = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (highlighted != null)
          _HighlightedComment(
            comment: highlighted!,
            onLongPress: () => _openPersonSheet(
              context,
              highlighted!.authorId,
              comment: highlighted,
            ),
          ),
        if (pinned != null)
          _PinnedComment(
            comment: pinned!,
            onLongPress: () => _openPersonSheet(
              context,
              pinned!.authorId,
              comment: pinned,
            ),
          ),
        _ChatMessages(
          state: state,
          hostId: session.hostId,
        ),
        _ComposerOrMuteNotice(
          state: state,
          composer: composer,
          onSend: onSend,
        ),
      ],
    );
    return chat;
  }
}

class _ChatMessages extends StatelessWidget {
  const _ChatMessages({required this.state, required this.hostId});

  final LiveRoomState state;
  final String hostId;

  @override
  Widget build(BuildContext context) {
    final form = AppBreakpoints.of(context);
    // En expanded el chat vive en una columna propia, así que puede ocupar
    // casi todo el alto; en compact comparte el ancho con el escenario y se
    // queda en un tercio para no comerse el video.
    final maxHeight = form.isExpanded
        ? MediaQuery.sizeOf(context).height * .55
        : MediaQuery.sizeOf(context).height * .3;
    return LiveChatOverlay(
      comments: state.comments,
      hostId: hostId,
      maxHeight: maxHeight,
      onLongPress: (comment) =>
          _openPersonSheet(context, comment.authorId, comment: comment),
    );
  }
}

/// Si estás silenciado, el campo se reemplaza por el aviso; si no, el
/// compositor normal. "Hasta cuándo" sale del `until`: null = "resto del
/// vivo". El silencio vence solo porque `LiveChatMute.activeAt` lo decide, y
/// el cubit limpia el estado cuando llega el evento.
class _ComposerOrMuteNotice extends StatelessWidget {
  const _ComposerOrMuteNotice({
    required this.state,
    required this.composer,
    required this.onSend,
  });

  final LiveRoomState state;
  final TextEditingController composer;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final mute = state.myMute;
    if (mute != null) {
      return _MuteBanner(key: const Key('room-mute-banner'), mute: mute);
    }
    // Con las preguntas apagadas por el host, el campo no se ofrece: se dice
    // por qué, y la participación queda en subir al escenario o reaccionar.
    return LiveChatComposer(
      controller: composer,
      onSend: onSend,
      disabledNotice: state.canComment
          ? null
          : 'El host desactivó los comentarios',
    );
  }
}

class _MuteBanner extends StatelessWidget {
  const _MuteBanner({super.key, required this.mute});

  final LiveChatMute mute;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final until = mute.until;
    final suffix = until == null
        ? 'hasta que termine el vivo'
        : 'por unos minutos más';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.neutral.withValues(alpha: .55),
          borderRadius: AppRadii.medium,
          border: Border.all(color: AppColors.warning, width: 1.5),
        ),
        child: Row(
          children: [
            NexoIcon(
              NexoGlyph.lock,
              filled: true,
              size: 18,
              color: AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Estás silenciado en este vivo $suffix.',
                style: text.bodyMedium?.copyWith(color: AppColors.onMedia),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fuera de la sala: una pantalla propia con la mascota. Reemplaza al chat y
/// al escenario — insistir con reconectar sería pedirle al servidor que
/// repita el "no".
class _ExcludedScreen extends StatelessWidget {
  const _ExcludedScreen({required this.kind, required this.onLeave});

  final LiveSanctionKind kind;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final title = switch (kind) {
      LiveSanctionKind.kick => 'Te sacaron de este vivo',
      LiveSanctionKind.ban => 'El host te bloqueó de sus vivos',
      LiveSanctionKind.chatMute => 'Estás silenciado',
    };
    final message = switch (kind) {
      LiveSanctionKind.kick =>
        'Puedes volver a entrar cuando el host inicie otro vivo.',
      LiveSanctionKind.ban =>
        'No podrás entrar a los vivos de este host hasta que levante el bloqueo.',
      LiveSanctionKind.chatMute =>
        'Puedes seguir mirando, pero no comentar durante este vivo.',
    };
    return Scaffold(
      appBar: AppBar(),
      body: AppEmptyView(
        key: const Key('live-excluded'),
        mascot: NexoMascot.shield,
        title: title,
        message: message,
        actionLabel: 'Ver otros vivos',
        onAction: onLeave,
      ),
    );
  }
}

/// Degradados arriba y abajo, para que el chrome sobre video siga siendo
/// legible aunque cambie lo que haya en la imagen.
class _StageScrim extends StatelessWidget {
  const _StageScrim();

  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.stageScrim,
            Colors.transparent,
            Colors.transparent,
            AppColors.stageScrim,
          ],
          stops: [0, .22, .5, 1],
        ),
      ),
    ),
  );
}

class _RoomTopBar extends StatelessWidget {
  const _RoomTopBar({required this.session, required this.onLeave});

  final LiveSession session;
  final VoidCallback onLeave;

  /// Por debajo de este ancho los espectadores bajan debajo del botón de
  /// "Salir". Antes era 360; se subió al cruzar la X por un pill con texto
  /// (D6), que es ~40 px más ancha, y en 420 el `_HostPill` se queda sin
  /// espacio para el nombre del host y su botón de seguir. El breakpoint ahora
  /// se parece al límite teléfono/tablet, que es cuando el ancho alcanza para
  /// las dos cosas en una fila.
  static const _stackBelow = 600.0;

  @override
  Widget build(BuildContext context) {
    // "Salir" con texto, no la X ambigua que confunde con "Terminar" en el
    // host (D6 del SDD 0011). La hoja de confirmación la decide el llamador —
    // acá sólo pedimos el gesto.
    final close = LiveLabeledGlassButton(
      key: const Key('room-leave'),
      glyph: NexoGlyph.close,
      label: 'Salir',
      onTap: onLeave,
    );
    final viewers = _ViewerCount(viewers: session.viewers);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < _stackBelow) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _HostPill(session: session)),
                const SizedBox(width: AppSpacing.xs),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [close, const SizedBox(height: 6), viewers],
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: _HostPill(session: session)),
              const SizedBox(width: AppSpacing.xs),
              viewers,
              const SizedBox(width: AppSpacing.xs),
              close,
            ],
          );
        },
      ),
    );
  }
}

class _ViewerCount extends StatelessWidget {
  const _ViewerCount({required this.viewers});

  final int viewers;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$viewers espectadores',
    excludeSemantics: true,
    child: LiveGlassPill(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NexoIcon(NexoGlyph.community, size: 16, color: AppColors.onMedia),
          const SizedBox(width: 5),
          Text(
            compactCount(viewers),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.onMedia,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    ),
  );
}

class _HostPill extends StatelessWidget {
  const _HostPill({required this.session});

  final LiveSession session;

  @override
  Widget build(BuildContext context) {
    final status = session.status;
    return Align(
      alignment: Alignment.centerLeft,
      child: LiveGlassPill(
        padding: const EdgeInsets.only(left: AppSpacing.xxs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(
              name: session.hostName,
              imageUrl: session.hostAvatarUrl,
              size: 30,
              onAir: status.isOnAir,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    session.hostName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.onMedia,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  StatusBadge(
                    label: status.label,
                    color: status.color,
                    foreground: status.foreground,
                    pulse: status.isOnAir,
                  ),
                ],
              ),
            ),
            _HostFollowButton(hostUsername: session.hostUsername),
            const SizedBox(width: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

class _HostFollowButton extends StatelessWidget {
  const _HostFollowButton({required this.hostUsername});

  final String hostUsername;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final viewer = auth is AuthAuthenticated ? auth.user.username : null;
    if (hostUsername.isEmpty || hostUsername == viewer) {
      return const SizedBox.shrink();
    }
    return BlocProvider(
      key: ValueKey(hostUsername),
      create: (_) => sl<FollowCubit>(param1: hostUsername)..load(),
      child: BlocConsumer<FollowCubit, FollowButtonState>(
        listenWhen: (previous, current) =>
            current.notice != null &&
            previous.noticeSerial != current.noticeSerial,
        listener: (context, state) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.notice!.message))),
        builder: (context, state) {
          if (!state.isReady) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: FilledButton(
              key: const Key('live-follow-host'),
              onPressed: () => unawaited(context.read<FollowCubit>().toggle()),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.padded,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                backgroundColor: state.following ? AppColors.linerHigh : null,
                foregroundColor: state.following ? AppColors.onMedia : null,
                textStyle: Theme.of(context).textTheme.labelMedium,
              ),
              child: Text(state.following ? 'Siguiendo' : 'Seguir'),
            ),
          );
        },
      ),
    );
  }
}

/// El mensaje fijado por moderación. Va arriba del chat y con su propia
/// etiqueta.
class _PinnedComment extends StatelessWidget {
  const _PinnedComment({required this.comment, this.onLongPress});

  final LiveComment comment;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.sm,
      0,
      AppSpacing.sm,
      AppSpacing.xs,
    ),
    child: Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: StickerCard(
                  radius: 18,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: _AnchoredBody(comment: comment),
                ),
              ),
              Positioned(
                top: 0,
                right: AppSpacing.md,
                child: StatusBadge(
                  label: 'Mensaje fijado',
                  color: AppColors.vinylCyan,
                  foreground: AppColors.ink,
                  tilt: .05,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// La pregunta destacada: la misma caja que un mensaje fijado, con otra
/// etiqueta. Se usa en un podcast para apuntar a la pregunta que se va a
/// contestar en vivo.
class _HighlightedComment extends StatelessWidget {
  const _HighlightedComment({required this.comment, this.onLongPress});

  final LiveComment comment;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.sm,
      0,
      AppSpacing.sm,
      AppSpacing.xs,
    ),
    child: Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: StickerCard(
                  radius: 18,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: _AnchoredBody(comment: comment),
                ),
              ),
              Positioned(
                top: 0,
                right: AppSpacing.md,
                child: StatusBadge(
                  label: 'Pregunta destacada',
                  color: AppColors.vinylLime,
                  foreground: AppColors.ink,
                  tilt: .05,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AnchoredBody extends StatelessWidget {
  const _AnchoredBody({required this.comment});

  final LiveComment comment;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAvatar(
          name: comment.author,
          imageUrl: comment.authorAvatarUrl,
          size: 30,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(comment.body, style: text.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

/// Por qué la sala ya no está al aire. La copy la elige la View; el estado
/// sólo dice qué pasó.
enum _RoomEnding {
  finished,
  cancelled,
  failed,
  removed;

  static _RoomEnding? of(LiveStatus status) => switch (status) {
    LiveStatus.recorded || LiveStatus.published => finished,
    LiveStatus.cancelled => cancelled,
    LiveStatus.failed => failed,
    LiveStatus.removed => removed,
    LiveStatus.draft ||
    LiveStatus.scheduled ||
    LiveStatus.live ||
    LiveStatus.ending => null,
  };

  String get title => switch (this) {
    finished => 'El vivo terminó',
    cancelled => 'Este vivo se canceló',
    failed => 'El vivo se cortó',
    removed => 'Este vivo ya no está disponible',
  };
}

class _EndedPanel extends StatelessWidget {
  const _EndedPanel({
    required this.session,
    required this.ending,
    required this.onBack,
    required this.onMore,
  });

  final LiveSession session;
  final _RoomEnding ending;
  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final host = session.hostUsername.isEmpty
        ? session.hostName
        : '@${session.hostUsername}';
    final lasted = _lasted(session);
    return EnterStatic(
      child: Padding(
        key: const Key('live-ended'),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(
              name: session.hostName,
              imageUrl: session.hostAvatarUrl,
              size: 72,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              ending.title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppColors.onMedia),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              [host, ?lasted].join(' · '),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onMediaSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                OutlinedButton(
                  key: const Key('live-ended-back'),
                  onPressed: onBack,
                  child: const Text('Volver'),
                ),
                FilledButton(
                  key: const Key('live-ended-more'),
                  onPressed: onMore,
                  child: const Text('Ver más vivos'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String? _lasted(LiveSession session) {
    final startedAt = session.startedAt;
    final endedAt = session.endedAt;
    if (startedAt == null || endedAt == null) return null;
    final minutes = endedAt.difference(startedAt).inMinutes;
    if (minutes < 1) return 'Duró menos de un minuto';
    if (minutes < 60) return 'Duró $minutes min';
    final rest = minutes.remainder(60);
    return rest == 0
        ? 'Duró ${minutes ~/ 60} h'
        : 'Duró ${minutes ~/ 60} h ${rest.toString().padLeft(2, '0')} min';
  }
}
