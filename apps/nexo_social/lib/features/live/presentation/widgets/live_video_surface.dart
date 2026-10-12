import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/nexo_mascot.dart';
import '../bloc/live_media_cubit.dart';

/// El video del vivo, o [fallback] cuando no hay video que mostrar.
///
/// El fallback no es un error: es el escenario simulado sin App ID de
/// Agora, la sala antes de que el host empiece a publicar, o la pantalla
/// después de un fallo. La sala sigue funcionando —chat, espectadores,
/// moderación— con o sin imagen.
class LiveVideoSurface extends StatelessWidget {
  const LiveVideoSurface({
    super.key,
    required this.role,
    required this.fallback,
  });

  final LiveMediaRole role;
  final Widget fallback;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LiveMediaCubit, LiveMediaState>(
        builder: (context, state) {
          final cubit = context.read<LiveMediaCubit>();
          if (cubit.engine.isSimulated) return fallback;

          final channel = cubit.channel;
          final Widget? video = switch (role) {
            LiveMediaRole.host when state.phase == LiveMediaPhase.connected =>
              cubit.engine.localView(),
            LiveMediaRole.audience
                when channel != null && state.remoteUids.isNotEmpty =>
              cubit.engine.remoteView(channel, state.remoteUids.first),
            _ => null,
          };

          return Stack(
            fit: StackFit.expand,
            children: [
              video ?? fallback,
              if (video == null) _StatusCaption(state: state, role: role),
            ],
          );
        },
      );
}

class _StatusCaption extends StatelessWidget {
  const _StatusCaption({required this.state, required this.role});

  final LiveMediaState state;
  final LiveMediaRole role;

  String? get _text => switch ((state.phase, state.issue)) {
    (
      LiveMediaPhase.failed,
      LiveMediaIssue.permissionDenied || LiveMediaIssue.permissionBlocked,
    ) =>
      'Sin permiso de cámara o micrófono. Actívalo en los ajustes.',
    (LiveMediaPhase.failed, _) =>
      'No pudimos conectar el video. El chat sigue funcionando.',
    (LiveMediaPhase.joining, _) => 'Conectando el video…',
    (LiveMediaPhase.connected, _) when role == LiveMediaRole.audience =>
      'Esperando la señal del host…',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final text = _text;
    if (text == null) return const SizedBox.shrink();
    return Align(
      alignment: const Alignment(0, .35),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(
          text,
          key: const Key('live-video-status'),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

/// El escenario sin imagen: el escenario oscuro con el gato de la marca
/// chico en el centro.
///
/// Plano, sin degradé: no es una transmisión ni pretende parecerlo. Con el
/// motor simulado lo dice con [caption]; con Agora es la sala antes de que
/// llegue la señal, y la leyenda la pone [LiveVideoSurface].
class LiveStagePlaceholder extends StatelessWidget {
  const LiveStagePlaceholder({
    super.key,
    this.mascot = NexoMascot.camera,
    this.size = 96,
    this.caption,
    this.alignment = Alignment.center,
  });

  final NexoMascot mascot;
  final double size;
  final String? caption;

  /// Dónde va el gato. El Studio lo sube: la mitad de abajo del escenario es
  /// del chat.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.stageDark,
    child: Align(
      alignment: alignment,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MascotIllustration(mascot, size: size),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              caption!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    ),
  );
}
