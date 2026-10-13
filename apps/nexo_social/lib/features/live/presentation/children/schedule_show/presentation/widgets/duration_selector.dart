import 'package:flutter/material.dart';

import '../../../../../../../app/theme/app_tokens.dart';
import '../../../../../../../core/animations/app_motion.dart';
import '../../../../../../../core/widgets/pills.dart';
import '../bloc/schedule_show_cubit.dart';
import '../utils/show_date_format.dart';
import 'show_section.dart';

class DurationSelector extends StatelessWidget {
  const DurationSelector({
    super.key,
    required this.minutes,
    required this.onChanged,
  });

  final int minutes;
  final ValueChanged<int> onChanged;

  static const presets = [30, 45, 60, 90];

  static const custom = [15, 20, 120, 150, 180, 240];

  Future<void> _pickCustom(BuildContext context) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
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
              Text(
                'Otra duración',
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              // Los mismos chips que la fila: elegir es despegar uno.
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final option in custom)
                    FilterPill(
                      key: Key('schedule-duration-custom-$option'),
                      label: ShowDateFormat.duration(option),
                      selected: option == minutes,
                      onTap: () => Navigator.pop(sheetContext, option),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = !presets.contains(minutes);
    return ShowSection(
      title: 'Duración Estimada',
      trailing: Text(
        '${ShowDateFormat.duration(ShowDraft.recommendedMinutes)} '
        'recomendada',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                for (final preset in presets) ...[
                  FilterPill(
                    key: Key('schedule-duration-$preset'),
                    label: '$preset min',
                    selected: preset == minutes,
                    onTap: () => onChanged(preset),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                FilterPill(
                  key: const Key('schedule-duration-custom'),
                  label: isCustom
                      ? ShowDateFormat.duration(minutes)
                      : 'Personalizar',
                  selected: isCustom,
                  onTap: () => _pickCustom(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _DurationScale(minutes: minutes),
        ],
      ),
    );
  }
}

/// La duración dibujada a escala: una barra cuyo largo es la duración sobre
/// el máximo que acepta el servidor, con una marca por hora.
///
/// "45 min" y "90 min" son dos chips del mismo tamaño; en la barra se ve que
/// uno es el doble del otro, que es lo que se está decidiendo.
class _DurationScale extends StatelessWidget {
  const _DurationScale({required this.minutes});

  final int minutes;

  static const _max = ScheduleShowCubit.maxDurationMinutes;
  static const _hours = _max ~/ 60;
  static const _trackHeight = 10.0;

  @override
  Widget build(BuildContext context) {
    final fraction = (minutes / _max).clamp(0.0, 1.0);
    final label = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppColors.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Semantics(
      label: 'Duración: ${ShowDateFormat.duration(minutes)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _trackHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.linerHigh,
                    borderRadius: AppRadii.pill,
                  ),
                ),
                AnimatedFractionallySizedBox(
                  duration: AppMotion.feedbackDuration,
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppRadii.pill,
                    ),
                  ),
                ),
                // Las marcas de hora van encima del relleno, para que la
                // escala se lea también dentro de la barra.
                Row(
                  children: [
                    for (var hour = 1; hour <= _hours; hour++)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: hour == _hours
                              ? const SizedBox.shrink()
                              : Container(
                                  width: 2,
                                  height: _trackHeight,
                                  color: AppColors.background,
                                ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              for (var hour = 1; hour <= _hours; hour++)
                Expanded(
                  child: Text(
                    '$hour h',
                    textAlign: TextAlign.right,
                    style: label,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
