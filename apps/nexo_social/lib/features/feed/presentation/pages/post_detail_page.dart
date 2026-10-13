import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/nexo_mascot.dart';
import '../bloc/post_detail_cubit.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/post_actions.dart';
import '../widgets/post_card.dart';

/// Una publicación entera: la que se abre desde el feed, la grilla de un
/// perfil, una notificación o un enlace compartido (`/p/<id>`).
///
/// Ruta raíz empujada sobre el shell, así que lleva su propio Scaffold.
class PostDetailPage extends StatelessWidget {
  const PostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<PostDetailCubit>(param1: postId)..load(),
    child: const _PostDetailView(),
  );
}

class _PostDetailView extends StatelessWidget {
  const _PostDetailView();

  /// Desde un enlace no hay a dónde volver: atrás lleva al inicio en vez de
  /// no hacer nada.
  void _back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(AppRoutes.feed);

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<PostDetailCubit, PostDetailState>(
        listenWhen: (previous, current) =>
            previous.noticeSerial != current.noticeSerial ||
            (current.status == PostDetailStatus.deleted &&
                previous.status != PostDetailStatus.deleted),
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state.status == PostDetailStatus.deleted) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Publicación eliminada.')),
            );
            _back(context);
            return;
          }
          final notice = state.notice;
          if (notice != null) {
            messenger.showSnackBar(SnackBar(content: Text(notice.message)));
          }
        },
        builder: (context, state) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              key: const Key('post-detail-back'),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => _back(context),
              icon: const NexoIcon(NexoGlyph.back),
            ),
            title: const Text('Publicación'),
          ),
          body: switch (state.status) {
            PostDetailStatus.loading || PostDetailStatus.deleted =>
              const _Frame(child: FeedSkeleton(count: 1)),
            PostDetailStatus.notFound => AppEmptyView(
              key: const Key('post-detail-not-found'),
              mascot: NexoMascot.peek,
              title: 'Esta publicación ya no está',
              message:
                  'Puede que la hayan borrado o que no sea pública para tu '
                  'cuenta.',
              actionLabel: 'Ir al inicio',
              onAction: () => context.go(AppRoutes.feed),
            ),
            PostDetailStatus.failure => AppErrorView(
              onRetry: () => unawaited(context.read<PostDetailCubit>().load()),
            ),
            PostDetailStatus.ready => _Content(state: state),
          },
        ),
      );
}

class _Content extends StatelessWidget {
  const _Content({required this.state});

  final PostDetailState state;

  Future<void> _openComments(BuildContext context) async {
    final cubit = context.read<PostDetailCubit>();
    final post = state.post;
    if (post == null) return;
    await showCommentsSheet(context, post);
    // Comentar o borrar desde la hoja cambia el contador de acá abajo.
    await cubit.refresh();
  }

  Future<void> _runAction(BuildContext context) async {
    final cubit = context.read<PostDetailCubit>();
    final post = state.post;
    if (post == null) return;
    final action = await showPostActions(context, post);
    switch (action) {
      case EditPost(:final body):
        await cubit.edit(body);
      case DeletePost():
        await cubit.delete();
      case ReportPost(:final reason):
        await cubit.report(reason);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PostDetailCubit>();
    final post = state.post!;
    final text = Theme.of(context).textTheme;
    final comments = post.comments;
    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          _Frame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PostCard(
                  post: post,
                  onLike: () => unawaited(cubit.toggleLike()),
                  onSave: cubit.toggleSave,
                  onComment: post.allowComments
                      ? () => unawaited(_openComments(context))
                      : null,
                  onShowLikers: () =>
                      unawaited(showLikersSheet(context, cubit.likers())),
                  onMore: () => unawaited(_runAction(context)),
                ),
                const SizedBox(height: AppSpacing.md),
                if (post.allowComments)
                  OutlinedButton.icon(
                    key: const Key('post-detail-comments'),
                    onPressed: () => unawaited(_openComments(context)),
                    icon: const NexoIcon(NexoGlyph.comment, size: 18),
                    label: Text(
                      comments == 0
                          ? 'Sé la primera persona en comentar'
                          : comments == 1
                          ? 'Ver el comentario'
                          : 'Ver los $comments comentarios',
                    ),
                  )
                else
                  Text(
                    'Los comentarios están cerrados en esta publicación.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// El ancho de lectura de la app: pasados los 640 una publicación deja de
/// leerse, así que en escritorio se centra en vez de estirarse.
class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: child,
    ),
  );
}

extension on PostDetailNotice {
  String get message => switch (this) {
    PostDetailNotice.edited => 'Publicación actualizada.',
    PostDetailNotice.reported => 'Gracias. El reporte llegó a moderación.',
    PostDetailNotice.likeFailed =>
      'No pudimos guardar tu me gusta. Inténtalo de nuevo.',
    PostDetailNotice.actionFailed =>
      'No pudimos completar la acción. Inténtalo de nuevo.',
    PostDetailNotice.forbidden => 'Tu cuenta no puede hacer esto.',
  };
}
