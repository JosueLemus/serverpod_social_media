import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../profile/domain/entities/follow.dart';

/// "A quién seguir", en horizontal dentro del feed: una tira de stickers de
/// avatar sobre el liner, cada uno con su botón. Tocar el avatar abre el
/// perfil; el botón sigue sin salir del feed.
///
/// Sin tarjetas: el feed ya no las usa, y una tarjeta por cuenta dentro de
/// una sección es una caja dentro de otra.
///
/// Scrollea en horizontal con alto fijo: dentro de `NexoPage` (una lista de
/// slivers) una lista vertical no tiene altura acotada, una horizontal sí.
class SuggestedAccountsRow extends StatelessWidget {
  const SuggestedAccountsRow({
    super.key,
    required this.accounts,
    required this.onToggleFollow,
  });

  final List<ProfileSummary> accounts;
  final ValueChanged<ProfileSummary> onToggleFollow;

  static const cardWidth = 124.0;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 184,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: accounts.length,
      separatorBuilder: (context, index) =>
          const SizedBox(width: AppSpacing.sm),
      itemBuilder: (context, index) => _AccountSticker(
        account: accounts[index],
        onToggleFollow: () => onToggleFollow(accounts[index]),
      ),
    ),
  );
}

class _AccountSticker extends StatelessWidget {
  const _AccountSticker({required this.account, required this.onToggleFollow});

  final ProfileSummary account;
  final VoidCallback onToggleFollow;

  /// Alto visible del botón. El área táctil la completa Material hasta 48.
  static const _buttonHeight = 38.0;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final followers = account.followerCount;
    return SizedBox(
      width: SuggestedAccountsRow.cardWidth,
      child: Column(
        children: [
          InkWell(
            key: Key('suggested-${account.username}'),
            onTap: () =>
                unawaited(context.push(AppRoutes.profileOf(account.username))),
            borderRadius: AppRadii.medium,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: Column(
                children: [
                  UserAvatar(
                    name: account.name,
                    imageUrl: account.avatarUrl,
                    size: 68,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          account.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall,
                        ),
                      ),
                      if (account.isVerified) ...[
                        const SizedBox(width: 3),
                        NexoIcon(
                          NexoGlyph.verified,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    followers == null
                        ? '@${account.username}'
                        : '${compactCount(followers)} seguidores',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Seguir es la acción: sticker blanco. Ya seguida, el sticker se
          // despega y queda sólo el contorno.
          SizedBox(
            width: double.infinity,
            child: account.viewerFollows
                ? OutlinedButton(
                    key: Key('suggested-follow-${account.username}'),
                    onPressed: onToggleFollow,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, _buttonHeight),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      textStyle: text.labelMedium,
                    ),
                    child: const Text('Siguiendo'),
                  )
                : FilledButton(
                    key: Key('suggested-follow-${account.username}'),
                    onPressed: onToggleFollow,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, _buttonHeight),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      textStyle: text.labelMedium,
                    ),
                    child: const Text('Seguir'),
                  ),
          ),
        ],
      ),
    );
  }
}
