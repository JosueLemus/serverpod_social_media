import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/post.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onSave,
  });

  final Post post;
  final VoidCallback onLike;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Card(
    key: Key('post-${post.id}'),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xs,
            0,
          ),
          child: _PostHeader(post: post),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: Text(
            post.body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ),
        if (post.media != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _PostMedia(kind: post.media!),
        ],
        if (post.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final tag in post.tags) _TagChip(tag: tag)],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: _PostActions(post: post, onLike: onLike, onSave: onSave),
        ),
      ],
    ),
  );
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      UserAvatar(
        name: post.name,
        size: 42,
        ring: post.isLive ? AppColors.secondary : null,
        ringWidth: 2,
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: InkWell(
          // Empujado, no `go`: abrir un perfil desde el feed tiene que dejar
          // el feed debajo para que el gesto de volver devuelva la misma
          // posición de scroll. `go` reemplazaría la pila y la perdería.
          onTap: () => context.push(AppRoutes.profileOf(post.author)),
          borderRadius: AppRadii.small,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      post.name,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (post.authorIsVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                  ],
                  if (post.authorIsPro) ...[
                    const SizedBox(width: 6),
                    const StatusBadge(
                      label: 'Pro',
                      color: AppColors.primarySurface,
                      foreground: AppColors.textOnBrandSurface,
                    ),
                  ],
                ],
              ),
              Text(
                '@${post.author} · ${RelativeTime.format(post.createdAt)}',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      if (post.isLive) const StatusBadge(label: 'En vivo', pulse: true),
      IconButton(
        tooltip: 'Más opciones',
        iconSize: 20,
        onPressed: () {},
        icon: const Icon(Icons.more_horiz_rounded),
      ),
    ],
  );
}

/// Sustituto de media real. El build de hackathon no sube archivos, y un
/// recuadro gris se lee como una imagen rota — una superficie de marca se lee
/// como un placeholder.
class _PostMedia extends StatelessWidget {
  const _PostMedia({required this.kind});

  final PostMedia kind;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 16 / 10,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primarySurface, AppColors.primarySurfaceDeep],
        ),
      ),
      child: Center(
        child: Icon(
          kind == PostMedia.video
              ? Icons.play_circle_fill_rounded
              : Icons.image_outlined,
          size: kind == PostMedia.video ? 54 : 38,
          color: AppColors.primary.withValues(alpha: .65),
        ),
      ),
    ),
  );
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 4),
    decoration: const BoxDecoration(
      color: AppColors.primarySurface,
      borderRadius: AppRadii.pill,
    ),
    child: Text(
      '#$tag',
      style: const TextStyle(
        color: AppColors.textOnBrandSurface,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    ),
  );
}

class _PostActions extends StatelessWidget {
  const _PostActions({
    required this.post,
    required this.onLike,
    required this.onSave,
  });

  final Post post;
  final VoidCallback onLike;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _ActionButton(
        buttonKey: Key('like-${post.id}'),
        // El corazón late sólo al activarse. Keyear Pop en `isLiked` lo
        // repite cada vez que pasa a true y deja el des-like silencioso, que
        // es la asimetría real del gesto.
        icon: Pop(
          trigger: post.isLiked,
          child: Icon(
            post.isLiked ? Icons.favorite_rounded : Icons.favorite_border,
            size: 21,
            color: post.isLiked ? AppColors.secondary : AppColors.textSecondary,
          ),
        ),
        label: '${post.displayLikes}',
        tooltip: post.isLiked ? 'Quitar me gusta' : 'Me gusta',
        onTap: onLike,
        emphasised: post.isLiked,
      ),
      _ActionButton(
        buttonKey: Key('comment-${post.id}'),
        icon: const Icon(
          Icons.chat_bubble_outline_rounded,
          size: 20,
          color: AppColors.textSecondary,
        ),
        label: '${post.comments}',
        tooltip: 'Comentar',
        onTap: () {},
      ),
      _ActionButton(
        buttonKey: Key('share-${post.id}'),
        icon: const Icon(
          Icons.send_outlined,
          size: 19,
          color: AppColors.textSecondary,
        ),
        tooltip: 'Compartir',
        onTap: () {},
      ),
      const Spacer(),
      IconButton(
        key: Key('save-${post.id}'),
        tooltip: post.isSaved ? 'Quitar de guardados' : 'Guardar',
        onPressed: onSave,
        icon: Icon(
          post.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          size: 21,
          color: post.isSaved ? AppColors.primaryDeep : AppColors.textSecondary,
        ),
      ),
    ],
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.buttonKey,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.label,
    this.emphasised = false,
  });

  final Key buttonKey;
  final Widget icon;
  final String? label;
  final String tooltip;
  final VoidCallback onTap;

  /// Tiñe también el número, no sólo el ícono: con el corazón rojo y el
  /// contador gris, el conteo se lee como si perteneciera a otra acción.
  final bool emphasised;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      key: buttonKey,
      onTap: onTap,
      borderRadius: AppRadii.pill,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: emphasised
                      ? AppColors.secondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
