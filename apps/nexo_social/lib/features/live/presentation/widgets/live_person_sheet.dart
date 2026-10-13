import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/live_comment.dart';
import '../../domain/entities/live_moderation.dart';
import '../../domain/entities/live_permissions.dart';
import '../../domain/entities/live_session.dart';
import '../utils/live_role_ui.dart';

/// Lo que la hoja de una persona devuelve. La hoja **no aplica nada**: arma la
/// decisión, el cubit la aplica — como en la hoja del chat
/// (`moderation_sheet.dart`), para que la misma hoja sirva en el directo y en
/// la consola sin saber nada de ninguna de las dos.
sealed class LivePersonDecision {
  const LivePersonDecision();
}

class InviteToStageDecision extends LivePersonDecision {
  const InviteToStageDecision();
}

class ApproveHandDecision extends LivePersonDecision {
  const ApproveHandDecision();
}

class DenyHandDecision extends LivePersonDecision {
  const DenyHandDecision();
}

class RemoveFromStageDecision extends LivePersonDecision {
  const RemoveFromStageDecision();
}

class MuteMicDecision extends LivePersonDecision {
  const MuteMicDecision();
}

class MuteChatDecision extends LivePersonDecision {
  const MuteChatDecision(this.duration);

  final LiveMuteDuration duration;
}

class KickDecision extends LivePersonDecision {
  const KickDecision();
}

class BanDecision extends LivePersonDecision {
  const BanDecision();
}

class AssignModeratorDecision extends LivePersonDecision {
  const AssignModeratorDecision({required this.assign});

  /// `true`: nombrar; `false`: quitar.
  final bool assign;
}

class HideCommentDecision extends LivePersonDecision {
  const HideCommentDecision(this.comment);

  final LiveComment comment;
}

class UnhideCommentDecision extends LivePersonDecision {
  const UnhideCommentDecision(this.comment);

  final LiveComment comment;
}

class DeleteCommentDecision extends LivePersonDecision {
  const DeleteCommentDecision(this.comment);

  final LiveComment comment;
}

class PinCommentDecision extends LivePersonDecision {
  const PinCommentDecision(this.comment);

  final LiveComment comment;
}

class UnpinCommentDecision extends LivePersonDecision {
  const UnpinCommentDecision();
}

class HighlightCommentDecision extends LivePersonDecision {
  const HighlightCommentDecision(this.comment);

  final LiveComment comment;
}

class UnhighlightCommentDecision extends LivePersonDecision {
  const UnhighlightCommentDecision();
}

/// La persona sobre la que se abre la hoja — su nombre y qué está haciendo en
/// la sala. [onStage] y [handRaised] son dos lados del mismo eje: si está
/// arriba, hay cosas que ofrecer (silenciar el micrófono, bajarlo); si pidió
/// la palabra, aparece "Aprobar" / "Rechazar".
class LivePerson {
  const LivePerson({
    required this.userId,
    required this.name,
    required this.role,
    this.username = '',
    this.avatarUrl,
    this.onStage = false,
    this.handRaised = false,
    this.micMuted = false,
    this.isModerator = false,
  });

  final String userId;
  final String name;
  final String username;
  final String? avatarUrl;
  final LiveRole role;
  final bool onStage;
  final bool handRaised;
  final bool micMuted;

  /// La persona ya está nombrada como moderadora del vivo. "Nombrar
  /// moderador" se convierte en "Quitar moderador".
  final bool isModerator;
}

/// Abre la hoja de acciones sobre [person], filtradas por
/// [LivePermissions.on] para quien mira ([actorRole]).
///
/// [comment] es el mensaje desde donde se abrió la hoja, si la acción salió
/// del chat: habilita ocultar/borrar/fijar/destacar sobre ese mensaje en
/// particular.
///
/// La hoja **devuelve** una [LivePersonDecision]; el cubit decide qué método
/// invocar. Si devuelve `null`, el usuario cerró sin decidir.
Future<LivePersonDecision?> showLivePersonSheet(
  BuildContext context, {
  required LivePerson person,
  required LiveRole actorRole,
  LiveComment? comment,
  bool pinnedIsThis = false,
  bool highlightedIsThis = false,
}) => showModalBottomSheet<LivePersonDecision>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  backgroundColor: AppColors.surface,
  builder: (_) => _LivePersonSheet(
    person: person,
    actorRole: actorRole,
    comment: comment,
    pinnedIsThis: pinnedIsThis,
    highlightedIsThis: highlightedIsThis,
  ),
);

class _LivePersonSheet extends StatefulWidget {
  const _LivePersonSheet({
    required this.person,
    required this.actorRole,
    required this.comment,
    required this.pinnedIsThis,
    required this.highlightedIsThis,
  });

  final LivePerson person;
  final LiveRole actorRole;
  final LiveComment? comment;
  final bool pinnedIsThis;
  final bool highlightedIsThis;

  @override
  State<_LivePersonSheet> createState() => _LivePersonSheetState();
}

class _LivePersonSheetState extends State<_LivePersonSheet> {
  LiveMuteDuration _mute = LiveMuteDuration.fifteenMinutes;

  void _decide(LivePersonDecision decision) =>
      Navigator.of(context).pop(decision);

  /// Banear es persistente (no entra a **ningún** vivo de este host hasta que
  /// el host lo levante) y por eso se confirma: una pulsación larga sobre un
  /// nombre no puede terminar en una sanción permanente sin un segundo paso.
  Future<void> _confirmBan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('¿Bloquear a @${widget.person.username}?'),
        content: Text(
          'No podrá entrar a ninguno de tus vivos hasta que lo levantes. '
          'Esta sanción no se deshace al terminar el vivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) _decide(const BanDecision());
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final allowed = LivePermissions.on(widget.actorRole, widget.person.role);
    final rows = <Widget>[];

    // --- Acciones sobre la PERSONA en el escenario -------------------------

    if (widget.person.handRaised &&
        allowed.contains(LiveAction.approveRequest)) {
      rows.add(
        _ActionRow(
          key: const Key('person-approve-hand'),
          glyph: NexoGlyph.check,
          discColor: AppColors.sticker,
          glyphColor: AppColors.ink,
          title: 'Aprobar la palabra',
          detail: 'Sube al escenario con micrófono.',
          onTap: () => _decide(const ApproveHandDecision()),
        ),
      );
      rows.add(
        _ActionRow(
          key: const Key('person-deny-hand'),
          glyph: NexoGlyph.close,
          title: 'Rechazar',
          detail: 'La mano se baja; no vuelve al escenario esta vez.',
          onTap: () => _decide(const DenyHandDecision()),
        ),
      );
    }
    if (!widget.person.onStage &&
        !widget.person.handRaised &&
        allowed.contains(LiveAction.inviteToStage)) {
      rows.add(
        _ActionRow(
          key: const Key('person-invite'),
          glyph: NexoGlyph.mic,
          discColor: AppColors.sticker,
          glyphColor: AppColors.ink,
          title: 'Subir al escenario',
          detail: 'Entra con micrófono y puede prender la cámara.',
          onTap: () => _decide(const InviteToStageDecision()),
        ),
      );
    }
    if (widget.person.onStage && allowed.contains(LiveAction.muteMic)) {
      rows.add(
        _ActionRow(
          key: const Key('person-mute-mic'),
          glyph: NexoGlyph.micOff,
          discColor: AppColors.warning,
          glyphColor: AppColors.ink,
          title: widget.person.micMuted
              ? 'Micrófono apagado'
              : 'Silenciar micrófono',
          detail: widget.person.micMuted
              ? 'Puede volver a activarlo cuando quiera.'
              : 'Puede volver a activarlo. Si insiste, bájalo del escenario.',
          onTap: widget.person.micMuted
              ? null
              : () => _decide(const MuteMicDecision()),
        ),
      );
    }
    if (widget.person.onStage &&
        allowed.contains(LiveAction.removeFromStage)) {
      rows.add(
        _ActionRow(
          key: const Key('person-remove-stage'),
          glyph: NexoGlyph.logout,
          title: 'Bajar del escenario',
          detail: 'Queda como oyente; puede volver a pedir la palabra.',
          onTap: () => _decide(const RemoveFromStageDecision()),
        ),
      );
    }

    // --- Acciones sobre el MENSAJE que abrió la hoja ----------------------
    final comment = widget.comment;
    if (comment != null) {
      if (allowed.contains(LiveAction.pinChat) ||
          widget.actorRole == LiveRole.host ||
          widget.actorRole == LiveRole.moderator) {
        if (widget.pinnedIsThis) {
          rows.add(
            _ActionRow(
              key: const Key('person-unpin'),
              glyph: NexoGlyph.bookmark,
              title: 'Despegar mensaje',
              detail: 'Vuelve a ser un comentario más.',
              onTap: () => _decide(const UnpinCommentDecision()),
            ),
          );
        } else {
          rows.add(
            _ActionRow(
              key: const Key('person-pin'),
              glyph: NexoGlyph.bookmark,
              title: 'Fijar mensaje',
              detail: 'Queda arriba del chat para todos los que miran.',
              onTap: () => _decide(PinCommentDecision(comment)),
            ),
          );
        }
      }
      // Destacar una pregunta puede hacerlo también un invitado (SDD 0011 S8).
      final canHighlight = widget.actorRole == LiveRole.host ||
          widget.actorRole == LiveRole.moderator ||
          widget.actorRole == LiveRole.cohost;
      if (canHighlight) {
        if (widget.highlightedIsThis) {
          rows.add(
            _ActionRow(
              key: const Key('person-unhighlight'),
              glyph: NexoGlyph.sparkles,
              title: 'Quitar pregunta destacada',
              detail: 'La pregunta vuelve a ser un comentario más.',
              onTap: () => _decide(const UnhighlightCommentDecision()),
            ),
          );
        } else {
          rows.add(
            _ActionRow(
              key: const Key('person-highlight'),
              glyph: NexoGlyph.sparkles,
              title: 'Destacar pregunta',
              detail: 'Queda arriba del chat; útil para una pregunta en vivo.',
              onTap: () => _decide(HighlightCommentDecision(comment)),
            ),
          );
        }
      }
      if (allowed.contains(LiveAction.hideChat)) {
        rows.add(
          _ActionRow(
            key: const Key('person-hide-comment'),
            glyph: NexoGlyph.hidden,
            title: 'Ocultar mensaje',
            detail: 'Se oculta para la sala; se puede restaurar luego.',
            onTap: () => _decide(HideCommentDecision(comment)),
          ),
        );
      }
      if (allowed.contains(LiveAction.deleteChat)) {
        rows.add(
          _ActionRow(
            key: const Key('person-delete-comment'),
            glyph: NexoGlyph.trash,
            discColor: AppColors.error,
            glyphColor: AppColors.onError,
            title: 'Borrar mensaje',
            detail: 'Fuera del chat y del replay. No se deshace.',
            onTap: () => _decide(DeleteCommentDecision(comment)),
          ),
        );
      }
    }

    // --- Sanciones --------------------------------------------------------

    if (allowed.contains(LiveAction.muteChat)) {
      rows.add(const _Divider());
      rows.add(
        _ChatMuteRow(
          selected: _mute,
          onChanged: (duration) => setState(() => _mute = duration),
          onApply: () => _decide(MuteChatDecision(_mute)),
        ),
      );
    }
    if (allowed.contains(LiveAction.kick)) {
      rows.add(
        _ActionRow(
          key: const Key('person-kick'),
          glyph: NexoGlyph.logout,
          outline: AppColors.warning,
          title: 'Expulsar de este vivo',
          detail: 'Sale y no vuelve a entrar a este vivo.',
          onTap: () => _decide(const KickDecision()),
        ),
      );
    }
    if (allowed.contains(LiveAction.ban)) {
      rows.add(
        _ActionRow(
          key: const Key('person-ban'),
          glyph: NexoGlyph.lock,
          discColor: AppColors.error,
          glyphColor: AppColors.onError,
          outline: AppColors.error,
          title: 'Bloquear de tus vivos',
          detail: 'No entra a ninguno de tus vivos hasta que lo levantes.',
          onTap: () => unawaited(_confirmBan()),
        ),
      );
    }
    if (allowed.contains(LiveAction.assignModerator)) {
      rows.add(const _Divider());
      rows.add(
        _ActionRow(
          key: const Key('person-moderator'),
          glyph: NexoGlyph.moderation,
          title: widget.person.isModerator
              ? 'Quitar como moderador'
              : 'Nombrar moderador',
          detail: widget.person.isModerator
              ? 'Vuelve a su rol anterior en la sala.'
              : 'Puede silenciar, ocultar y expulsar en esta sala.',
          onTap: () =>
              _decide(AssignModeratorDecision(assign: !widget.person.isModerator)),
        ),
      );
    }

    if (rows.isEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'No puedes aplicar acciones sobre esta persona.',
            style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

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
                UserAvatar(
                  name: widget.person.name,
                  imageUrl: widget.person.avatarUrl,
                  size: 44,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.person.name, style: text.titleLarge),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            widget.person.username.isEmpty
                                ? widget.person.role.label
                                : '@${widget.person.username}',
                            style: text.bodySmall,
                          ),
                          StatusBadge(
                            label: widget.person.role.label,
                            color: AppColors.vinylCyan,
                            foreground: AppColors.ink,
                          ),
                          if (widget.person.handRaised)
                            StatusBadge(
                              label: 'Pidió la palabra',
                              color: AppColors.warning,
                              foreground: AppColors.ink,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (comment != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.linerHigh,
                  borderRadius: AppRadii.medium,
                ),
                child: Text(
                  '“${comment.body}”',
                  style: text.bodyMedium,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            for (final row in rows) row,
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: AppSpacing.lg);
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    super.key,
    required this.glyph,
    required this.title,
    required this.detail,
    required this.onTap,
    this.discColor,
    this.glyphColor,
    this.outline,
  });

  final NexoGlyph glyph;
  final String title;
  final String detail;

  /// `null` deja la fila apagada: un control que no responde se lee como una
  /// app rota.
  final VoidCallback? onTap;
  final Color? discColor;
  final Color? glyphColor;
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
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? .5 : 1,
          child: Padding(
            padding: outline == null
                ? const EdgeInsets.symmetric(vertical: AppSpacing.xs)
                : const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                _GlyphDisc(
                  glyph,
                  background: discColor,
                  foreground: glyphColor,
                ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// La fila de silenciar en el chat: cuatro duraciones y un botón "Aplicar".
///
/// Elegir una duración NO silencia (misma regla que la hoja de moderación del
/// chat): arma la decisión; "Aplicar" la confirma. Sin eso, un moderador que
/// toca el chip equivocado no tiene forma de corregirse antes del envío.
class _ChatMuteRow extends StatelessWidget {
  const _ChatMuteRow({
    required this.selected,
    required this.onChanged,
    required this.onApply,
  });

  final LiveMuteDuration selected;
  final ValueChanged<LiveMuteDuration> onChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _GlyphDisc(
                NexoGlyph.micOff,
                background: AppColors.warning,
                foreground: AppColors.ink,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Silenciar en el chat', style: text.titleMedium),
                    Text(
                      'No podrá escribir en el chat durante el tiempo elegido.',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final option in LiveMuteDuration.values)
                FilterPill(
                  key: Key('mute-${option.name}'),
                  label: _label(option),
                  selected: option == selected,
                  onTap: () => onChanged(option),
                ),
              FilledButton(
                key: const Key('person-apply-mute'),
                onPressed: onApply,
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
        ],
      ),
    );
  }

  static String _label(LiveMuteDuration duration) => switch (duration) {
    LiveMuteDuration.fiveMinutes => '5 min',
    LiveMuteDuration.fifteenMinutes => '15 min',
    LiveMuteDuration.oneHour => '1 h',
    LiveMuteDuration.restOfLive => 'Resto del vivo',
  };
}

class _GlyphDisc extends StatelessWidget {
  const _GlyphDisc(this.glyph, {this.background, this.foreground});

  static const _size = 40.0;

  final NexoGlyph glyph;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) => Container(
    width: _size,
    height: _size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: background ?? AppColors.linerHigh,
      shape: BoxShape.circle,
    ),
    child: NexoIcon(
      glyph,
      size: 20,
      color: foreground ?? AppColors.textPrimary,
    ),
  );
}
