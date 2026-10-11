import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../../../moderation/presentation/widgets/moderation_sheet.dart';
import '../bloc/live_room_cubit.dart';

/// Los comentarios de un vivo, flotando sobre el video.
///
/// Lo usan la sala y el Studio: el host tiene que ver lo mismo que su
/// audiencia, y moderar desde ahí con la misma pulsación larga.
///
/// Alto acotado y sin fondo propio: el chat de un vivo es efímero, y un panel
/// opaco que se come media pantalla compite con lo que la gente vino a ver.
class LiveChatOverlay extends StatelessWidget {
  const LiveChatOverlay({
    super.key,
    required this.comments,
    this.emptyLabel = 'Sé la primera persona en comentar',
    this.maxHeight,
  });

  final List<LiveComment> comments;
  final String emptyLabel;

  /// El techo del chat. Sin valor, un tercio de la pantalla: en la sala el
  /// chat crece hacia arriba hasta ahí y después scrollea. El Studio lo
  /// acota al escenario, que no ocupa toda la pantalla.
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            emptyLabel,
            style: const TextStyle(color: Colors.white54, fontSize: 12.5),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? MediaQuery.sizeOf(context).height * .32,
      ),
      child: ListView.builder(
        // Anclado abajo, que es donde llega lo nuevo.
        reverse: true,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        itemCount: comments.length,
        itemBuilder: (context, index) =>
            LiveChatLine(comment: comments[comments.length - 1 - index]),
      ),
    );
  }
}

class LiveChatLine extends StatelessWidget {
  const LiveChatLine({super.key, required this.comment});

  final LiveComment comment;

  /// Moderar sale de una pulsación larga sobre el mensaje, no de un ícono por
  /// fila: con seis acciones disponibles, un control por comentario convierte
  /// el chat en una consola y le come la pantalla al directo.
  Future<void> _moderate(BuildContext context) async {
    final cubit = context.read<LiveRoomCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final issueBefore = cubit.state.issueSerial;
    final decision = await showModerationSheet(
      context,
      author: comment.author,
      comment: comment.body,
      canModerate: cubit.state.canModerate,
    );
    if (decision == null) return;

    switch (decision.type) {
      case ModerationType.hideComment:
        await cubit.hideComment(comment);
      case ModerationType.report:
        await cubit.reportComment(comment);
      case ModerationType.muteUser ||
          ModerationType.banUser ||
          ModerationType.dismissReport:
        cubit.recordModeration('${decision.confirmation} (${comment.author})');
    }
    // Si el servidor lo rechazó, el listener ya avisó por qué.
    if (cubit.state.issue != null && cubit.state.issueSerial != issueBefore) {
      return;
    }
    // Se confirma qué pasó. Una acción de moderación que no deja rastro
    // visible se siente como que no se aplicó, y el moderador la repite.
    messenger.showSnackBar(SnackBar(content: Text(decision.confirmation)));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAvatar(name: comment.author, size: 24),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: InkWell(
            key: Key('chat-${comment.id}'),
            onLongPress: () => unawaited(_moderate(context)),
            borderRadius: AppRadii.medium,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.neutral.withValues(alpha: .5),
                borderRadius: AppRadii.medium,
              ),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  children: [
                    TextSpan(
                      text: '${comment.author} ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: comment.isMine
                            ? AppColors.primarySurface
                            : Colors.white70,
                      ),
                    ),
                    TextSpan(text: comment.body),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    ),
  );
}
