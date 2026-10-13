import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/live_session.dart';
import '../utils/live_status_ui.dart';

/// La fila de historias que abre el feed: una tira de avatares troquelados.
///
/// Quien está al aire lleva el anillo holográfico y la insignia VIVO pegada
/// abajo, el mismo lenguaje que la tarjeta destacada y la lista de creadores:
/// se reconoce igual en toda la app, sin leer una palabra.
class LiveStoriesRow extends StatelessWidget {
  const LiveStoriesRow({
    super.key,
    required this.sessions,
    required this.onTap,
    required this.onCreate,
  });

  final List<LiveSession> sessions;
  final ValueChanged<LiveSession> onTap;
  final VoidCallback onCreate;

  /// Alto fijo porque la fila es un scroller horizontal dentro de una lista
  /// vertical: sin alto acotado no tiene restricciones y revienta en layout.
  static const height = 100.0;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      children: [
        _OwnStory(onTap: onCreate),
        for (final session in sessions)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: _Story(session: session, onTap: () => onTap(session)),
          ),
      ],
    ),
  );
}

/// El lado del avatar sin anillo. El del vivo suma el anillo holográfico
/// alrededor, así que todas las caras miden lo mismo y sólo el vivo crece.
const _face = 54.0;

/// La caja donde va cualquier avatar, con o sin anillo: así los nombres
/// quedan alineados en una sola línea.
const _slot = 64.0;

class _OwnStory extends StatelessWidget {
  const _OwnStory({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // La cuenta de la sesión, no Elena escrita a mano: "Tu historia" con la
    // cara de otra persona es el dato falso más visible del feed.
    final auth = context.watch<AuthCubit>().state;
    final user = auth is AuthAuthenticated ? auth.user : null;
    return _StoryFrame(
      onTap: onTap,
      label: 'Tu historia',
      avatar: UserAvatar(
        name: user?.name ?? 'Tú',
        imageUrl: user?.avatarUrl,
        size: _face,
      ),
      // Un "+" como sticker blanco pegado al borde: crear es la acción
      // principal, y en toda la app la acción principal es blanca.
      corner: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.sticker,
          shape: BoxShape.circle,
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.background, width: 2.5),
          ),
        ),
        child: NexoIcon(NexoGlyph.add, size: 13, color: AppColors.ink),
      ),
    );
  }
}

class _Story extends StatelessWidget {
  const _Story({required this.session, required this.onTap});

  final LiveSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onAir = session.status.isOnAir;
    return _StoryFrame(
      onTap: onTap,
      label: session.hostName,
      emphasized: onAir,
      // Sin anillo cuando no está al aire: un anillo en todas las historias
      // deja de significar nada.
      avatar: UserAvatar(
        name: session.hostName,
        imageUrl: session.hostAvatarUrl,
        size: _face,
        onAir: onAir,
      ),
      badge: onAir ? const StatusBadge(label: 'Vivo', tilt: -.06) : null,
    );
  }
}

class _StoryFrame extends StatelessWidget {
  const _StoryFrame({
    required this.avatar,
    required this.label,
    required this.onTap,
    this.badge,
    this.corner,
    this.emphasized = false,
  });

  final Widget avatar;
  final String label;
  final VoidCallback onTap;

  /// Pegada sobre el borde inferior del avatar, a caballo con el nombre.
  final Widget? badge;

  /// Pegado en la esquina inferior derecha del avatar.
  final Widget? corner;

  /// El nombre de quien está al aire va en el texto claro; el resto, gris.
  final bool emphasized;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: AppRadii.medium,
    child: SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.xxs),
          SizedBox.square(
            dimension: _slot,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                avatar,
                if (corner case final corner?)
                  Positioned(right: 2, bottom: 2, child: corner),
                if (badge case final badge?)
                  Positioned(bottom: -7, child: badge),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: emphasized
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
