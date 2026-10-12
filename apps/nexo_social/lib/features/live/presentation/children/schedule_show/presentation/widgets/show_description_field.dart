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
      title: 'Descripción y Temario',
      trailing: const ShowHintPill(label: 'Soporta Markdown'),
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
            decoration: showMultilineDecoration(
              hintText:
                  '¿Qué va a aprender tu audiencia? Cuenta el temario y '
                  'cómo van a poder participar.',
            ),
            style: text.bodyMedium?.copyWith(height: 1.5),
          ),
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
                      label: 'Negrita',
                      emphasis: FontWeight.w900,
                      onTap: () => _wrap('**'),
                    ),
                    _FormatButton(
                      key: const Key('schedule-format-code'),
                      label: 'Código',
                      onTap: () => _wrap('`'),
                    ),
                    _FormatButton(
                      key: const Key('schedule-format-list'),
                      label: 'Lista',
                      onTap: _bullet,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Opcional',
                style: text.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Un atajo de formato. Sin ícono: negrita, código y lista no tienen glifo
/// propio, y uno de Material sería otro trazo en medio de los de Nexo. La
/// palabra alcanza.
class _FormatButton extends StatelessWidget {
  const _FormatButton({
    super.key,
    required this.label,
    required this.onTap,
    this.emphasis,
  });

  final String label;
  final VoidCallback onTap;

  /// La propia etiqueta muestra lo que hace: "Negrita" va en negrita.
  final FontWeight? emphasis;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.linerHigh,
    borderRadius: AppRadii.pill,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Container(
        height: AppSizes.chipHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        // Center con widthFactor y no `alignment`: un Container alineado
        // se estira a todo el ancho que le den, y en el Wrap cada atajo
        // ocupaba un renglón entero.
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: emphasis,
            ),
          ),
        ),
      ),
    ),
  );
}
