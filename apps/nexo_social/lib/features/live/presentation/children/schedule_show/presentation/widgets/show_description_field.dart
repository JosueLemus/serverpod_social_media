import 'package:flutter/material.dart';

import '../../../../../../../app/theme/app_tokens.dart';
import 'show_section.dart';

class ShowDescriptionField extends StatelessWidget {
  const ShowDescriptionField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  void _wrap(String marker) {
    final value = controller.value;
    final selection = _validSelection(value);
    final selected = selection.textInside(value.text);
    final text = value.text.replaceRange(
      selection.start,
      selection.end,
      '$marker$selected$marker',
    );
    final cursor = selected.isEmpty
        ? selection.start + marker.length
        : selection.start + marker.length * 2 + selected.length;
    _apply(text, cursor);
  }

  void _bullet() {
    final value = controller.value;
    final selection = _validSelection(value);
    final lineStart = selection.start == 0
        ? 0
        : value.text.lastIndexOf('\n', selection.start - 1) + 1;
    if (value.text.startsWith('- ', lineStart)) return;
    final text = value.text.replaceRange(lineStart, lineStart, '- ');
    _apply(text, selection.end + 2);
  }

  TextSelection _validSelection(TextEditingValue value) =>
      value.selection.isValid
      ? value.selection
      : TextSelection.collapsed(offset: value.text.length);

  void _apply(String text, int cursor) {
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor),
    );
    onChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ShowSection(
      icon: Icons.notes_rounded,
      title: 'Descripción y Temario',
      trailing: const ShowHintPill(
        label: 'Soporta Markdown',
        icon: Icons.code_rounded,
        tinted: true,
      ),
      child: ShowCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('schedule-description-field'),
              controller: controller,
              onChanged: onChanged,
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                    '¿Qué va a aprender tu audiencia? Cuenta el temario y '
                    'cómo van a poder participar.',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: text.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _FormatButton(
                        key: const Key('schedule-format-bold'),
                        icon: Icons.format_bold_rounded,
                        label: 'Negrita',
                        onTap: () => _wrap('**'),
                      ),
                      _FormatButton(
                        key: const Key('schedule-format-code'),
                        icon: Icons.code_rounded,
                        label: 'Código',
                        onTap: () => _wrap('`'),
                      ),
                      _FormatButton(
                        key: const Key('schedule-format-list'),
                        icon: Icons.format_list_bulleted_rounded,
                        label: 'Lista',
                        onTap: _bullet,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Opcional',
                  style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  const _FormatButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.background,
    borderRadius: AppRadii.pill,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.textPrimary),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
