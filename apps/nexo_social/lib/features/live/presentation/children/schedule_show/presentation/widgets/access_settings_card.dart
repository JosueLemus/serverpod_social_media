import 'package:flutter/material.dart';

import '../../../../../../../app/theme/app_tokens.dart';
import '../../../../../../../core/animations/app_motion.dart';
import '../bloc/schedule_show_cubit.dart';
import '../utils/schedule_show_copy.dart';
import 'show_section.dart';

class AccessSettingsCard extends StatelessWidget {
  const AccessSettingsCard({
    super.key,
    required this.access,
    required this.allowQuestions,
    required this.recordReplay,
    required this.onAccess,
    required this.onAllowQuestions,
    required this.onRecordReplay,
  });

  final ShowAccess access;
  final bool allowQuestions;
  final bool recordReplay;
  final ValueChanged<ShowAccess> onAccess;
  final ValueChanged<bool> onAllowQuestions;
  final ValueChanged<bool> onRecordReplay;

  @override
  Widget build(BuildContext context) => ShowCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShowSection(
          icon: Icons.lock_outline_rounded,
          title: 'Acceso y Configuración',
          child: _AccessToggle(access: access, onChanged: onAccess),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SettingRow(
          switchKey: const Key('schedule-questions'),
          title: 'Preguntas anticipadas',
          detail: 'Permite que tu comunidad deje preguntas antes del vivo.',
          value: allowQuestions,
          onChanged: onAllowQuestions,
        ),
        const Divider(),
        _SettingRow(
          switchKey: const Key('schedule-replay'),
          title: 'Grabar repetición (Replay VOD)',
          detail: 'Publicar la grabación automáticamente al finalizar.',
          value: recordReplay,
          onChanged: onRecordReplay,
        ),
      ],
    ),
  );
}

class _AccessToggle extends StatelessWidget {
  const _AccessToggle({required this.access, required this.onChanged});

  final ShowAccess access;
  final ValueChanged<ShowAccess> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.xxs),
    decoration: const BoxDecoration(
      color: AppColors.background,
      borderRadius: AppRadii.pill,
    ),
    child: Row(
      children: [
        for (final option in ShowAccess.values)
          Expanded(
            child: Semantics(
              selected: option == access,
              button: true,
              child: InkWell(
                key: Key('schedule-access-${option.name}'),
                onTap: () => onChanged(option),
                borderRadius: AppRadii.pill,
                child: AnimatedContainer(
                  duration: AppMotion.feedbackDuration,
                  constraints: const BoxConstraints(
                    minHeight: AppSizes.chipHeight,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 6,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: option == access
                        ? AppColors.surface
                        : Colors.transparent,
                    borderRadius: AppRadii.pill,
                    boxShadow: option == access
                        ? const [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        option == ShowAccess.public
                            ? Icons.public_rounded
                            : Icons.star_border_rounded,
                        size: 16,
                        color: option == access
                            ? AppColors.primaryDeep
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Flexible(
                        child: Text(
                          option.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: option == access
                                ? AppColors.primaryDeep
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.switchKey,
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final Key switchKey;
  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium?.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(detail, style: text.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch(key: switchKey, value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
