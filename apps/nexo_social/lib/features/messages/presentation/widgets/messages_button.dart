import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../bloc/unread_messages_cubit.dart';

/// El botón "Mensajes" de la barra del feed, con las conversaciones sin leer.
class MessagesButton extends StatelessWidget {
  const MessagesButton({super.key});

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<UnreadMessagesCubit>().state;
    return IconButton(
      key: const Key('feed-messages'),
      tooltip: unread == 0 ? 'Mensajes' : 'Mensajes: $unread sin leer',
      onPressed: () => unawaited(context.push(AppRoutes.messages)),
      icon: Badge(
        isLabelVisible: unread > 0,
        backgroundColor: AppColors.secondary,
        textColor: AppColors.onSecondary,
        label: Text(unread > 9 ? '9+' : '$unread'),
        child: const NexoIcon(NexoGlyph.comment, size: 22),
      ),
    );
  }
}
