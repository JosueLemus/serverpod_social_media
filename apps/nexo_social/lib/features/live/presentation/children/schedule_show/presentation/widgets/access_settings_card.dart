import 'package:flutter/material.dart';

import '../../../../../../../app/theme/app_tokens.dart';
import '../../../../../../../core/animations/app_motion.dart';
import '../../../../../../../core/widgets/nexo_icon.dart';
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

  /// Donde arranca el texto de la fila: el divisor empieza ahí, como en una
  /// lista agrupada.
  static const _dividerIndent = AppSpacing.md + 22 + AppSpacing.sm;

  @override
  Widget build(BuildContext context) => ShowSection(
    title: 'Acceso y Configuración',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AccessToggle(access: access, onChanged: onAccess),
        const SizedBox(height: AppSpacing.sm),
        // Una lista de ajustes se ve como tal: un grupo sin filete, filas
        // separadas por un divisor con sangría.
        ShowPanel(
          child: Column(
            children: [
              _SettingRow(
                switchKey: const Key('schedule-questions'),
                glyph: NexoGlyph.comment,
                title: 'Preguntas anticipadas',
                detail:
                    'Permite que tu comunidad deje preguntas antes del vivo.',
                value: allowQuestions,
                onChanged: onAllowQuestions,
              ),
              const Divider(height: 1, indent: _dividerIndent),
              _SettingRow(
                switchKey: const Key('schedule-replay'),
                glyph: NexoGlyph.play,
                title: 'Grabar repetición (Replay VOD)',
                detail: 'Publicar la grabación automáticamente al finalizar.',
                value: recordReplay,
                onChanged: onRecordReplay,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Quién puede entrar, como dos chips: elegir uno lo despega (blanco con
/// tinta), igual que cualquier selección de la app.
class _AccessToggle extends StatelessWidget {
  const _AccessToggle({required this.access, required this.onChanged});

  final ShowAccess access;
  final ValueChanged<ShowAccess> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (index, option) in ShowAccess.values.indexed) ...[
        if (index > 0) const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _AccessOption(
            option: option,
            selected: option == access,
            onTap: () => onChanged(option),
          ),
        ),
      ],
    ],
  );
}

class _AccessOption extends StatelessWidget {
  const _AccessOption({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ShowAccess option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.ink : AppColors.textSecondary;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('schedule-access-${option.name}'),
          onTap: onTap,
          borderRadius: AppRadii.pill,
          child: AnimatedContainer(
            duration: AppMotion.feedbackDuration,
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(
              minHeight: AppSizes.buttonHeightDense,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 6,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.sticker : AppColors.linerHigh,
              borderRadius: AppRadii.pill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NexoIcon(
                  option == ShowAccess.public
                      ? NexoGlyph.community
                      : NexoGlyph.crown,
                  filled: selected,
                  size: 18,
                  color: foreground,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Flexible(
                  child: Text(
                    option.label,
                    textAlign: TextAlign.center,
                    // Al partirse en dos renglones, el texto mide su renglón
                    // más largo y no todo el ancho: así el glifo queda
                    // pegado a la palabra y no contra el borde.
                    textWidthBasis: TextWidthBasis.longestLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.switchKey,
    required this.glyph,
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final Key switchKey;
  final NexoGlyph glyph;
  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          NexoIcon(glyph, size: 22, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleSmall),
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
