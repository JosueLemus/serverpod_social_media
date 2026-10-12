import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/live_session.dart';
import '../bloc/live_media_cubit.dart';
import '../bloc/live_room_cubit.dart';
import '../utils/live_room_issue_ui.dart';
import '../utils/live_status_ui.dart';
import '../widgets/live_card.dart';
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
    child: const LiveMediaSync(
      role: LiveMediaRole.audience,
      child: _RoomView(),
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
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final session = state.session;
        if (session != null && session.endedByModeration) {
          return Scaffold(
            appBar: AppBar(),
            body: AppEmptyView(
              icon: Icons.gpp_maybe_outlined,
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
              icon: Icons.videocam_off_outlined,
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
                          child: StatusBadge(
                            key: Key('live-reconnecting'),
                            label: 'RECONECTANDO',
                            color: AppColors.neutral,
                            icon: Icons.sync_rounded,
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
                      LiveChatOverlay(comments: state.comments),
                      LiveChatComposer(
                        controller: _composer,
                        onSend: _send,
                        trailing: [
                          // Sin regalos todavía: apagado, no escondido.
                          const LiveGlassButton(
                            icon: Icons.card_giftcard_rounded,
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDeep, AppColors.stageDark],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sensors_rounded, color: Colors.white38, size: 54),
            if (simulated) ...[
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Transmisión simulada',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
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

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _HostPill(session: session)),
        const SizedBox(width: AppSpacing.xs),
        ViewerPill(viewers: session.viewers, isOnAir: session.status.isOnAir),
        const SizedBox(width: AppSpacing.xs),
        LiveGlassButton(
          icon: Icons.close_rounded,
          tooltip: 'Salir del vivo',
          onTap: onLeave,
        ),
      ],
    ),
  );
}

/// Quién transmite, con el botón de seguir al lado. La cápsula se ajusta al
/// contenido (`MainAxisSize.min`) para no ocupar toda la fila sobre el video.
class _HostPill extends StatelessWidget {
  const _HostPill({required this.session});

  final LiveSession session;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.fromLTRB(4, 4, AppSpacing.xs, 4),
      decoration: BoxDecoration(
        color: AppColors.neutral.withValues(alpha: .55),
        borderRadius: AppRadii.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserAvatar(name: session.hostName, size: 30),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  session.hostName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                StatusBadge(
                  label: session.status.label,
                  color: Colors.transparent,
                  pulse: session.status.isOnAir,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            height: 28,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 28),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Seguir'),
            ),
          ),
        ],
      ),
    ),
  );
}

/// El mensaje fijado por moderación. Va **arriba** del chat y con su propia
/// etiqueta: sin ella se lee como un comentario más y se pierde entre los que
/// van pasando.
class _PinnedComment extends StatelessWidget {
  const _PinnedComment({required this.comment});

  final LiveComment comment;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.sm,
      0,
      AppSpacing.sm,
      AppSpacing.xs,
    ),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.neutral.withValues(alpha: .62),
        borderRadius: AppRadii.medium,
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.push_pin_rounded,
                size: 12,
                color: Colors.white70,
              ),
              const SizedBox(width: 5),
              Text(
                'MENSAJE FIJADO · ${comment.author}'.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            comment.body,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}

class _LoveButton extends StatelessWidget {
  const _LoveButton({required this.loved, required this.onTap});

  final bool loved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LiveGlassButton(
    key: const Key('live-love'),
    icon: loved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
    tooltip: 'Dar amor',
    onTap: onTap,
    background: loved ? AppColors.secondary : null,
    child: Pop(
      trigger: loved,
      child: Icon(
        loved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: 20,
        color: Colors.white,
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
            UserAvatar(name: session.hostName, size: 64),
            const SizedBox(height: AppSpacing.sm),
            Text(
              ending.title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              [host, ?lasted].join(' · '),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                OutlinedButton(
                  key: const Key('live-ended-back'),
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                  ),
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
