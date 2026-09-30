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
      icon: Icons.subtitles_outlined,
      title: 'Título del Show',
      child: ShowCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ShowFieldLabel('Nombre de la transmisión *'),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              key: const Key('schedule-title-field'),
              controller: controller,
              onChanged: onChanged,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ej. Masterclass: Arquitectura de Estado',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: text.titleLarge?.copyWith(fontSize: 17),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sé directo y específico para mayor conversión.',
                    style: text.bodySmall?.copyWith(fontSize: 11.5),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: over ? AppColors.error : AppColors.background,
                    borderRadius: AppRadii.pill,
                  ),
                  child: Text(
                    '$length/${ShowDraft.maxTitleLength}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: over ? Colors.white : AppColors.textSecondary,
                    ),
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
