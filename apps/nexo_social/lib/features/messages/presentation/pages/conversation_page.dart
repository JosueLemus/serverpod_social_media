import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/nexo_mascot.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/direct_message.dart';
import '../../domain/repositories/messages_repository.dart';
import '../bloc/conversation_cubit.dart';
import '../bloc/unread_messages_cubit.dart';

/// Un chat 1 a 1 (SDD 0010). Se abre con [conversationId] desde la bandeja,
/// o con [userId] desde un perfil: en ese caso la conversación se crea si
/// hacía falta.
class ConversationPage extends StatelessWidget {
  const ConversationPage({super.key, this.conversationId, this.userId})
    : assert(conversationId != null || userId != null);

  final String? conversationId;
  final String? userId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => _open(context, sl()),
    child: const _ChatView(),
  );

  ConversationCubit _open(BuildContext context, MessagesRepository messages) {
    final auth = context.read<AuthCubit>().state;
    // Resuelto acá, sincrónico: más tarde este context puede no existir.
    final unread = context.read<UnreadMessagesCubit>();
    final cubit = ConversationCubit(
      messages,
      me: auth is AuthAuthenticated ? auth.user.id : '',
      onUnreadChanged: unread.set,
    );
    final id = conversationId;
    unawaited(id != null ? cubit.load(id) : cubit.openWith(userId!));
    return cubit;
  }
}

extension on ChatIssue {
  String get message => switch (this) {
    ChatIssue.forbidden => 'No puedes escribirle a esta cuenta.',
    ChatIssue.suspended =>
      'Tu cuenta está suspendida: no puedes mandar mensajes.',
    ChatIssue.tooFast => 'Vas muy rápido. Espera un segundo y reintenta.',
    ChatIssue.unavailable =>
      'No pudimos mandar el mensaje. Toca para reintentar.',
  };
}

class _ChatView extends StatelessWidget {
  const _ChatView();

  @override
  Widget build(BuildContext context) =>
      BlocListener<ConversationCubit, ChatState>(
        listenWhen: (previous, current) =>
            current.status == ChatStatus.ready &&
            current.issue != null &&
            previous.issueSerial != current.issueSerial,
        listener: (context, state) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.issue!.message))),
        child: BlocBuilder<ConversationCubit, ChatState>(
          builder: (context, state) {
            final peer = state.conversation?.peer;
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                titleSpacing: 0,
                leading: IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => unawaited(Navigator.of(context).maybePop()),
                  icon: const NexoIcon(NexoGlyph.back),
                ),
                title: peer == null
                    ? const Text('Mensajes')
                    : _PeerTitle(peer: peer),
              ),
              body: switch (state.status) {
                ChatStatus.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                ChatStatus.notFound => Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: AppEmptyView(
                      mascot: NexoMascot.lock,
                      title: 'No encontramos esta conversación',
                      message:
                          'Puede que no exista o que la cuenta ya no pueda '
                          'recibir mensajes.',
                      actionLabel: 'Ir a mensajes',
                      onAction: () => context.go(AppRoutes.messages),
                    ),
                  ),
                ),
                ChatStatus.failure => Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: AppErrorView(
                      onRetry: () {
                        final page = context
                            .findAncestorWidgetOfExactType<ConversationPage>();
                        final cubit = context.read<ConversationCubit>();
                        final id = page?.conversationId;
                        unawaited(
                          id != null
                              ? cubit.load(id)
                              : cubit.openWith(page!.userId!),
                        );
                      },
                    ),
                  ),
                ),
                ChatStatus.ready => Column(
                  children: [
                    if (state.reconnecting) const _ReconnectingBanner(),
                    Expanded(child: _MessageList(state: state)),
                    const _Composer(),
                  ],
                ),
              },
            );
          },
        ),
      );
}

class _PeerTitle extends StatelessWidget {
  const _PeerTitle({required this.peer});

  final ChatPeer peer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => unawaited(context.push(AppRoutes.profileOf(peer.username))),
      borderRadius: AppRadii.medium,
      child: Row(
        children: [
          UserAvatar(name: peer.name, imageUrl: peer.avatarUrl, size: 34),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  peer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium,
                ),
                Text(
                  '@${peer.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
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

class _ReconnectingBanner extends StatelessWidget {
  const _ReconnectingBanner();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('dm-reconnecting'),
    width: double.infinity,
    color: AppColors.linerHigh,
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(
      'Reconectando…',
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
    ),
  );
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.state});

  final ChatState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ConversationCubit>();
    final messages = state.messages;
    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Todavía no se escribieron. Manda el primer mensaje.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    // Invertida: anclada abajo, donde llega lo nuevo.
    return ListView.builder(
      key: const Key('dm-message-list'),
      reverse: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      itemCount: messages.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return Center(
            child: state.loadingOlder
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    key: const Key('dm-load-older'),
                    onPressed: () => unawaited(cubit.loadOlder()),
                    child: const Text('Ver mensajes anteriores'),
                  ),
          );
        }
        final message = messages[messages.length - 1 - index];
        return _Bubble(
          message: message,
          mine: message.authorId == cubit.me,
          onRetry: () => unawaited(cubit.retry(message.id)),
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.onRetry,
  });

  final DirectMessage message;
  final bool mine;
  final VoidCallback onRetry;

  static String _time(DateTime moment) {
    final local = moment.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final failed = message.delivery == MessageDelivery.failed;
    final status = switch (message.delivery) {
      MessageDelivery.sending => 'Enviando…',
      MessageDelivery.failed => 'No se envió · Toca para reintentar',
      MessageDelivery.sent => _time(message.createdAt),
    };
    // Lo propio es el sticker blanco con tinta; lo ajeno, el liner.
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * .75,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: mine ? AppColors.sticker : AppColors.linerHigh,
        borderRadius: AppRadii.medium,
        border: failed ? Border.all(color: AppColors.error, width: 1.5) : null,
      ),
      child: Text(
        message.body,
        style: text.bodyMedium?.copyWith(
          color: mine ? AppColors.ink : AppColors.textPrimary,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (failed)
            InkWell(
              key: Key('dm-retry-${message.id}'),
              onTap: onRetry,
              borderRadius: AppRadii.medium,
              child: bubble,
            )
          else
            bubble,
          const SizedBox(height: 2),
          Text(
            status,
            key: Key('dm-status-${message.id}'),
            style: text.labelSmall?.copyWith(
              color: failed ? AppColors.error : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// El campo de escribir. Dueño de su controller: construirlo en `build` lo
/// recrearía en cada tecla y el cursor saltaría al principio.
class _Composer extends StatefulWidget {
  const _Composer();

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    unawaited(context.read<ConversationCubit>().send(text));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: const Key('dm-composer-field'),
              controller: _controller,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              inputFormatters: [LengthLimitingTextInputFormatter(1000)],
              decoration: const InputDecoration(
                hintText: 'Escribe un mensaje…',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton.filled(
            key: const Key('dm-send'),
            tooltip: 'Enviar',
            onPressed: _controller.text.trim().isEmpty ? null : _send,
            icon: const NexoIcon(NexoGlyph.send, size: 20),
          ),
        ],
      ),
    ),
  );
}
