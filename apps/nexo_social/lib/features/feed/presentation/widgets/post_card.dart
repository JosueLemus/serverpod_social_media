import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/nexo_themes.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/sticker.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/post.dart';
import '../../../../core/share/share_sheet.dart';
import '../utils/post_share_text.dart';
import 'dart:async';
import 'photo_viewer.dart';

/// Una publicación, pegada directo sobre el liner.
///
/// Sin tarjeta: una columna de cajas con borde es el feed genérico que esta
/// app no quiere ser, y la media ya es un sticker por su cuenta. Lo que separa
/// una publicación de la siguiente es el espacio y un filete, que pone el feed.
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onSave,
    this.onComment,
    this.onMore,
    this.onShowLikers,
    this.onOpen,
  });

  final Post post;
  final VoidCallback onLike;
  final VoidCallback onSave;

  /// Null donde la tarjeta no puede abrir hojas (un test aislado, una vista
  /// previa): el botón queda deshabilitado en vez de no hacer nada.
  final VoidCallback? onComment;
  final VoidCallback? onMore;
  final VoidCallback? onShowLikers;

  /// Abre la publicación entera al tocar el texto. Null en la propia
  /// pantalla de publicación, donde ya se está.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      key: Key('post-${post.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PostHeader(post: post, onMore: onMore),
        const SizedBox(height: AppSpacing.xs),
        _OpenOnTap(
          onOpen: onOpen,
          child: Text(
            post.body,
            style: text.bodyMedium?.copyWith(height: 1.45),
          ),
        ),
        if (post.media != null) ...[
          const SizedBox(height: AppSpacing.sm),
          // La media es el sticker del post: troquel blanco, despegado del
          // liner. El borde dice "publicado", no "al aire".
          StickerFrame(
            child: _PostMedia(kind: post.media!, url: post.mediaUrl),
          ),
        ],
        if (post.tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xxs,
            children: [
              for (final tag in post.tags)
                Text(
                  '#$tag',
                  style: text.labelMedium?.copyWith(color: AppColors.primary),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xxs),
        _PostActions(
          post: post,
          onLike: onLike,
          onSave: onSave,
          onComment: onComment,
          onShowLikers: onShowLikers,
        ),
      ],
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post, this.onMore});

  final Post post;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: InkWell(
            // Empujado, no `go`: abrir un perfil desde el feed tiene que dejar
            // el feed debajo para que el gesto de volver devuelva la misma
            // posición de scroll. `go` reemplazaría la pila y la perdería.
            onTap: () => context.push(AppRoutes.profileOf(post.author)),
            borderRadius: AppRadii.medium,
            child: Row(
              children: [
                _AuthorAvatar(post: post),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wrap y no Row: a 320 el nombre, el verificado y las
                      // insignias no entran en una línea, y con la insignia de
                      // en vivo afuera de esta columna se comía el ancho del
                      // handle y recortaba la hora a "2…". Acá baja de renglón.
                      Wrap(
                        spacing: 6,
                        runSpacing: AppSpacing.xxs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            post.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleMedium,
                          ),
                          if (post.authorIsVerified)
                            NexoIcon(
                              NexoGlyph.verified,
                              size: 15,
                              color: AppColors.primary,
                            ),
                          if (post.authorIsPro)
                            StatusBadge(
                              label: 'Pro',
                              color: AppColors.vinylViolet,
                              foreground: AppColors.ink,
                            ),
                          if (post.isLive)
                            const StatusBadge(label: 'En vivo', pulse: true),
                        ],
                      ),
                      Text(
                        '@${post.author} · ${RelativeTime.format(post.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          key: Key('more-${post.id}'),
          tooltip: 'Más opciones',
          onPressed: onMore,
          icon: NexoIcon(
            NexoGlyph.more,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// El avatar del autor en un hueco fijo. Al aire suma el foil holo por fuera
/// del sticker, así que la cara se achica para que el anillo entre en el
/// mismo hueco: si no, el nombre de quien transmite queda corrido respecto
/// del resto de la columna.
class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.post});

  final Post post;

  static const _slot = 46.0;
  static const _ring = 2.0;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: _slot,
    child: Center(
      child: post.isLive
          ? UserAvatar(
              name: post.name,
              imageUrl: post.authorAvatarUrl,
              // UserAvatar separa el anillo con un aro de 1.5 más su ancho.
              size: _slot - 2 * (_ring + 1.5),
              ringWidth: _ring,
              onAir: true,
            )
          : UserAvatar(
              name: post.name,
              imageUrl: post.authorAvatarUrl,
              size: 42,
            ),
    ),
  );
}

/// La foto o el video del post. Sin [url] (los posts del mock), o mientras
/// carga, queda el dorso liso del sticker con el glifo de media: un recuadro
/// de marca con degradado se leía como una imagen de verdad.
class _PostMedia extends StatelessWidget {
  const _PostMedia({required this.kind, this.url});

  final PostMedia kind;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final source = url;
    if (source != null && kind == PostMedia.image) {
      // Tocar la foto la abre a pantalla completa, con zoom.
      return GestureDetector(
        key: const Key('post-image-open'),
        onTap: () => unawaited(showPhotoViewer(context, url: source)),
        child: AspectRatio(
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
            errorBuilder: (context, error, stack) => const _MediaPlaceholder(),
          ),
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

  /// Un video que no cargó ya no promete reproducirse: pierde el disco de
  /// play y queda el glifo de media.
  final bool broken;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 16 / 10,
    child: ColoredBox(
      color: AppColors.linerHigh,
      child: Center(
        child: kind == PostMedia.video && !broken
            ? const _PlayDisc()
            : NexoIcon(
                NexoGlyph.media,
                size: 40,
                color: AppColors.textTertiary,
              ),
      ),
    ),
  );
}

/// El play como un sticker blanco redondo, cortado como el gato del logo:
/// troquel blanco, contorno de tinta y relleno blanco con el triángulo en
/// tinta. Sobre una foto o sobre el liner se lee igual.
class _PlayDisc extends StatelessWidget {
  const _PlayDisc();

  @override
  Widget build(BuildContext context) => Container(
    width: 60,
    height: 60,
    padding: const EdgeInsets.all(AppStroke.kissCut),
    decoration: BoxDecoration(color: AppColors.cut, shape: BoxShape.circle),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.sticker,
        shape: BoxShape.circle,
        border: Border.all(
          color: NexoThemes.active.stickerCut
              ? AppColors.ink
              : AppColors.sticker,
          width: AppStroke.ink,
        ),
      ),
      child: Center(
        child: NexoIcon(
          NexoGlyph.play,
          filled: true,
          size: 24,
          color: AppColors.ink,
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
            if (!_controller.value.isPlaying) const _PlayDisc(),
          ],
        ),
      ),
    );
  }
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

  static const _iconSize = 22.0;

  /// Un visitante mira; interactuar pide una cuenta. Antes el toque llegaba
  /// al servidor, que lo rechazaba, y el aviso decía "No pudimos guardar tu
  /// me gusta", como si fuera una falla.
  void _like(BuildContext context) {
    final auth = context.read<AuthCubit>().state;
    final isMember =
        auth is AuthAuthenticated && auth.user.role != UserRole.visitor;
    if (isMember) {
      onLike();
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('like-sign-in'),
          content: const Text('Inicia sesión para dar me gusta.'),
          action: SnackBarAction(
            label: 'Iniciar sesión',
            onPressed: () => context.go(AppRoutes.signIn),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _ActionButton(
        buttonKey: Key('like-${post.id}'),
        // El corazón se "pega" sólo al activarse: el slap de Pop. Keyearlo en
        // `isLiked` lo repetiría cada vez que pasa a true y dejaría el
        // des-like silencioso, que es la asimetría real del gesto.
        icon: Pop(
          trigger: post.isLiked,
          child: NexoIcon(
            NexoGlyph.heart,
            filled: post.isLiked,
            size: _iconSize,
            color: post.isLiked ? AppColors.secondary : AppColors.textSecondary,
          ),
        ),
        label: '${post.displayLikes}',
        tooltip: post.isLiked ? 'Quitar me gusta' : 'Me gusta',
        onTap: () => _like(context),
        // Mantener apretado muestra quién dio like: el toque ya es el like.
        onLongPress: onShowLikers,
        emphasised: post.isLiked,
        edge: _Edge.start,
      ),
      _ActionButton(
        buttonKey: Key('comment-${post.id}'),
        icon: NexoIcon(
          NexoGlyph.comment,
          size: _iconSize,
          color: onComment == null
              ? AppColors.textTertiary
              : AppColors.textSecondary,
        ),
        label: '${post.comments}',
        tooltip: 'Comentar',
        onTap: onComment,
      ),
      // La hoja de compartir del sistema: WhatsApp, Instagram, copiar.
      Builder(
        builder: (buttonContext) => _ActionButton(
          buttonKey: Key('share-${post.id}'),
          icon: NexoIcon(
            NexoGlyph.share,
            size: _iconSize,
            color: AppColors.textSecondary,
          ),
          tooltip: 'Compartir',
          onTap: () => unawaited(
            openShareSheet(buttonContext, text: postShareText(post)),
          ),
        ),
      ),
      const Spacer(),
      // Guardado = despegado: relleno y blanco, como todo lo seleccionado.
      _ActionButton(
        buttonKey: Key('save-${post.id}'),
        icon: NexoIcon(
          NexoGlyph.bookmark,
          filled: post.isSaved,
          size: _iconSize,
          color: post.isSaved ? AppColors.textPrimary : AppColors.textSecondary,
        ),
        tooltip: post.isSaved ? 'Quitar de guardados' : 'Guardar',
        onTap: onSave,
        edge: _Edge.end,
      ),
    ],
  );
}

/// De qué lado de la fila está el botón. Los de las puntas pegan el ícono al
/// borde del texto, para que la fila de acciones quede alineada con el cuerpo
/// del post y no metida hacia adentro; el área táctil sigue siendo de 44.
enum _Edge { start, none, end }

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.buttonKey,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.onLongPress,
    this.label,
    this.emphasised = false,
    this.edge = _Edge.none,
  });

  final Key buttonKey;
  final Widget icon;
  final String? label;
  final String tooltip;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final _Edge edge;

  /// Tiñe también el número, no sólo el ícono: con el corazón rojo y el
  /// contador gris, el conteo se lee como si perteneciera a otra acción.
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final padding = switch (edge) {
      _Edge.start => const EdgeInsetsDirectional.only(end: AppSpacing.sm),
      _Edge.end => const EdgeInsetsDirectional.only(start: AppSpacing.sm),
      _Edge.none => const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
      ),
    };
    return Tooltip(
      message: tooltip,
      child: InkWell(
        key: buttonKey,
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: AppRadii.pill,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: edge == _Edge.end
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                icon,
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: emphasised
                          ? AppColors.secondary
                          : AppColors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El texto de una publicación abre la publicación entera, como en cualquier
/// red social. Sin [onOpen] (la propia pantalla de publicación) es sólo texto.
class _OpenOnTap extends StatelessWidget {
  const _OpenOnTap({required this.onOpen, required this.child});

  final VoidCallback? onOpen;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final open = onOpen;
    if (open == null) return child;
    return InkWell(
      key: const Key('post-open'),
      onTap: open,
      borderRadius: AppRadii.small,
      child: child,
    );
  }
}
