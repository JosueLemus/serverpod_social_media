import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/nexo_mascot.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/direct_message.dart';
import '../bloc/messages_inbox_cubit.dart';

/// La bandeja de mensajes directos (SDD 0010). Ruta raíz empujada sobre el
/// shell, como editar perfil: es una tarea, no una pestaña.
class MessagesInboxPage extends StatelessWidget {
  const MessagesInboxPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => MessagesInboxCubit(sl())..load(),
    child: const _InboxView(),
  );
}

class _InboxView extends StatelessWidget {
  const _InboxView();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final me = auth is AuthAuthenticated ? auth.user.id : '';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
          icon: const NexoIcon(NexoGlyph.back),
        ),
        title: const Text('Mensajes'),
      ),
      body: BlocBuilder<MessagesInboxCubit, InboxState>(
        builder: (context, state) {
          final cubit = context.read<MessagesInboxCubit>();
          return switch (state.status) {
            InboxStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            InboxStatus.failure => Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppErrorView(onRetry: () => unawaited(cubit.load())),
              ),
            ),
            InboxStatus.ready when state.isEmpty => Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppEmptyView(
                  mascot: NexoMascot.empty,
                  title: 'Todavía no hay mensajes',
                  message:
                      'Escríbele a alguien desde su perfil: el botón de '
                      'mensaje está al lado de Seguir.',
                  actionLabel: 'Explorar',
                  onAction: () => context.go(AppRoutes.explore),
                ),
              ),
            ),
            InboxStatus.ready => RefreshIndicator(
              onRefresh: cubit.refresh,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.extentAfter < 200) {
                    unawaited(cubit.loadMore());
                  }
                  return false;
                },
                child: ListView.separated(
                  key: const Key('messages-inbox-list'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  itemCount: state.conversations.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _ConversationTile(
                    conversation: state.conversations[index],
                    me: me,
                  ),
                ),
              ),
            ),
          };
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.me});

  final Conversation conversation;
  final String me;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final peer = conversation.peer;
    final last = conversation.lastMessage;
    final unread = conversation.unreadCount > 0;
    final preview = last == null
        ? ''
        : last.authorId == me
        ? 'Tú: ${last.body}'
        : last.body;
    return InkWell(
      key: Key('conversation-${conversation.id}'),
      onTap: () =>
          unawaited(context.push(AppRoutes.conversation(conversation.id))),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            UserAvatar(name: peer.name, imageUrl: peer.avatarUrl, size: 48),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    peer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(
                      fontWeight: unread ? FontWeight.w800 : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: unread
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: unread ? FontWeight.w700 : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  RelativeTime.format(conversation.lastActivityAt),
                  style: text.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                if (unread) ...[
                  const SizedBox(height: 4),
                  _UnreadPill(count: conversation.unreadCount),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnreadPill extends StatelessWidget {
  const _UnreadPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: const BoxDecoration(
      color: AppColors.secondary,
      borderRadius: AppRadii.pill,
    ),
    child: Text(
      count > 9 ? '9+' : '$count',
      style: const TextStyle(
        color: AppColors.sticker,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
