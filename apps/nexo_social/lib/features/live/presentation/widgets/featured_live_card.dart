import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/live_session.dart';
import 'live_card.dart';
import '../../../../core/share/share_sheet.dart';
import '../utils/live_share_text.dart';
import 'dart:async';

/// La tarjeta destacada que abre el feed cuando alguien está transmitiendo.
///
/// Es la única tarjeta del feed con un CTA propio: entrar a un vivo es
/// urgente de un modo que ninguna otra fila lo es, y enterrarla entre posts
/// hace que se pierda justo mientras está pasando.
class FeaturedLiveCard extends StatelessWidget {
  const FeaturedLiveCard({
    super.key,
    required this.session,
    required this.hostUsername,
    required this.onJoin,
    this.isOwn = false,
  });

  final LiveSession session;
  final String hostUsername;
  final VoidCallback onJoin;

  /// El vivo es de quien mira: el CTA lo devuelve a su Studio en vez de
  /// invitarlo a unirse como audiencia de sí mismo.
  final bool isOwn;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Directo sobre el liner, sin tarjeta: el objeto es la media, un sticker
    // grande con el borde de su estado (holo al aire) y EN VIVO pegado en la
    // esquina. Una tarjeta alrededor sería un sticker dentro de otro.
    return Column(
      key: Key('featured-live-${session.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LiveThumbnail(session: session, featured: true),
        const SizedBox(height: AppSpacing.md),
        Text(
          session.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            UserAvatar(
              name: session.hostName,
              imageUrl: session.hostAvatarUrl,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                // Sin handle (el mock no lo tiene) va el nombre: inventar
                // un `@` puede nombrar a otra cuenta.
                hostUsername.isEmpty
                    ? 'por ${session.hostName}'
                    : 'por @$hostUsername',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall,
              ),
            ),
            const SizedBox(width: 4),
            NexoIcon(NexoGlyph.verified, size: 14, color: AppColors.primary),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const Key('join-featured-live'),
                onPressed: onJoin,
                icon: NexoIcon(
                  isOwn ? NexoGlyph.studio : NexoGlyph.live,
                  size: 18,
                ),
                label: Text(isOwn ? 'Volver a tu vivo' : 'Unirme al Live'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, AppSizes.buttonHeightDense),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Builder(
              builder: (buttonContext) => IconButton(
                key: Key('share-live-${session.id}'),
                tooltip: 'Compartir',
                onPressed: () => unawaited(
                  openShareSheet(buttonContext, text: liveShareText(session)),
                ),
                icon: const NexoIcon(NexoGlyph.share, size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
