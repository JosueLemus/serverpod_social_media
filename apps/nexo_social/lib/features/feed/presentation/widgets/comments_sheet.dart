import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/nexo_mascot.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../admin/presentation/widgets/reason_sheet.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_extras.dart';
import '../bloc/comments_cubit.dart';

/// Los comentarios de [post], en una hoja que sube desde abajo.
///
/// La hoja es dueña de su cubit: cerrarla lo libera. El feed se entera de los
/// cambios por el repositorio (el contador se actualiza solo).
///
/// Es una hoja del liner (`surface`, la del tema): los comentarios van
/// directo sobre ella, sin tarjeta por mensaje.
Future<void> showCommentsSheet(BuildContext context, Post post) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider(
        create: (_) => sl<CommentsCubit>(param1: post.id)..load(),
        child: _CommentsSheet(post: post),
      ),
    );

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.post});

  final Post post;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final sent = await context.read<CommentsCubit>().send(_controller.text);
    if (sent) _controller.clear();
  }

  @override
  Widget build(BuildContext context) => Padding(
    // El teclado no tapa el campo de comentar.
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .7,
      // Messenger y Scaffold propios: el de la página queda debajo de la
      // barrera del modal, así que un aviso mostrado ahí se dibujaba detrás
      // de la hoja y nadie lo veía. Transparente, para que la hoja conserve
      // su superficie y su forma.
      child: ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          body: Builder(
            // El context de adentro del Scaffold es el que encuentra este
            // messenger y no el de la página.
            builder: (context) => BlocListener<CommentsCubit, CommentsState>(
              listenWhen: (previous, current) =>
                  current.notice != null &&
                  previous.noticeSerial != current.noticeSerial,
              listener: (context, state) {
                final message = state.notice!.message;
                if (message == null) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              },
              child: _content(context),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _content(BuildContext context) {
    // Del árbol, nunca con `BlocProvider(create:)`: la sesión es singleton y
    // un provider propio la cerraría al cerrar la hoja. Nullable porque una
    // hoja montada sin sesión arriba (un test) no tiene a quién preguntar.
    final auth = context.watch<AuthCubit?>()?.state;
    final isVisitor =
        auth != null &&
        (auth is! AuthAuthenticated || auth.user.role == UserRole.visitor);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Text(
                'Comentarios',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Expanded(child: _CommentList()),
        const Divider(height: 1),
        if (!widget.post.allowComments)
          const _CommentsClosed()
        // Un visitante podía escribir y recibía "no acepta comentarios":
        // el campo prometía algo que el servidor iba a rechazar. Se le
        // ofrece lo que sí puede hacer.
        else if (isVisitor)
          _SignInToComment(postId: widget.post.id)
        else
          _CommentComposer(controller: _controller, onSend: _send),
      ],
    );
  }
}

/// La invitación a iniciar sesión donde iría el campo de comentar.
class _SignInToComment extends StatelessWidget {
  const _SignInToComment({required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      // En columna: a 320 el botón y la frase no entran en una fila.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Con una cuenta puedes sumarte a la conversación.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            key: const Key('comments-sign-in'),
            onPressed: () {
              // El router se lee antes de cerrar la hoja: después, este
              // context ya no está montado. Al volver con sesión se aterriza
              // en la publicación, no en el feed.
              final router = GoRouter.of(context);
              Navigator.of(context).pop();
              router.go(AppRoutes.signInFrom(AppRoutes.post(postId)));
            },
            child: const Text('Inicia sesión para comentar'),
          ),
        ],
      ),
    ),
  );
}

class _CommentsClosed extends StatelessWidget {
  const _CommentsClosed();

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          NexoIcon(NexoGlyph.lock, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'Los comentarios están desactivados en esta publicación.',
              key: const Key('comments-closed'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CommentList extends StatelessWidget {
  const _CommentList();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CommentsCubit, CommentsState>(
        builder: (context, state) {
          final cubit = context.read<CommentsCubit>();
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.failed) {
            return _SheetMessage(
              mascot: NexoMascot.error,
              child: TextButton(
                onPressed: cubit.load,
                child: const Text(
                  'No pudimos cargar los comentarios. Reintentar',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (state.comments.isEmpty) {
            return _SheetMessage(
              mascot: NexoMascot.peek,
              child: Text(
                'Sé la primera persona en comentar.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount:
                state.comments.length + (state.nextCursor == null ? 0 : 1),
            itemBuilder: (context, index) {
              if (index == state.comments.length) {
                return TextButton(
                  onPressed: () => unawaited(cubit.loadMore()),
                  child: const Text('Ver más comentarios'),
                );
              }
              return _CommentTile(comment: state.comments[index]);
            },
          );
        },
      );
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final PostComment comment;

  Future<void> _actions(BuildContext context) async {
    final cubit = context.read<CommentsCubit>();
    if (comment.canDelete) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Eliminar comentario'),
          content: const Text('Deja de verse para todos.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              key: const Key('confirm-delete-comment'),
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (confirmed ?? false) await cubit.delete(comment);
      return;
    }
    final reason = await showReasonSheet(
      context,
      title: 'Reportar comentario',
      detail:
          'Lo revisa el equipo de moderación. Quien lo escribió no se entera de quién lo reportó.',
      confirmLabel: 'Reportar',
      destructive: false,
    );
    if (reason != null) await cubit.report(comment, reason);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      key: Key('comment-${comment.id}'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: UserAvatar(
              name: comment.name,
              imageUrl: comment.authorAvatarUrl,
              size: 34,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xxs),
                // El nombre pesa, el handle y la hora acompañan. Dos
                // Flexible para que a 320 se recorte cada uno con su elipsis
                // en vez de empujar al otro fuera de la fila.
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '@${comment.author} · '
                        '${RelativeTime.format(comment.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.body, style: text.bodyMedium),
              ],
            ),
          ),
          IconButton(
            key: Key('comment-actions-${comment.id}'),
            tooltip: comment.canDelete ? 'Eliminar' : 'Reportar',
            onPressed: () => unawaited(_actions(context)),
            icon: NexoIcon(
              comment.canDelete ? NexoGlyph.trash : NexoGlyph.flag,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Un vacío o un fallo dentro de la hoja: el gato chico y lo que pasa. La
/// hoja es más baja que una pantalla, así que el gato va a 112 y no a 148.
class _SheetMessage extends StatelessWidget {
  const _SheetMessage({required this.mascot, required this.child});

  final NexoMascot mascot;
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MascotIllustration(mascot, size: 112),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    ),
  );
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final sending = context.select<CommentsCubit, bool>(
      (cubit) => cubit.state.isSending,
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('comment-input'),
                controller: controller,
                maxLength: CommentsCubit.maxLength,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Escribe un comentario…',
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Enviar es la acción de la hoja: sticker blanco con tinta.
            IconButton.filled(
              key: const Key('comment-send'),
              tooltip: 'Enviar',
              onPressed: sending ? null : onSend,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.sticker,
                foregroundColor: AppColors.ink,
                disabledBackgroundColor: AppColors.linerHigh,
                disabledForegroundColor: AppColors.textTertiary,
              ),
              icon: sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const NexoIcon(NexoGlyph.send, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

extension on CommentsNotice {
  /// Null cuando no hace falta avisar: el comentario enviado ya se ve en la
  /// lista.
  String? get message => switch (this) {
    CommentsNotice.sent => null,
    CommentsNotice.deleted => 'Comentario eliminado.',
    CommentsNotice.reported => 'Gracias. El reporte llegó a moderación.',
    CommentsNotice.failed =>
      'No pudimos completar la acción. Inténtalo de nuevo.',
    CommentsNotice.forbidden => 'Tu cuenta no puede hacer esto.',
    CommentsNotice.cannotComment =>
      'No puedes comentar en esta publicación ahora.',
  };
}
