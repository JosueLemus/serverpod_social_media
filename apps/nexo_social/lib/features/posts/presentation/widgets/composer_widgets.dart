import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../feed/domain/entities/post_extras.dart';
import '../bloc/post_composer_cubit.dart';

/// La copy de cada problema del compositor. Dice qué pasó con lo que la
/// persona intentaba hacer; el texto del servidor nunca se pinta.
extension ComposerIssueCopy on ComposerIssue {
  String get message => switch (this) {
    ComposerIssue.fileTooLarge =>
      'El archivo es muy pesado: hasta 10 MB para fotos y 50 MB para videos.',
    ComposerIssue.unsupportedFile =>
      'Ese formato no se acepta. Usa JPG, PNG, WebP o GIF; MP4, MOV o WebM.',
    ComposerIssue.publishFailed =>
      'No pudimos publicar. Tu borrador sigue acá para reintentar.',
    ComposerIssue.offline =>
      'Sin conexión. Tu borrador sigue acá para reintentar.',
    ComposerIssue.forbidden => 'Tu cuenta no puede publicar en este momento.',
  };
}

/// Vista previa de lo adjuntado, con su botón de quitar. La foto se ve tal
/// cual; un video muestra su nombre y su peso.
class ComposerMediaPreview extends StatelessWidget {
  const ComposerMediaPreview({
    super.key,
    required this.attachment,
    required this.onRemove,
  });

  final MediaAttachment attachment;
  final VoidCallback onRemove;

  bool get _isVideo => attachment.kind == PostMedia.video;

  String get _size {
    final mb = attachment.sizeBytes / (1024 * 1024);
    return mb >= 1
        ? '${mb.toStringAsFixed(1)} MB'
        : '${(attachment.sizeBytes / 1024).ceil()} KB';
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: AppRadii.medium,
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_isVideo)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primarySurface,
                    AppColors.primarySurfaceDeep,
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            Image.memory(
              attachment.bytes,
              key: const Key('composer-image-preview'),
              fit: BoxFit.cover,
              // Se decodifica al tamaño en que se muestra, no a la
              // resolución nativa de la foto.
              cacheWidth: 1280,
              errorBuilder: (context, error, stack) =>
                  const ColoredBox(color: AppColors.primarySurface),
            ),
          Positioned(
            top: AppSpacing.xs,
            right: AppSpacing.xs,
            child: InkResponse(
              key: const Key('composer-remove-media'),
              onTap: onRemove,
              radius: 22,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.neutral.withValues(alpha: .6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 17,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: AppSpacing.xs,
            left: AppSpacing.xs,
            right: AppSpacing.xl,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge(
                label: '${attachment.fileName} · $_size',
                color: AppColors.neutral.withValues(alpha: .6),
                icon: Icons.attach_file_rounded,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Editor de encuesta.
///
/// Stateful porque es dueño de un controller por opción. Construirlos en
/// `build` —que es como empezó— los recrea en cada tecla: el cursor salta al
/// principio en cuanto el cubit emite, y cada controller descartado queda sin
/// liberar.
class ComposerPollEditor extends StatefulWidget {
  const ComposerPollEditor({
    super.key,
    required this.poll,
    required this.onChanged,
    required this.onAddOption,
    required this.onRemove,
  });

  final DraftPoll poll;
  final void Function(int index, String value) onChanged;
  final VoidCallback onAddOption;
  final VoidCallback onRemove;

  @override
  State<ComposerPollEditor> createState() => _ComposerPollEditorState();
}

class _ComposerPollEditorState extends State<ComposerPollEditor> {
  final _controllers = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant ComposerPollEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  /// Agrega controllers para las opciones nuevas y libera los que sobran. No
  /// reescribe el texto de los existentes: el cubit ya tiene lo que el usuario
  /// escribió, y pisarlo movería el cursor en cada tecla.
  void _sync() {
    while (_controllers.length < widget.poll.options.length) {
      _controllers.add(
        TextEditingController(text: widget.poll.options[_controllers.length]),
      );
    }
    while (_controllers.length > widget.poll.options.length) {
      _controllers.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.poll_outlined,
                size: 17,
                color: AppColors.primaryDeep,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Encuesta interactiva',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                key: const Key('composer-remove-poll'),
                tooltip: 'Quitar encuesta',
                visualDensity: VisualDensity.compact,
                onPressed: widget.onRemove,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            ],
          ),
          Text(
            'Tu audiencia votará al instante en tiempo real',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final (index, controller) in _controllers.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: TextField(
                key: Key('poll-option-$index'),
                controller: controller,
                onChanged: (value) => widget.onChanged(index, value),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Opción ${index + 1}',
                  prefixIcon: const Icon(
                    Icons.radio_button_unchecked_rounded,
                    size: 17,
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 38),
                ),
              ),
            ),
          if (widget.poll.canAddOption)
            TextButton.icon(
              key: const Key('poll-add-option'),
              onPressed: widget.onAddOption,
              icon: const Icon(Icons.add_rounded, size: 17),
              label: const Text('Añadir opción'),
            ),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                'Duración: ${widget.poll.durationHours} horas',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Fila de adjuntos: foto, video, encuesta, enlace, emoción.
class ComposerAttachments extends StatelessWidget {
  const ComposerAttachments({
    super.key,
    required this.onAttach,
    required this.onPoll,
    required this.pollActive,
  });

  final ValueChanged<PostMedia> onAttach;
  final VoidCallback onPoll;
  final bool pollActive;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _Attachment(
        icon: Icons.photo_library_outlined,
        label: 'Foto',
        buttonKey: const Key('composer-attach-photo'),
        onTap: () => onAttach(PostMedia.image),
      ),
      _Attachment(
        icon: Icons.videocam_outlined,
        label: 'Video',
        buttonKey: const Key('composer-attach-video'),
        onTap: () => onAttach(PostMedia.video),
      ),
      _Attachment(
        icon: Icons.poll_outlined,
        label: 'Encuesta',
        buttonKey: const Key('composer-attach-poll'),
        active: pollActive,
        onTap: onPoll,
      ),
      _Attachment(
        icon: Icons.link_rounded,
        label: 'Enlace',
        buttonKey: const Key('composer-attach-link'),
        onTap: () {},
      ),
      _Attachment(
        icon: Icons.emoji_emotions_outlined,
        label: 'Emoción',
        buttonKey: const Key('composer-attach-mood'),
        onTap: () {},
      ),
    ],
  );
}

class _Attachment extends StatelessWidget {
  const _Attachment({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.buttonKey,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Key buttonKey;
  final bool active;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkResponse(
          key: buttonKey,
          onTap: onTap,
          radius: 28,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: active ? AppColors.primaryDeep : AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 19,
              color: active ? Colors.white : AppColors.textOnBrandSurface,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

/// El bloque de IA, marcado como próximamente.
///
/// Está apagado a propósito y lo dice: el Notion pone la IA en P2 detrás de
/// una interfaz, y un botón que parece funcionar y no hace nada es peor que
/// uno que declara que todavía no existe.
class ComposerAiTeaser extends StatelessWidget {
  const ComposerAiTeaser({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.primarySurface,
      borderRadius: AppRadii.medium,
      border: Border.all(color: AppColors.primarySurfaceDeep),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Flexible(
              child: StatusBadge(
                label: 'Asistente IA · Próximamente',
                color: AppColors.primaryDeep,
                icon: Icons.auto_awesome,
              ),
            ),
            const Spacer(),
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Optimiza tu alcance en segundos',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Genera ganchos creativos, títulos de impacto y hashtags '
          'optimizados con IA en la versión Pro.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const _WaitlistAvatars(),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: SizedBox(
                height: 36,
                child: FilledButton.icon(
                  onPressed: () {},
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                  label: const Text(
                    'Unirme a la lista',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _WaitlistAvatars extends StatelessWidget {
  const _WaitlistAvatars();

  static const _names = ['Marcos', 'Lucía', 'Sofía'];

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 26 + 16.0 * _names.length,
    height: 28,
    child: Stack(
      children: [
        for (final (index, name) in _names.indexed)
          Positioned(
            left: index * 16,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.primarySurface, width: 2),
                ),
              ),
              child: UserAvatar(name: name, size: 24),
            ),
          ),
        Positioned(
          left: _names.length * 16,
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.primaryDeep,
              shape: BoxShape.circle,
              border: Border.fromBorderSide(
                BorderSide(color: AppColors.primarySurface, width: 2),
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              '+48',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Los dos interruptores de publicación.
class ComposerToggles extends StatelessWidget {
  const ComposerToggles({
    super.key,
    required this.allowComments,
    required this.notifyVip,
    required this.onAllowComments,
    required this.onNotifyVip,
  });

  final bool allowComments;
  final bool notifyVip;
  final ValueChanged<bool> onAllowComments;
  final ValueChanged<bool> onNotifyVip;

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        _ToggleRow(
          switchKey: const Key('composer-allow-comments'),
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Permitir comentarios',
          detail: 'Tu audiencia podrá responder e interactuar',
          value: allowComments,
          onChanged: onAllowComments,
        ),
        const Divider(height: 1),
        _ToggleRow(
          switchKey: const Key('composer-notify-vip'),
          icon: Icons.notifications_active_outlined,
          iconColor: AppColors.secondary,
          title: 'Notificar a suscriptores VIP',
          detail: 'Envía una alerta instantánea prioritaria',
          badge: 'Push',
          value: notifyVip,
          onChanged: onNotifyVip,
        ),
      ],
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.switchKey,
    required this.icon,
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
    this.badge,
    this.iconColor = AppColors.primaryDeep,
  });

  final Key switchKey;
  final IconData icon;
  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? badge;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.sm),
    child: Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: AppColors.primarySurface,
          child: Icon(icon, size: 17, color: iconColor),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 6),
                    StatusBadge(label: badge!),
                  ],
                ],
              ),
              Text(detail, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Switch(key: switchKey, value: value, onChanged: onChanged),
      ],
    ),
  );
}
