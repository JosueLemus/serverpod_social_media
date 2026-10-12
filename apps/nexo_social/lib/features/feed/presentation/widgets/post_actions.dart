import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/nexo_mascot.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../admin/presentation/widgets/reason_sheet.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_extras.dart';

/// Lo que se puede hacer con un post desde el menú "…". Las opciones las
/// decide el servidor (`canEdit`, `canDelete`): el menú no ofrece lo que
/// después se va a rechazar.
sealed class PostAction {
  const PostAction();
}

class EditPost extends PostAction {
  const EditPost(this.body);

  final String body;
}

class DeletePost extends PostAction {
  const DeletePost();
}

class ReportPost extends PostAction {
  const ReportPost(this.reason);

  final ModerationReason reason;
}

/// Abre el menú y devuelve la decisión ya confirmada, o null. No aplica
/// nada: lo aplica quien lo abrió, igual que la hoja de moderación.
Future<PostAction?> showPostActions(BuildContext context, Post post) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (post.canEdit)
            ListTile(
              key: const Key('post-action-edit'),
              leading: const NexoIcon(NexoGlyph.edit, size: 22),
              title: const Text('Editar texto'),
              onTap: () => Navigator.pop(sheetContext, 'edit'),
            ),
          if (post.canDelete)
            ListTile(
              key: const Key('post-action-delete'),
              iconColor: AppColors.error,
              textColor: AppColors.error,
              leading: const NexoIcon(NexoGlyph.trash, size: 22),
              title: const Text('Eliminar'),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
          // Lo propio no se reporta: se edita o se elimina.
          if (!post.canEdit)
            ListTile(
              key: const Key('post-action-report'),
              leading: const NexoIcon(NexoGlyph.flag, size: 22),
              title: const Text('Reportar'),
              onTap: () => Navigator.pop(sheetContext, 'report'),
            ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return null;

  switch (choice) {
    case 'edit':
      final body = await _editBody(context, post.body);
      return body == null ? null : EditPost(body);
    case 'delete':
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Eliminar publicación'),
          content: const Text(
            'Deja de verse para todos, con sus likes y comentarios.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              key: const Key('confirm-delete-post'),
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      return (confirmed ?? false) ? const DeletePost() : null;
    case 'report':
      final reason = await showReasonSheet(
        context,
        title: 'Reportar publicación',
        detail:
            'Lo revisa el equipo de moderación. Quien la publicó no se entera de quién la reportó.',
        confirmLabel: 'Reportar',
        destructive: false,
      );
      return reason == null ? null : ReportPost(reason);
  }
  return null;
}

Future<String?> _editBody(BuildContext context, String current) =>
    showDialog<String>(
      context: context,
      builder: (_) => _EditBodyDialog(initial: current),
    );

/// Stateful porque es dueño de su controller: construirlo en `build` lo
/// recrea en cada tecla y el cursor salta al principio.
class _EditBodyDialog extends StatefulWidget {
  const _EditBodyDialog({required this.initial});

  final String initial;

  @override
  State<_EditBodyDialog> createState() => _EditBodyDialogState();
}

class _EditBodyDialogState extends State<_EditBodyDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Editar publicación'),
    content: TextField(
      key: const Key('edit-post-input'),
      controller: _controller,
      minLines: 3,
      maxLines: 8,
      maxLength: 2200,
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      ValueListenableBuilder(
        valueListenable: _controller,
        builder: (context, value, _) => FilledButton(
          key: const Key('save-post-edit'),
          onPressed: value.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, value.text.trim()),
          child: const Text('Guardar'),
        ),
      ),
    ],
  );
}

/// Quién dio like. Recibe la lista ya leída: la hoja no conoce el repositorio.
Future<void> showLikersSheet(
  BuildContext context,
  Future<List<PostLiker>> likers,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (sheetContext) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(sheetContext).height * .5,
      child: FutureBuilder<List<PostLiker>>(
        future: likers,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('No pudimos cargar los me gusta.'));
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MascotIllustration(NexoMascot.heart, size: 112),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Todavía nadie dio me gusta.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Me gusta',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final liker in items)
                ListTile(
                  leading: UserAvatar(name: liker.name, size: 34),
                  title: Text(
                    liker.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('@${liker.username}'),
                ),
            ],
          );
        },
      ),
    ),
  ),
);
