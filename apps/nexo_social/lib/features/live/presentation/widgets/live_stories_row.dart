import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/live_session.dart';
import '../utils/live_status_ui.dart';

/// La fila de historias que abre el feed.
///
/// El anillo rojo con la etiqueta VIVO es el mismo lenguaje que usan la
/// tarjeta destacada y la lista de creadores: quien está al aire se reconoce
/// igual en toda la app, sin leer una palabra.
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
  static const height = 92.0;

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
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: _Story(session: session, onTap: () => onTap(session)),
          ),
      ],
    ),
  );
}

class _OwnStory extends StatelessWidget {
  const _OwnStory({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _StoryFrame(
    onTap: onTap,
    label: 'Tu historia',
    avatar: Stack(
      clipBehavior: Clip.none,
      children: [
        const UserAvatar(name: 'Elena Vega', size: 54),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColors.primaryDeep,
              shape: BoxShape.circle,
              border: Border.fromBorderSide(
                BorderSide(color: AppColors.background, width: 2),
              ),
            ),
            child: const Icon(Icons.add_rounded, size: 13, color: Colors.white),
          ),
        ),
      ],
    ),
  );
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
      badge: onAir ? 'VIVO' : null,
      avatar: UserAvatar(
        name: session.hostName,
        size: 54,
        // Sin anillo cuando no está al aire: un anillo en todas las historias
        // deja de significar nada.
        ring: onAir ? AppColors.secondary : null,
      ),
    );
  }
}

class _StoryFrame extends StatelessWidget {
  const _StoryFrame({
    required this.avatar,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final Widget avatar;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: AppRadii.medium,
    child: SizedBox(
      width: 68,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              avatar,
              if (badge != null)
                Positioned(
                  bottom: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: AppRadii.pill,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .4,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}
