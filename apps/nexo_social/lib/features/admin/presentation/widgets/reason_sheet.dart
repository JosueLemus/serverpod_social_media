import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/pills.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../utils/admin_ui.dart';

/// Pide el motivo de una sanción y la confirma.
///
/// Elegir el motivo **no** aplica nada: arma la decisión, y el botón la
/// confirma. Aplicar en el tap del chip deja al operador sin forma de
/// corregirse, y una suspensión aplicada por error ya cerró la sesión de
/// alguien.
Future<ModerationReason?> showReasonSheet(
  BuildContext context, {
  required String title,
  required String detail,
  required String confirmLabel,
  bool destructive = true,
}) => showModalBottomSheet<ModerationReason>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  backgroundColor: AppColors.surface,
  builder: (_) => _ReasonSheet(
    title: title,
    detail: detail,
    confirmLabel: confirmLabel,
    destructive: destructive,
  ),
);

class _ReasonSheet extends StatefulWidget {
  const _ReasonSheet({
    required this.title,
    required this.detail,
    required this.confirmLabel,
    required this.destructive,
  });

  final String title;
  final String detail;
  final String confirmLabel;
  final bool destructive;

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  ModerationReason? _reason;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Una sanción lleva el escudo de moderación en rojo; un reporte de
    // usuario, la bandera en gris. Es lo primero que dice la hoja sobre el
    // peso de lo que se está por confirmar.
    final glyph = widget.destructive ? NexoGlyph.moderation : NexoGlyph.flag;
    final tone = widget.destructive ? AppColors.error : AppColors.textSecondary;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.linerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: NexoIcon(glyph, size: 20, color: tone),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: text.headlineSmall),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(widget.detail, style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Motivo', style: text.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final reason in ModerationReason.values)
                  FilterPill(
                    key: Key('reason-${reason.name}'),
                    label: reason.label,
                    selected: _reason == reason,
                    onTap: () => setState(() => _reason = reason),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Destructivo: relleno rojo con blanco, nunca el sticker blanco.
            // Un reporte de usuario no saca a nadie: ahí sí va el sticker.
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('reason-confirm'),
                onPressed: _reason == null
                    ? null
                    : () => Navigator.pop(context, _reason),
                style: widget.destructive
                    ? AdminButtons.destructiveFill.copyWith(
                        minimumSize: const WidgetStatePropertyAll(
                          Size(0, AppSizes.buttonHeight),
                        ),
                      )
                    : null,
                child: Text(widget.confirmLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
