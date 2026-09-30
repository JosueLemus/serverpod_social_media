import 'package:flutter/material.dart';

import '../../../../../../../app/theme/app_tokens.dart';
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in custom)
              ListTile(
                key: Key('schedule-duration-custom-$option'),
                leading: Icon(
                  option == minutes
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: option == minutes
                      ? AppColors.primaryDeep
                      : AppColors.textSecondary,
                ),
                title: Text(ShowDateFormat.duration(option)),
                onTap: () => Navigator.pop(sheetContext, option),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = !presets.contains(minutes);
    return ShowSection(
      icon: Icons.timer_outlined,
      title: 'Duración Estimada',
      trailing: Text(
        '${ShowDateFormat.duration(ShowDraft.recommendedMinutes)} '
        'recomendada',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primaryDeep,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: [
            for (final preset in presets) ...[
              FilterPill(
                key: Key('schedule-duration-$preset'),
                label: preset == minutes ? '✓  $preset min' : '$preset min',
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
    );
  }
}
