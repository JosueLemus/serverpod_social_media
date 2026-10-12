import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/nexo_mascot.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/sticker.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../profile/presentation/bloc/follow_cubit.dart';
import '../../../profile/presentation/utils/profile_notice_ui.dart';
import '../../domain/entities/live_session.dart';
import '../bloc/live_media_cubit.dart';
import '../bloc/live_room_cubit.dart';
import '../utils/live_room_issue_ui.dart';
import '../utils/live_status_ui.dart';
import '../widgets/live_chat.dart';
import '../widgets/live_media_sync.dart';
import '../widgets/live_video_surface.dart';

/// La vista de audiencia de una sesión.
///
/// Es la única pantalla inmersiva de la app: el video ocupa todo y el chrome
/// flota encima. El chat no vive en una hoja blanca debajo del video —
/// partir la pantalla en dos deja el video del tamaño de una miniatura, que es
/// lo contrario de lo que alguien viene a hacer acá.
class LiveRoomPage extends StatelessWidget {
  const LiveRoomPage({super.key, required this.liveId});

  final String liveId;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => LiveRoomCubit(sl(), sl())..load(liveId)),
      BlocProvider(create: (_) => sl<LiveMediaCubit>()),
    ],
    child: BlocListener<LiveRoomCubit, LiveRoomState>(
      // El host no mira su propio vivo como audiencia: llega acá desde una
      // notificación o un enlace, y lo que busca es su Studio.
      // Un replay propio sí se mira como cualquiera.
      listenWhen: (previous, current) =>
          previous.role != current.role &&
          current.role == LiveRole.host &&
          (current.session?.status.isOnAir == true ||
              current.session?.status == LiveStatus.scheduled),
      listener: (context, state) => context.go(AppRoutes.studio),
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
  // La vista es dueña del controller; el cubit es dueño de los mensajes. Un
  // controller dentro de un cubit ata un objeto de UI desechable a un estado
  // que sobrevive a la pantalla.
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

  void _leave() => context.go(AppRoutes.explore);

  /// Atrás de verdad cuando se llegó empujando (desde el feed o un perfil);
  /// si la sala se abrió directo, Explorar es el único "atrás" que existe.
  void _back() => context.canPop() ? context.pop() : _leave();

  @override
  Widget build(
    BuildContext context,
  ) => BlocListener<LiveRoomCubit, LiveRoomState>(
    // Un rechazo del servidor se avisa una vez, en el momento. No es parte de
    // lo que la sala dibuja, así que no vive en el builder.
    listenWhen: (previous, current) =>
        current.issue != null && previous.issueSerial != current.issueSerial,
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
        if (session == null) {
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

        final ending = _RoomEnding.of(session.status);
        return Scaffold(
          backgroundColor: AppColors.stageDark,
          // El teclado no debe redimensionar el video: con resize, escribir
          // un comentario encoge la transmisión a una franja.
          resizeToAvoidBottomInset: false,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const LiveVideoSurface(
                role: LiveMediaRole.audience,
                fallback: _Stage(),
              ),
              const _StageScrim(),
              // Terminado: un velo parejo sobre el último cuadro. La sala no
              // se queda congelada como si siguiera al aire.
              if (ending != null)
                const IgnorePointer(
                  child: ColoredBox(color: AppColors.stageScrim),
                ),
              SafeArea(
                child: Column(
                  children: [
                    _RoomTopBar(session: session, onLeave: _leave),
                    // Se cortó el tiempo real: decirlo, en vez de dejar un
                    // chat que parece vivo y no recibe nada.
                    if (state.reconnecting && ending == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          // Ámbar: "mirá esto", no un fallo. La sala sigue
                          // ahí y vuelve sola.
                          child: StatusBadge(
                            key: Key('live-reconnecting'),
                            label: 'RECONECTANDO',
                            color: AppColors.warning,
                            foreground: AppColors.ink,
                            glyph: NexoGlyph.refresh,
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (ending != null) ...[
                      _EndedPanel(
                        session: session,
                        ending: ending,
                        onBack: _back,
                        onMore: _leave,
                      ),
                      const Spacer(),
                    ] else ...[
                      if (state.pinnedComment != null)
                        _PinnedComment(comment: state.pinnedComment!),
                      LiveChatOverlay(
                        comments: state.comments,
                        hostId: session.hostId,
                      ),
                      LiveChatComposer(
                        controller: _composer,
                        onSend: _send,
                        trailing: [
                          // Sin regalos todavía: apagado, no escondido.
                          const LiveGlassButton(
                            glyph: NexoGlyph.gift,
                            tooltip: 'Regalos: muy pronto',
                            onTap: null,
                          ),
                          _LoveButton(
                            loved: state.loved,
                            onTap: context.read<LiveRoomCubit>().toggleLove,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// El video. Simulado y dicho con todas las letras: Agora llega detrás de
/// `LiveMediaGateway`, y una superficie que pretende ser una transmisión real
/// hace que nadie note que no lo es.
class _Stage extends StatelessWidget {
  const _Stage();

  @override
  Widget build(BuildContext context) {
    // Con Agora activo esto es la sala antes de que llegue la señal, y no
    // tiene que decir "simulada": lo que se espera es video real.
    final simulated = context.read<LiveMediaCubit>().engine.isSimulated;
    // Un poco por encima del centro: la mitad de abajo es del chat.
    return LiveStagePlaceholder(
      alignment: const Alignment(0, -.15),
      caption: simulated ? 'Transmisión simulada' : null,
    );
  }
}

/// Degradados arriba y abajo. El chrome va sobre video, y sin el velo su
/// legibilidad depende de lo que esté pasando en la imagen — o sea, cambia
/// frame a frame.
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
  /// cerrar: en la misma fila le dejaban al host un hueco donde ni el nombre
  /// ni la insignia de EN VIVO se leían.
  static const _stackBelow = 360.0;

  @override
  Widget build(BuildContext context) {
    final close = LiveGlassButton(
      glyph: NexoGlyph.close,
      tooltip: 'Salir del vivo',
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

/// Cuánta gente mira. Cifras tabulares: un contador que cambia cada pocos
/// segundos no puede hacer saltar la cápsula de ancho.
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
          const NexoIcon(
            NexoGlyph.community,
            size: 16,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 5),
          Text(
            compactCount(viewers),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Quién transmite, con el botón de seguir al lado. La cápsula se ajusta al
/// contenido (`MainAxisSize.min`) para no ocupar toda la fila sobre el video.
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
            // Al aire, el avatar lleva el foil: es la marca de "está
            // pasando ahora" en toda la app.
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
                      color: AppColors.textPrimary,
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

/// Seguir al host sin salir del vivo. No se ofrece hasta saber si ya se lo
/// sigue, ni a quien es el host.
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
                // Se ve compacto dentro de la cápsula, pero el área de toque
                // sigue siendo la de un control: 48.
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.padded,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                // Siguiendo vuelve a pegarse a la plancha: el botón ya hizo
                // lo suyo, y el sticker blanco queda para la acción.
                backgroundColor: state.following ? AppColors.linerHigh : null,
                foregroundColor: state.following ? AppColors.textPrimary : null,
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

/// El mensaje fijado por moderación. Va **arriba** del chat y con su propia
/// etiqueta: sin ella se lee como un comentario más y se pierde entre los que
/// van pasando.
class _PinnedComment extends StatelessWidget {
  const _PinnedComment({required this.comment});

  final LiveComment comment;

  /// Un sticker blanco pegado sobre el chat, con su etiqueta pegada a mano en
  /// la esquina: es lo único del chat que no pasa, así que es lo único que se
  /// ve como un objeto.
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: StickerCard(
                radius: 18,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: _PinnedBody(comment: comment),
              ),
            ),
            const Positioned(
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
  );
}

/// Lo de adentro del sticker fijado. Va en su propio widget para leer el tema
/// **dentro** de la [StickerCard], que lo pasa a tinta: leído afuera, el texto
/// saldría claro sobre blanco.
class _PinnedBody extends StatelessWidget {
  const _PinnedBody({required this.comment});

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

class _LoveButton extends StatelessWidget {
  const _LoveButton({required this.loved, required this.onTap});

  final bool loved;
  final VoidCallback onTap;

  /// Dar amor pega un sticker: el corazón aterriza con el slap de [Pop] y el
  /// disco se vuelve rojo de reacción con su troquel blanco.
  @override
  Widget build(BuildContext context) => LiveGlassButton(
    key: const Key('live-love'),
    glyph: NexoGlyph.heart,
    tooltip: 'Dar amor',
    onTap: onTap,
    background: loved ? AppColors.secondary : null,
    child: Pop(
      trigger: loved,
      child: NexoIcon(
        NexoGlyph.heart,
        filled: loved,
        size: 22,
        color: AppColors.sticker,
      ),
    ),
  );
}

/// Por qué la sala ya no está al aire. La copy la elige la View; el estado
/// sólo dice qué pasó.
enum _RoomEnding {
  finished,
  cancelled,
  failed,
  removed;

  /// Null mientras el vivo no terminó: programado (la sala de espera) o al
  /// aire.
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

/// Lo que ve quien se quedó mirando hasta el final: quién era, cuánto duró y
/// a dónde ir. Como en cualquier red social, el final se dice; una sala que
/// sólo deja de moverse se lee como que se colgó la app.
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
            // Sin foil: terminado es el troquel blanco de siempre. El holo
            // dice "está pasando ahora", y ya no pasa.
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
              ).textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              [host, ?lasted].join(' · '),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
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

  /// "Duró 12 min", o null cuando el servidor no dice cuándo empezó o
  /// terminó (un vivo cancelado antes de salir al aire, el mock).
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
