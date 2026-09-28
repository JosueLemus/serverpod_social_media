import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/pills.dart';
import '../../../moderation/domain/entities/moderation_action.dart';

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
  Widget build(BuildContext context) => SafeArea(
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
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(widget.detail, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Text('Motivo', style: Theme.of(context).textTheme.titleMedium),
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
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('reason-confirm'),
              onPressed: _reason == null
                  ? null
                  : () => Navigator.pop(context, _reason),
              style: widget.destructive
                  ? FilledButton.styleFrom(backgroundColor: AppColors.error)
                  : null,
              child: Text(widget.confirmLabel),
            ),
          ),
        ],
      ),
    ),
  );
}
