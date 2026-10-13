import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../animations/app_motion.dart';
import 'nexo_icon.dart';
import 'nexo_mascot.dart';
import 'pills.dart';
import 'sticker.dart';

enum CreateOption {
  post(
    title: 'Publicación',
    detail: 'Ideas, encuestas interactivas y fotos para tu comunidad',
    mascot: NexoMascot.peek,
    edge: StickerEdge.kissCut,
  ),
  goLive(
    title: 'Transmitir en Vivo',
    detail: 'Inicia stream al instante con tu audiencia',
    mascot: NexoMascot.mic,
    edge: StickerEdge.holo,
  ),
  scheduleShow(
    title: 'Programar Show',
    detail: 'Agenda con fecha, invitados y recordatorios',
    mascot: NexoMascot.calendar,
    edge: StickerEdge.dashed,
  );

  const CreateOption({
    required this.title,
    required this.detail,
    required this.mascot,
    required this.edge,
  });

  final String title;
  final String detail;
  final NexoMascot mascot;

  /// Las tres opciones enseñan el vocabulario de bordes de la app: lo que se
  /// publica ya está despegado, lo que sale al aire lleva holo, lo programado
  /// sigue punteado en la plancha.
  final StickerEdge edge;
}

Future<CreateOption?> showCreateSheet(BuildContext context) =>
    showModalBottomSheet<CreateOption>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => const CreateSheetWidget(),
    );

class CreateSheetWidget extends StatelessWidget {
  const CreateSheetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¿Qué deseas crear?', style: text.headlineSmall),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Elige el formato para conectar con tu comunidad',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton.filledTonal(
                  key: const Key('create-sheet-close'),
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.linerHigh,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  icon: const NexoIcon(NexoGlyph.close, size: 18),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final (index, option) in CreateOption.values.indexed) ...[
              // Las tarjetas se tocan, así que sólo aparecen: una traslación
              // dejaría el hit test corrido mientras dura.
              EnterStatic(
                index: index,
                child: _CreateOptionTile(
                  option: option,
                  onTap: () => Navigator.pop(context, option),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreateOptionTile extends StatelessWidget {
  const _CreateOptionTile({required this.option, required this.onTap});

  final CreateOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tile = Material(
      color: AppColors.linerHigh,
      borderRadius: AppRadii.large,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('create-option-${option.name}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              MascotIllustration(option.mascot, size: 64),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wrap y no Row: a 320 "Transmitir en Vivo" más su
                    // insignia no entran, y una fila recortaría la insignia.
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(option.title, style: text.titleMedium),
                        ?_badgeFor(option),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      option.detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              NexoIcon(
                NexoGlyph.forward,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
    return StickerFrame(
      edge: option.edge,
      radius: 26,
      edgeWidth: option.edge == StickerEdge.kissCut ? 0 : AppStroke.kissCut,
      child: tile,
    );
  }

  static Widget? _badgeFor(CreateOption option) => switch (option) {
    CreateOption.post => null,
    CreateOption.goLive => const StatusBadge(label: 'Directo', pulse: true),
    CreateOption.scheduleShow => StatusBadge(
      label: 'Nuevo',
      color: AppColors.vinylLime,
      foreground: AppColors.ink,
    ),
  };
}
