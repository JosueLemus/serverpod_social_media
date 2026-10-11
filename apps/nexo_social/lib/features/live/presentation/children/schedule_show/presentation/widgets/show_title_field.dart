import 'package:flutter/material.dart';

import '../../../../../../../app/theme/app_tokens.dart';
import '../bloc/schedule_show_cubit.dart';
import 'show_section.dart';

class ShowTitleField extends StatelessWidget {
  const ShowTitleField({
    super.key,
    required this.controller,
    required this.length,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int length;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final over = length > ShowDraft.maxTitleLength;
    return ShowSection(
      title: 'Título del Show',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // El campo del tema: pastilla `linerHigh`, filete lila en foco.
          TextField(
            key: const Key('schedule-title-field'),
            controller: controller,
            onChanged: onChanged,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Ej. Masterclass: Arquitectura de Estado',
            ),
            style: text.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Sé directo y específico para mayor conversión.',
                    style: text.bodySmall,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '$length/${ShowDraft.maxTitleLength}',
                  style: text.labelSmall?.copyWith(
                    color: over ? AppColors.error : AppColors.textSecondary,
                    fontWeight: over ? FontWeight.w900 : FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
