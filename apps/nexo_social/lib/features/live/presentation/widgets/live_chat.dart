import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../../../moderation/presentation/widgets/moderation_sheet.dart';
import '../bloc/live_room_cubit.dart';

/// El vidrio oscuro de todo lo que flota sobre el video: tinta translúcida.
/// Sobre la imagen no hay liner, así que el chrome baja la luz en vez de
/// taparla con un panel opaco.
final _glass = AppColors.neutral.withValues(alpha: .55);

/// El filo de ese vidrio: un hilo de blanco apenas visible, para que una
/// cápsula oscura no se pierda sobre un cuadro oscuro.
final _glassEdge = AppColors.onMedia.withValues(alpha: .16);

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
    this.hostId,
  });

  final List<LiveComment> comments;
  final String emptyLabel;

  /// El techo del chat. Sin valor, un tercio de la pantalla: en la sala el
  /// chat crece hacia arriba hasta ahí y después scrollea. El Studio lo
  /// acota al escenario, que no ocupa toda la pantalla.
  final double? maxHeight;

  /// Quién transmite. Sus mensajes llevan la insignia HOST: en un chat que
  /// corre rápido, la respuesta del host es la que la gente busca.
  final String? hostId;

  bool _byHost(LiveComment comment) {
    final host = hostId;
    return host != null && host.isNotEmpty && comment.authorId == host;
  }

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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onMediaSecondary,
              shadows: _legibility,
            ),
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
        itemBuilder: (context, index) {
          final comment = comments[comments.length - 1 - index];
          return LiveChatLine(comment: comment, byHost: _byHost(comment));
        },
      ),
    );
  }
}

/// Una sombra corta para el texto que va suelto sobre el video, sin burbuja.
const _legibility = [
  Shadow(color: AppColors.stageDark, blurRadius: 6, offset: Offset(0, 1)),
];

class LiveChatLine extends StatelessWidget {
  const LiveChatLine({super.key, required this.comment, this.byHost = false});

  final LiveComment comment;

  /// Lo escribió quien transmite.
  final bool byHost;

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
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: UserAvatar(
              name: comment.author,
              imageUrl: comment.authorAvatarUrl,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Material(
              color: _glass,
              borderRadius: AppRadii.medium,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: Key('chat-${comment.id}'),
                onLongPress: () => unawaited(_moderate(context)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    6,
                    AppSpacing.sm,
                    7,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Wrap: un nombre largo más la insignia no entran en
                      // una burbuja angosta, y una fila recortaría la
                      // insignia, que es lo que importa.
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            comment.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleSmall?.copyWith(
                              fontSize: 13,
                              color: comment.isMine
                                  ? AppColors.primary
                                  : AppColors.onMediaSecondary,
                            ),
                          ),
                          if (byHost)
                            StatusBadge(
                              label: 'Host',
                              color: AppColors.vinylLime,
                              foreground: AppColors.ink,
                            ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        comment.body,
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.onMedia,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// El campo para comentar sobre el video. Lo usan la audiencia y el host: el
/// host también contesta en su propio chat, como en cualquier vivo.
///
/// [trailing] son los controles al lado del campo (regalo, amor) que sólo
/// tiene la audiencia.
class LiveChatComposer extends StatelessWidget {
  const LiveChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.trailing = const [],
    this.fieldKey = const Key('live-comment-field'),
    this.sendKey = const Key('live-send'),
    this.liftAboveKeyboard = true,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final List<Widget> trailing;
  final Key fieldKey;
  final Key sendKey;

  /// En la sala el Scaffold no se redimensiona con el teclado, así que el
  /// campo se sube solo. En el Studio la página sí se acomoda, y subirlo de
  /// nuevo lo dejaría flotando a media pantalla.
  final bool liftAboveKeyboard;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        (liftAboveKeyboard ? MediaQuery.viewInsetsOf(context).bottom : 0) +
            AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: AppSizes.searchHeight,
              padding: const EdgeInsets.only(left: AppSpacing.md),
              decoration: BoxDecoration(
                color: _glass,
                borderRadius: AppRadii.pill,
                border: Border.all(color: _glassEdge),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: fieldKey,
                      controller: controller,
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.onMedia,
                      ),
                      cursorColor: AppColors.primary,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                      decoration: InputDecoration(
                        hintText: 'Escribe un comentario',
                        hintStyle: text.bodyMedium?.copyWith(
                          color: AppColors.onMediaSecondary,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  IconButton(
                    key: sendKey,
                    tooltip: 'Enviar',
                    onPressed: onSend,
                    icon: NexoIcon(
                      NexoGlyph.send,
                      size: 20,
                      color: AppColors.onMedia,
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final control in trailing) ...[
            const SizedBox(width: AppSpacing.xs),
            control,
          ],
        ],
      ),
    );
  }
}

/// Botón circular de vidrio oscuro, el lenguaje de todo control sobre video.
///
/// El ícono es un [NexoIcon] ([glyph]); [icon] queda para lo que todavía no
/// tiene glifo propio (el regalo).
class LiveGlassButton extends StatelessWidget {
  const LiveGlassButton({
    super.key,
    this.icon,
    this.glyph,
    required this.tooltip,
    required this.onTap,
    this.background,
    this.child,
  }) : assert(
         icon != null || glyph != null || child != null,
         'LiveGlassButton necesita un glifo, un ícono o un hijo',
       );

  final IconData? icon;
  final NexoGlyph? glyph;
  final String tooltip;

  /// Null lo deja apagado: un control sin acción no se finge activo.
  final VoidCallback? onTap;
  final Color? background;

  /// Reemplaza al ícono cuando el control necesita animarse.
  final Widget? child;

  /// El disco mide lo mismo que el mínimo táctil: un control sobre video que
  /// se ve más chico que su área de toque hace errar el dedo.
  static const size = 44.0;

  @override
  Widget build(BuildContext context) {
    final face =
        child ??
        (glyph != null
            ? NexoIcon(glyph!, size: 20, color: AppColors.onMedia)
            : Icon(icon, size: 20, color: AppColors.onMedia));
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: onTap != null,
        child: InkResponse(
          onTap: onTap,
          radius: size / 2 + 4,
          child: Opacity(
            opacity: onTap == null ? .45 : 1,
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background ?? _glass,
                shape: BoxShape.circle,
                border: Border.all(
                  color: background == null ? _glassEdge : AppColors.onMedia,
                  width: background == null ? 1 : 2,
                ),
              ),
              child: face,
            ),
          ),
        ),
      ),
    );
  }
}

/// Una cápsula de vidrio oscuro para lo que flota sobre el video: el host,
/// los espectadores. La misma piel que [LiveGlassButton].
class LiveGlassPill extends StatelessWidget {
  const LiveGlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    constraints: const BoxConstraints(minHeight: LiveGlassButton.size),
    decoration: BoxDecoration(
      color: _glass,
      borderRadius: AppRadii.pill,
      border: Border.all(color: _glassEdge),
    ),
    child: child,
  );
}
