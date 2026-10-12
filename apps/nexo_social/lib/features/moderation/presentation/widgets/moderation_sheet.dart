import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/nexo_icon.dart';
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
  backgroundColor: AppColors.surface,
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
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(name: widget.author, size: 44),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.canModerate
                            ? 'Moderar participante'
                            : 'Reportar comentario',
                        style: text.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Acciones sobre @${widget.author} en esta sesión',
                        style: text.bodySmall,
                      ),
                      // Debajo y no al final de la fila: a 320 la insignia
                      // le quitaba el ancho al título.
                      if (widget.reports > 0) ...[
                        const SizedBox(height: AppSpacing.xs),
                        // Vinilo y no ámbar: cuántas veces lo reportaron es
                        // contexto para decidir, no una advertencia. El ámbar
                        // queda para el silenciamiento, que sí pide cuidado.
                        StatusBadge(
                          label: '${widget.reports} reportes',
                          color: AppColors.vinylMagenta,
                          foreground: AppColors.ink,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (widget.comment != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: const BoxDecoration(
                  color: AppColors.linerHigh,
                  borderRadius: AppRadii.medium,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: NexoIcon(
                        NexoGlyph.comment,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '“${widget.comment}”',
                        style: text.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (widget.canModerate) ...[
              // La acción de todos los días va primero y es la única con el
              // disco blanco: la jerarquía se lee antes que el texto.
              _ActionRow(
                actionKey: const Key('moderate-hide'),
                glyph: NexoGlyph.hidden,
                discColor: AppColors.sticker,
                glyphColor: AppColors.ink,
                title: 'Ocultar comentario',
                // En el detalle y no como texto al final de la fila: ahí le
                // quitaba al título casi todo el ancho a 320.
                detail: 'Solo este mensaje, invisible para toda la audiencia',
                onTap: () => _decide(ModerationType.hideComment),
              ),
              const Divider(height: AppSpacing.lg),
              Row(
                children: [
                  const _GlyphDisc(
                    NexoGlyph.micOff,
                    background: AppColors.warning,
                    foreground: AppColors.ink,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Silenciar usuario (timeout)',
                          style: text.titleMedium,
                        ),
                        Text(
                          'No podrá comentar durante el tiempo elegido',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  // Wrap: a 320 las tres duraciones y "Aplicar" no entran en
                  // un renglón, y repartir el ancho recortaba "24 horas".
                  Expanded(
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final option in MuteDuration.values)
                          FilterPill(
                            key: Key('mute-${option.name}'),
                            label: option.label,
                            selected: _mute == option,
                            // Elegir la duración no silencia: sólo arma la
                            // decisión. Aplicar en el tap del chip dejaría al
                            // moderador sin forma de corregirse antes de
                            // confirmar.
                            onTap: () => setState(() => _mute = option),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  FilledButton(
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
                ],
              ),
              const Divider(height: AppSpacing.lg),
            ],
            _ActionRow(
              actionKey: const Key('moderate-report'),
              glyph: NexoGlyph.flag,
              title: 'Reportar a moderación central',
              detail: 'Revisión exhaustiva por Trust & Safety',
              trailing: const NexoIcon(
                NexoGlyph.forward,
                size: 18,
                color: AppColors.textSecondary,
              ),
              onTap: () => _decide(ModerationType.report),
            ),
            if (widget.canModerate) ...[
              const SizedBox(height: AppSpacing.md),
              // La única acción destructiva va al final, con contorno de error
              // y no como sticker blanco: es la que no se deshace desde acá.
              _ActionRow(
                actionKey: const Key('moderate-ban'),
                glyph: NexoGlyph.lock,
                discColor: AppColors.error,
                glyphColor: AppColors.sticker,
                outline: AppColors.error,
                title: 'Bloquear usuario del canal',
                detail: 'No podrá volver a ingresar ni comentar',
                onTap: () => _decide(ModerationType.banUser),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.actionKey,
    required this.glyph,
    required this.title,
    required this.detail,
    required this.onTap,
    this.trailing,
    this.discColor = AppColors.linerHigh,
    this.glyphColor = AppColors.textPrimary,
    this.outline,
  });

  final Key actionKey;
  final NexoGlyph glyph;
  final String title;
  final String detail;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color discColor;
  final Color glyphColor;

  /// Contorno de la fila. Sólo para la acción destructiva.
  final Color? outline;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.large,
        side: outline == null
            ? BorderSide.none
            : BorderSide(color: outline!, width: 1.5),
      ),
      child: InkWell(
        key: actionKey,
        onTap: onTap,
        child: Padding(
          padding: outline == null
              ? const EdgeInsets.symmetric(vertical: AppSpacing.xs)
              : const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              _GlyphDisc(glyph, background: discColor, foreground: glyphColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleMedium),
                    Text(detail, style: text.bodySmall),
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
      ),
    );
  }
}

class _GlyphDisc extends StatelessWidget {
  const _GlyphDisc(
    this.glyph, {
    this.background = AppColors.linerHigh,
    this.foreground = AppColors.textPrimary,
  });

  static const _size = 40.0;

  final NexoGlyph glyph;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    width: _size,
    height: _size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: background, shape: BoxShape.circle),
    child: NexoIcon(glyph, size: 20, color: foreground),
  );
}
