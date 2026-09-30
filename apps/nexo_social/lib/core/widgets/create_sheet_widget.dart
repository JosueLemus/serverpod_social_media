import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../animations/app_motion.dart';
import 'pills.dart';

enum CreateOption {
  post(
    title: 'Publicación',
    detail: 'Ideas, encuestas interactivas y fotos para tu comunidad',
  ),
  goLive(
    title: 'Transmitir en Vivo',
    detail: 'Inicia stream al instante con tu audiencia',
  ),
  scheduleShow(
    title: 'Programar Show',
    detail: 'Agenda con fecha, invitados y recordatorios',
  );

  const CreateOption({required this.title, required this.detail});

  final String title;
  final String detail;
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
                    backgroundColor: AppColors.background,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 20),
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
            const _ScheduleTip(),
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

  /// Programar es la opción que el diseño destaca: superficie blanca con
  /// borde de acento, en vez del relleno tenue de las otras dos.
  bool get _featured => option == CreateOption.scheduleShow;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: _featured ? AppColors.surface : AppColors.primarySurface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.large,
        side: BorderSide(
          color: _featured ? AppColors.primary : AppColors.primarySurfaceDeep,
          width: _featured ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('create-option-${option.name}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _OptionIcon(option: option),
              const SizedBox(width: AppSpacing.md),
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
                        Text(
                          option.title,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        ?_badgeFor(option),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      option.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right_rounded,
                color: _featured
                    ? AppColors.primaryDeep
                    : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget? _badgeFor(CreateOption option) => switch (option) {
    CreateOption.post => null,
    CreateOption.goLive => const StatusBadge(label: 'Directo'),
    CreateOption.scheduleShow => const StatusBadge(
      label: 'Nuevo',
      color: AppColors.primaryDeep,
    ),
  };
}

class _OptionIcon extends StatelessWidget {
  const _OptionIcon({required this.option});

  final CreateOption option;

  static const _size = 48.0;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (option) {
      CreateOption.post => (
        AppColors.primarySurfaceDeep,
        AppColors.primaryDeep,
        Icons.edit_note_rounded,
      ),
      CreateOption.goLive => (
        AppColors.successSurface,
        AppColors.tertiary,
        Icons.sensors_rounded,
      ),
      CreateOption.scheduleShow => (
        AppColors.primaryDeep,
        Colors.white,
        Icons.edit_calendar_rounded,
      ),
    };
    final circle = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: foreground, size: 24),
    );
    if (option != CreateOption.goLive) return circle;

    // El punto verde dice "disponible ahora". Late aislado en su capa.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        circle,
        Positioned(
          top: 0,
          right: 0,
          child: PulsingDot(
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.tertiary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleTip extends StatelessWidget {
  const _ScheduleTip();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: AppRadii.small,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 18,
            color: AppColors.primaryDeep,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text.rich(
              TextSpan(
                text:
                    'Los shows programados incrementan la asistencia '
                    'hasta un ',
                children: [
                  TextSpan(
                    text: '45%',
                    style: style?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
