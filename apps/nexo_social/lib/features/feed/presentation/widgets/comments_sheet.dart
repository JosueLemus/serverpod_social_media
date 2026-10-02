import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../admin/presentation/widgets/reason_sheet.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_extras.dart';
import '../bloc/comments_cubit.dart';

/// Los comentarios de [post], en una hoja que sube desde abajo.
///
/// La hoja es dueña de su cubit: cerrarla lo libera. El feed se entera de los
/// cambios por el repositorio (el contador se actualiza solo).
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
  Widget build(
    BuildContext context,
  ) => BlocListener<CommentsCubit, CommentsState>(
    listenWhen: (previous, current) =>
        current.notice != null && previous.noticeSerial != current.noticeSerial,
    listener: (context, state) {
      final message = state.notice!.message;
      if (message == null) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    },
    child: Padding(
      // El teclado no tapa el campo de comentar.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: Column(
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
            if (widget.post.allowComments)
              _CommentComposer(controller: _controller, onSend: _send)
            else
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Los comentarios están desactivados en esta publicación.',
                  key: Key('comments-closed'),
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _CommentList extends StatelessWidget {
  const _CommentList();

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<CommentsCubit, CommentsState>(
    builder: (context, state) {
      final cubit = context.read<CommentsCubit>();
      if (state.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (state.failed) {
        return Center(
          child: TextButton(
            onPressed: cubit.load,
            child: const Text('No pudimos cargar los comentarios. Reintentar'),
          ),
        );
      }
      if (state.comments.isEmpty) {
        return const Center(
          child: Text(
            'Sé la primera persona en comentar.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: state.comments.length + (state.nextCursor == null ? 0 : 1),
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
              child: const Text(
                'Eliminar',
                style: TextStyle(color: AppColors.error),
              ),
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
  Widget build(BuildContext context) => Padding(
    key: Key('comment-${comment.id}'),
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAvatar(name: comment.name, size: 32),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${comment.name} · @${comment.author} · '
                '${RelativeTime.format(comment.createdAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(comment.body, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        IconButton(
          key: Key('comment-actions-${comment.id}'),
          tooltip: comment.canDelete ? 'Eliminar' : 'Reportar',
          iconSize: 18,
          onPressed: () => unawaited(_actions(context)),
          icon: Icon(
            comment.canDelete
                ? Icons.delete_outline_rounded
                : Icons.flag_outlined,
            color: AppColors.textSecondary,
          ),
        ),
      ],
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
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs,
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
            IconButton(
              key: const Key('comment-send'),
              tooltip: 'Enviar',
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: AppColors.primaryDeep,
                    ),
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
    CommentsNotice.closed => 'Esta publicación no acepta comentarios.',
  };
}
