import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

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
    this.onComment,
    this.onMore,
    this.onShowLikers,
  });

  final Post post;
  final VoidCallback onLike;
  final VoidCallback onSave;

  /// Null donde la tarjeta no puede abrir hojas (un test aislado, una vista
  /// previa): el botón queda deshabilitado en vez de no hacer nada.
  final VoidCallback? onComment;
  final VoidCallback? onMore;
  final VoidCallback? onShowLikers;

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
          child: _PostHeader(post: post, onMore: onMore),
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
          _PostMedia(kind: post.media!, url: post.mediaUrl),
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
          child: _PostActions(
            post: post,
            onLike: onLike,
            onSave: onSave,
            onComment: onComment,
            onShowLikers: onShowLikers,
          ),
        ),
      ],
    ),
  );
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post, this.onMore});

  final Post post;
  final VoidCallback? onMore;

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
        key: Key('more-${post.id}'),
        tooltip: 'Más opciones',
        iconSize: 20,
        onPressed: onMore,
        icon: const Icon(Icons.more_horiz_rounded),
      ),
    ],
  );
}

/// La foto o el video del post. Sin [url] (los posts del mock) dibuja una
/// superficie de marca: un recuadro gris se lee como una imagen rota, una
/// superficie de marca se lee como un placeholder.
class _PostMedia extends StatelessWidget {
  const _PostMedia({required this.kind, this.url});

  final PostMedia kind;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final source = url;
    if (source != null && kind == PostMedia.image) {
      return AspectRatio(
        aspectRatio: 4 / 5,
        child: Image.network(
          source,
          key: const Key('post-image'),
          fit: BoxFit.cover,
          // Se decodifica al ancho en que se muestra: Flutter guarda el
          // bitmap a resolución nativa si no se le dice otra cosa.
          cacheWidth: 1080,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : const _MediaPlaceholder(),
          errorBuilder: (context, error, stack) =>
              const _MediaPlaceholder(broken: true),
        ),
      );
    }
    if (source != null && kind == PostMedia.video) {
      return _InlineVideo(url: source);
    }
    return _MediaPlaceholder(kind: kind);
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({this.kind = PostMedia.image, this.broken = false});

  final PostMedia kind;
  final bool broken;

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
          broken
              ? Icons.broken_image_outlined
              : kind == PostMedia.video
              ? Icons.play_circle_fill_rounded
              : Icons.image_outlined,
          size: kind == PostMedia.video ? 54 : 38,
          color: AppColors.primary.withValues(alpha: .65),
        ),
      ),
    ),
  );
}

/// Un video del feed: se reproduce al tocarlo y se pausa al volver a tocar.
/// No arranca solo: diez videos sonando a la vez en un feed no se miran, se
/// cierran.
class _InlineVideo extends StatefulWidget {
  const _InlineVideo({required this.url});

  final String url;

  @override
  State<_InlineVideo> createState() => _InlineVideoState();
}

class _InlineVideoState extends State<_InlineVideo> {
  late final VideoPlayerController _controller =
      VideoPlayerController.networkUrl(Uri.parse(widget.url));
  var _ready = false;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _controller.initialize().then(
      (_) {
        if (mounted) setState(() => _ready = true);
      },
      onError: (Object _) {
        if (mounted) setState(() => _failed = true);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!_ready) return;
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const _MediaPlaceholder(broken: true);
    if (!_ready) return const _MediaPlaceholder(kind: PostMedia.video);
    return GestureDetector(
      key: const Key('post-video'),
      onTap: _toggle,
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            if (!_controller.value.isPlaying)
              const Icon(
                Icons.play_circle_fill_rounded,
                size: 56,
                color: Colors.white,
              ),
          ],
        ),
      ),
    );
  }
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
    this.onComment,
    this.onShowLikers,
  });

  final Post post;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback? onComment;
  final VoidCallback? onShowLikers;

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
        // Mantener apretado muestra quién dio like: el toque ya es el like.
        onLongPress: onShowLikers,
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
        onTap: onComment,
      ),
      _ActionButton(
        buttonKey: Key('share-${post.id}'),
        icon: const Icon(
          Icons.send_outlined,
          size: 19,
          color: AppColors.textSecondary,
        ),
        tooltip: 'Compartir (próximamente)',
        // Deshabilitado y no un tap que no hace nada: un botón que no
        // responde se lee como un bug.
        onTap: null,
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
    this.onLongPress,
    this.label,
    this.emphasised = false,
  });

  final Key buttonKey;
  final Widget icon;
  final String? label;
  final String tooltip;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Tiñe también el número, no sólo el ícono: con el corazón rojo y el
  /// contador gris, el conteo se lee como si perteneciera a otra acción.
  final bool emphasised;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      key: buttonKey,
      onTap: onTap,
      onLongPress: onLongPress,
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
