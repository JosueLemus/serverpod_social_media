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
import '../../../moderation/presentation/widgets/moderation_sheet.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../../domain/entities/live_session.dart';
import '../../domain/repositories/live_repository.dart';
import '../bloc/live_room_cubit.dart';
import '../utils/live_status_ui.dart';
import '../widgets/live_card.dart';

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
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => LiveRoomCubit(sl<LiveRepository>())..load(liveId),
    child: const _RoomView(),
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
    context.read<LiveRoomCubit>().sendComment(_composer.text);
    _composer.clear();
  }

  void _leave() => context.go(AppRoutes.explore);

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LiveRoomCubit, LiveRoomState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Scaffold(
              backgroundColor: AppColors.stageDark,
              body: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }

          final session = state.session;
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

          return Scaffold(
            backgroundColor: AppColors.stageDark,
            // El teclado no debe redimensionar el video: con resize, escribir
            // un comentario encoge la transmisión a una franja.
            resizeToAvoidBottomInset: false,
            body: Stack(
              fit: StackFit.expand,
              children: [
                const _Stage(),
                const _StageScrim(),
                SafeArea(
                  child: Column(
                    children: [
                      _RoomTopBar(session: session, onLeave: _leave),
                      const Spacer(),
                      if (state.pinnedComment != null)
                        _PinnedComment(comment: state.pinnedComment!),
                      _ChatOverlay(comments: state.comments),
                      _Composer(
                        controller: _composer,
                        loved: state.loved,
                        onSend: _send,
                        onLove: context.read<LiveRoomCubit>().toggleLove,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
}

/// El video. Simulado y dicho con todas las letras: Agora llega detrás de
/// `LiveMediaGateway`, y una superficie que pretende ser una transmisión real
/// hace que nadie note que no lo es.
class _Stage extends StatelessWidget {
  const _Stage();

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sensors_rounded, color: Colors.white38, size: 54),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Transmisión simulada',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    ),
  );
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
        _GlassIconButton(
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

/// Los comentarios, flotando sobre el video.
///
/// Alto acotado y sin fondo propio: el chat de un vivo es efímero, y un panel
/// opaco que se come media pantalla compite con lo que la gente vino a ver.
class _ChatOverlay extends StatelessWidget {
  const _ChatOverlay({required this.comments});

  final List<LiveComment> comments;

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Sé la primera persona en comentar',
            style: TextStyle(color: Colors.white54, fontSize: 12.5),
          ),
        ),
      );
    }

    return ConstrainedBox(
      // Un tercio de la pantalla como techo: el chat crece hacia arriba hasta
      // ahí y después scrollea.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .32,
      ),
      child: ListView.builder(
        // Anclado abajo, que es donde llega lo nuevo.
        reverse: true,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        itemCount: comments.length,
        itemBuilder: (context, index) =>
            _ChatLine(comment: comments[comments.length - 1 - index]),
      ),
    );
  }
}

class _ChatLine extends StatelessWidget {
  const _ChatLine({required this.comment});

  final LiveComment comment;

  /// Moderar sale de una pulsación larga sobre el mensaje, no de un ícono por
  /// fila: con seis acciones disponibles, un control por comentario convierte
  /// el chat en una consola y le come la pantalla al directo.
  Future<void> _moderate(BuildContext context) async {
    final cubit = context.read<LiveRoomCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final decision = await showModerationSheet(
      context,
      author: comment.author,
      comment: comment.body,
    );
    if (decision == null) return;

    if (decision.type == ModerationType.hideComment) {
      cubit.hideComment(comment);
    } else {
      cubit.recordModeration('${decision.confirmation} (${comment.author})');
    }
    // Se confirma qué pasó. Una acción de moderación que no deja rastro
    // visible se siente como que no se aplicó, y el moderador la repite.
    messenger.showSnackBar(SnackBar(content: Text(decision.confirmation)));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAvatar(name: comment.author, size: 24),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: InkWell(
            key: Key('chat-${comment.id}'),
            onLongPress: () => unawaited(_moderate(context)),
            borderRadius: AppRadii.medium,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.neutral.withValues(alpha: .5),
                borderRadius: AppRadii.medium,
              ),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  children: [
                    TextSpan(
                      text: '${comment.author} ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: comment.isMine
                            ? AppColors.primarySurface
                            : Colors.white70,
                      ),
                    ),
                    TextSpan(text: comment.body),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    ),
  );
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.loved,
    required this.onSend,
    required this.onLove,
  });

  final TextEditingController controller;
  final bool loved;
  final VoidCallback onSend;
  final VoidCallback onLove;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      AppSpacing.sm,
      AppSpacing.xs,
      AppSpacing.sm,
      // Sube el campo por encima del teclado. El Scaffold no redimensiona, así
      // que el inset se aplica acá y sólo acá.
      MediaQuery.viewInsetsOf(context).bottom + AppSpacing.sm,
    ),
    child: Row(
      children: [
        Expanded(
          child: Container(
            height: AppSizes.searchHeight,
            padding: const EdgeInsets.only(left: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.neutral.withValues(alpha: .55),
              borderRadius: AppRadii.pill,
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('live-comment-field'),
                    controller: controller,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    cursorColor: Colors.white,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: const InputDecoration(
                      hintText: 'Escribe un comentario',
                      hintStyle: TextStyle(color: Colors.white54),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('live-send'),
                  tooltip: 'Enviar',
                  onPressed: onSend,
                  icon: const Icon(
                    Icons.send_rounded,
                    size: 19,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        _GlassIconButton(
          icon: Icons.card_giftcard_rounded,
          tooltip: 'Enviar un regalo',
          onTap: () {},
        ),
        const SizedBox(width: 6),
        _GlassIconButton(
          key: const Key('live-love'),
          icon: loved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          tooltip: 'Dar amor',
          onTap: onLove,
          background: loved ? AppColors.secondary : null,
          child: Pop(
            trigger: loved,
            child: Icon(
              loved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Botón circular translúcido, el lenguaje de todo control sobre video.
class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.background,
    this.child,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? background;

  /// Reemplaza al ícono cuando el control necesita animarse.
  final Widget? child;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkResponse(
      onTap: onTap,
      radius: 26,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: background ?? AppColors.neutral.withValues(alpha: .55),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: child ?? Icon(icon, size: 20, color: Colors.white),
      ),
    ),
  );
}
