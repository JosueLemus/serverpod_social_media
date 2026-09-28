import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/moderation_action.dart';

/// La copy de una decisión. Nombra la consecuencia, no la acción:
/// "Silenciado" no dice por cuánto, y por cuánto es justamente lo que se
/// acaba de elegir.
extension ModerationDecisionCopy on ModerationDecision {
  String get confirmation => switch (type) {
    ModerationType.hideComment => 'Comentario oculto para toda la audiencia',
    ModerationType.muteUser => 'Usuario silenciado por ${muteFor?.label ?? ''}',
    ModerationType.banUser => 'Usuario bloqueado del canal',
    ModerationType.report => 'Reporte enviado a Trust & Safety',
    ModerationType.dismissReport => 'Reporte descartado',
  };
}

/// Acciones tácticas sobre un participante, desde el chat de un directo.
///
/// Se abre con pulsación larga sobre un comentario. No hay un ícono de moderar
/// por fila: con seis acciones disponibles, un control por mensaje convierte
/// el chat en una consola y le quita la pantalla al directo.
Future<ModerationDecision?> showModerationSheet(
  BuildContext context, {
  required String author,
  int reports = 0,
  String? comment,
  bool canModerate = true,
}) => showModalBottomSheet<ModerationDecision>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheetContext) => _ModerationSheet(
    author: author,
    reports: reports,
    comment: comment,
    canModerate: canModerate,
  ),
);

class _ModerationSheet extends StatefulWidget {
  const _ModerationSheet({
    required this.author,
    required this.reports,
    required this.comment,
    required this.canModerate,
  });

  final String author;
  final int reports;
  final String? comment;

  /// Sin permiso de moderación la hoja sólo ofrece reportar. El servidor
  /// rechazaría lo demás igual; mostrarlo sería ofrecer algo que falla.
  final bool canModerate;

  @override
  State<_ModerationSheet> createState() => _ModerationSheetState();
}

class _ModerationSheetState extends State<_ModerationSheet> {
  MuteDuration _mute = MuteDuration.oneDay;

  void _decide(ModerationType type) => Navigator.pop(
    context,
    ModerationDecision(
      type: type,
      muteFor: type == ModerationType.muteUser ? _mute : null,
    ),
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
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
            children: [
              UserAvatar(name: widget.author, size: 40),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.canModerate
                          ? 'Moderar participante'
                          : 'Reportar comentario',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 17),
                    ),
                    Text(
                      'Acciones sobre @${widget.author} en esta sesión',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (widget.reports > 0)
                StatusBadge(label: '${widget.reports} reportes'),
            ],
          ),
          if (widget.comment != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppRadii.small,
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '"${widget.comment}"',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (widget.canModerate) ...[
            _ActionRow(
              actionKey: const Key('moderate-hide'),
              icon: Icons.visibility_off_outlined,
              title: 'Ocultar comentario',
              detail: 'Invisible para toda la audiencia',
              trailing: const Text(
                'Solo este mensaje',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
              onTap: () => _decide(ModerationType.hideComment),
            ),
            const Divider(height: AppSpacing.lg),
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 19,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Silenciar usuario (timeout)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                for (final option in MuteDuration.values) ...[
                  Expanded(
                    child: FilterPill(
                      key: Key('mute-${option.name}'),
                      label: option.label,
                      selected: _mute == option,
                      // Elegir la duración no silencia: sólo arma la decisión.
                      // Aplicar en el tap del chip dejaría al moderador sin
                      // forma de corregirse antes de confirmar.
                      onTap: () => setState(() => _mute = option),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                SizedBox(
                  height: AppSizes.chipHeight,
                  child: FilledButton(
                    key: const Key('moderate-mute'),
                    onPressed: () => _decide(ModerationType.muteUser),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, AppSizes.chipHeight),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                    ),
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
          ],
          _ActionRow(
            actionKey: const Key('moderate-report'),
            icon: Icons.flag_outlined,
            title: 'Reportar a moderación central',
            detail: 'Revisión exhaustiva por Trust & Safety',
            trailing: const Icon(Icons.chevron_right_rounded, size: 19),
            onTap: () => _decide(ModerationType.report),
          ),
          if (widget.canModerate) ...[
            const SizedBox(height: AppSpacing.xs),
            _ActionRow(
              actionKey: const Key('moderate-ban'),
              icon: Icons.block_rounded,
              iconColor: AppColors.error,
              title: 'Bloquear usuario del canal',
              detail: 'No podrá volver a ingresar ni comentar',
              // La única acción destructiva va en rojo y al final. Es la que no
              // se deshace desde acá.
              titleColor: AppColors.error,
              trailing: const Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: AppColors.error,
              ),
              onTap: () => _decide(ModerationType.banUser),
            ),
          ],
        ],
      ),
    ),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.actionKey,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    this.trailing,
    this.iconColor = AppColors.textPrimary,
    this.titleColor = AppColors.textPrimary,
  });

  final Key actionKey;
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color iconColor;
  final Color titleColor;

  @override
  Widget build(BuildContext context) => InkWell(
    key: actionKey,
    onTap: onTap,
    borderRadius: AppRadii.medium,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 19, color: iconColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: titleColor),
                ),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.xs),
            trailing!,
          ],
        ],
      ),
    ),
  );
}
