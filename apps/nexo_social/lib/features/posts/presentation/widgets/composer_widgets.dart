import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/nexo_mascot.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/sticker.dart';
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
    ComposerIssue.pickerFailed =>
      'No pudimos abrir tu galería. Revisa que Nexo tenga permiso para '
          'acceder a tus fotos.',
    ComposerIssue.publishFailed =>
      'No pudimos publicar. Tu borrador sigue acá para reintentar.',
    ComposerIssue.offline =>
      'Sin conexión. Tu borrador sigue acá para reintentar.',
    ComposerIssue.forbidden => 'Tu cuenta no puede publicar en este momento.',
  };
}

/// Vista previa de lo adjuntado, con su botón de quitar. La foto se ve tal
/// cual; un video muestra su nombre y su peso.
///
/// Es un sticker troquelado: lo que se va a publicar ya tiene el borde blanco
/// de lo despegado, igual que en el feed.
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
  Widget build(BuildContext context) => StickerFrame(
    fill: AppColors.linerHigh,
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_isVideo)
            Center(
              child: NexoIcon(
                NexoGlyph.play,
                filled: true,
                size: 44,
                color: AppColors.textSecondary,
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
              errorBuilder: (context, error, stack) => Center(
                child: NexoIcon(
                  NexoGlyph.media,
                  size: 36,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          Positioned(
            top: AppSpacing.xs,
            right: AppSpacing.xs,
            child: Tooltip(
              message: 'Quitar adjunto',
              child: Material(
                color: AppColors.stageScrim,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: const Key('composer-remove-media'),
                  onTap: onRemove,
                  child: SizedBox.square(
                    dimension: 34,
                    child: Center(
                      child: NexoIcon(
                        NexoGlyph.close,
                        size: 15,
                        color: AppColors.sticker,
                      ),
                    ),
                  ),
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
              child: _FileTag(
                glyph: _isVideo ? NexoGlyph.play : NexoGlyph.media,
                label: '${attachment.fileName} · $_size',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Nombre y peso del archivo, sobre el velo para leerse encima de la foto.
/// Sin mayúsculas forzadas: es un nombre de archivo, no una insignia.
class _FileTag extends StatelessWidget {
  const _FileTag({required this.glyph, required this.label});

  final NexoGlyph glyph;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: const BoxDecoration(
      color: AppColors.stageScrim,
      borderRadius: AppRadii.pill,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NexoIcon(glyph, size: 13, color: AppColors.sticker),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.sticker,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
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
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                NexoIcon(NexoGlyph.stats, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text('Encuesta interactiva', style: text.titleSmall),
                ),
                IconButton(
                  key: const Key('composer-remove-poll'),
                  tooltip: 'Quitar encuesta',
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onRemove,
                  icon: const NexoIcon(NexoGlyph.close, size: 16),
                ),
              ],
            ),
            Text(
              'Tu audiencia votará al instante en tiempo real',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
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
                    prefixIcon: const Center(child: _OptionRing()),
                    prefixIconConstraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 20,
                    ),
                  ),
                ),
              ),
            if (widget.poll.canAddOption)
              TextButton.icon(
                key: const Key('poll-add-option'),
                onPressed: widget.onAddOption,
                icon: const NexoIcon(NexoGlyph.add, size: 15),
                label: const Text('Añadir opción'),
              ),
            const SizedBox(height: AppSpacing.xxs),
            Row(
              children: [
                NexoIcon(
                  NexoGlyph.clock,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Duración: ${widget.poll.durationHours} horas',
                  style: text.bodySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// El círculo vacío de una opción de encuesta: dónde va a caer el voto.
class _OptionRing extends StatelessWidget {
  const _OptionRing();

  @override
  Widget build(BuildContext context) => Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.textSecondary, width: 2),
    ),
  );
}

/// Fila de herramientas: foto, video, encuesta, enlace, emoción.
///
/// Cada una es un sticker en reposo, todavía pegado a la plancha. Al activarse
/// se despega: blanco con tinta, como un filtro elegido.
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
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Attachment(
        glyph: NexoGlyph.media,
        label: 'Foto',
        buttonKey: const Key('composer-attach-photo'),
        onTap: () => onAttach(PostMedia.image),
      ),
      _Attachment(
        glyph: NexoGlyph.play,
        label: 'Video',
        buttonKey: const Key('composer-attach-video'),
        onTap: () => onAttach(PostMedia.video),
      ),
      // Encuesta, enlace y emoción no viajan al servidor todavía: un post no
      // tiene dónde guardarlos. Deshabilitados y no escondidos, porque el
      // diseño los tiene; antes la encuesta se componía entera y se
      // descartaba en silencio al publicar (SDD 0007, F11).
      _Attachment(
        glyph: NexoGlyph.stats,
        label: 'Encuesta',
        buttonKey: const Key('composer-attach-poll'),
        active: pollActive,
        tooltip: 'Encuestas: muy pronto',
        onTap: null,
      ),
      const _Attachment(
        glyph: NexoGlyph.link,
        label: 'Enlace',
        buttonKey: Key('composer-attach-link'),
        tooltip: 'Enlaces: muy pronto',
        onTap: null,
      ),
      const _Attachment(
        glyph: NexoGlyph.emoji,
        label: 'Emoción',
        buttonKey: Key('composer-attach-mood'),
        tooltip: 'Emociones: muy pronto',
        onTap: null,
      ),
    ],
  );
}

class _Attachment extends StatelessWidget {
  const _Attachment({
    required this.glyph,
    required this.label,
    required this.onTap,
    required this.buttonKey,
    this.active = false,
    this.tooltip,
  });

  final NexoGlyph glyph;
  final String label;

  /// Null deshabilita: se dibuja apagado y el tooltip dice por qué.
  final VoidCallback? onTap;
  final Key buttonKey;
  final bool active;
  final String? tooltip;

  static const _side = 48.0;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    // Despegado (activo), en reposo sobre la plancha, o todavía no
    // disponible: un paso más hundido y con el trazo apagado.
    final (fill, tint) = active
        ? (AppColors.sticker, AppColors.ink)
        : enabled
        ? (AppColors.linerHigh, AppColors.textPrimary)
        : (AppColors.surface, AppColors.textTertiary);
    final button = AnimatedContainer(
      duration: AppMotion.feedbackDuration,
      curve: Curves.easeOutCubic,
      width: _side,
      height: _side,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: buttonKey,
          onTap: onTap,
          child: Center(
            child: NexoIcon(glyph, size: 21, filled: active, color: tint),
          ),
        ),
      ),
    );
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tooltip case final message?)
            Tooltip(message: message, child: button)
          else
            button,
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: active
                  ? AppColors.textPrimary
                  : enabled
                  ? AppColors.textSecondary
                  : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// El bloque de IA, marcado como próximamente.
///
/// Está apagado a propósito y lo dice: el Notion pone la IA en P2 detrás de
/// una interfaz, y un botón que parece funcionar y no hace nada es peor que
/// uno que declara que todavía no existe. Por lo mismo no muestra una lista
/// de espera: no existe, y una fila de avatares con "+48" la inventaba.
class ComposerAiTeaser extends StatelessWidget {
  const ComposerAiTeaser({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.medium,
      ),
      child: Row(
        children: [
          const MascotIllustration(NexoMascot.lock, size: 60),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wrap y no Row: a 320 el título y la insignia no entran
                // juntos, y una fila recortaría la insignia.
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Asistente IA', style: text.titleSmall),
                    StatusBadge(
                      label: 'Próximamente',
                      color: AppColors.vinylViolet,
                      foreground: AppColors.ink,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Genera ganchos creativos, títulos de impacto y hashtags '
                  'optimizados con IA en la versión Pro.',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Los dos interruptores de publicación, como sección agrupada de ajustes.
///
/// Es una lista de ajustes y se ve como tal, no como un sticker: relleno sin
/// filete y filas separadas por un divisor con sangría.
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

  static const _radius = BorderRadius.all(Radius.circular(22));

  /// Donde arranca el texto de la fila: el divisor empieza ahí, como en una
  /// lista agrupada de iOS.
  static const _dividerIndent = AppSpacing.md + 22 + AppSpacing.sm;

  @override
  Widget build(BuildContext context) => Material(
    // Material y no una caja pintada: la reacción del Switch se dibuja en el
    // Material más cercano, y con el del Scaffold quedaría debajo del relleno.
    color: AppColors.surface,
    borderRadius: _radius,
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        _ToggleRow(
          switchKey: const Key('composer-allow-comments'),
          glyph: NexoGlyph.comment,
          title: 'Permitir comentarios',
          detail: 'Tu audiencia podrá responder e interactuar',
          value: allowComments,
          onChanged: onAllowComments,
        ),
        const Divider(height: 1, indent: _dividerIndent),
        // Apagado hasta que existan las notificaciones (M5): el interruptor
        // se guardaba en el borrador y no se enviaba a nadie.
        const _ToggleRow(
          switchKey: Key('composer-notify-vip'),
          glyph: NexoGlyph.activity,
          title: 'Notificar a suscriptores VIP',
          detail: 'Llega con las notificaciones push',
          badge: 'Pronto',
          value: false,
          onChanged: null,
        ),
      ],
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.switchKey,
    required this.glyph,
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
    this.badge,
  });

  final Key switchKey;
  final NexoGlyph glyph;
  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final enabled = onChanged != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          NexoIcon(
            glyph,
            size: 22,
            color: enabled ? AppColors.textSecondary : AppColors.textTertiary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila y no Wrap: el título llena el renglón, y en un Wrap (o
                // dentro del texto) la insignia bajaba sola y quedaba entre
                // título y detalle. Así el título se parte en renglones y la
                // insignia sigue al lado de la primera línea.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(child: Text(title, style: text.titleSmall)),
                    if (badge case final label?) ...[
                      const SizedBox(width: AppSpacing.xs),
                      StatusBadge(
                        label: label,
                        color: AppColors.vinylViolet,
                        foreground: AppColors.ink,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(detail, style: text.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Switch(key: switchKey, value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
