import 'package:flutter/material.dart';

import '../../../../../../../app/theme/app_tokens.dart';
import '../../../../../../../core/widgets/nexo_icon.dart';
import '../../../../../../../core/widgets/user_avatar.dart';
import '../bloc/schedule_show_cubit.dart';
import 'show_section.dart';

Future<String?> showAddGuestSheet(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _AddGuestSheet(),
    );

class GuestsSection extends StatelessWidget {
  const GuestsSection({
    super.key,
    required this.guests,
    required this.onAdd,
    required this.onRemove,
  });

  final List<ShowGuest> guests;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final full = guests.length >= ShowDraft.maxGuests;
    return ShowSection(
      title: 'Invitados y Co-hosts',
      subtitle: guests.isEmpty
          ? 'Hasta ${ShowDraft.maxGuests} personas pueden subir al '
                'escenario contigo.'
          : null,
      trailing: ShowHintPill(
        label: '${guests.length} de ${ShowDraft.maxGuests} cupos',
      ),
      // Wrap y no Row: tres stickers más el de añadir no entran a 320, y un
      // Row recortaría justo el último.
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.sm,
        children: [
          for (final guest in guests)
            _GuestSticker(guest: guest, onRemove: () => onRemove(guest.id)),
          _AddGuestSlot(full: full, onTap: full ? null : onAdd),
        ],
      ),
    );
  }
}

/// El ancho de cada lugar en el escenario: avatar, nombre y handle.
const _slotWidth = 84.0;

/// El avatar de cada lugar.
const _avatar = 56.0;

/// La caja del avatar. Más alta y ancha que el avatar para que el botón de
/// quitar, pegado en su esquina, tenga 44 de área táctil sin salirse de la
/// caja: lo que asoma fuera de un Stack se ve pero no recibe toques.
const _stage = Size(_slotWidth, 68);

class _GuestSticker extends StatelessWidget {
  const _GuestSticker({required this.guest, required this.onRemove});

  final ShowGuest guest;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      key: Key('schedule-guest-${guest.id}'),
      width: _slotWidth,
      child: Column(
        children: [
          SizedBox.fromSize(
            size: _stage,
            child: Stack(
              children: [
                Positioned(
                  left: (_slotWidth - _avatar) / 2,
                  bottom: 0,
                  child: UserAvatar(name: guest.name, size: _avatar),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    key: Key('schedule-guest-remove-${guest.id}'),
                    tooltip: 'Quitar a ${guest.name}',
                    onPressed: onRemove,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                    icon: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.linerHigh,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: AppColors.background, width: 2),
                        ),
                      ),
                      child: const NexoIcon(
                        NexoGlyph.close,
                        size: 11,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // TODO(backend): mostrar "Confirmado" cuando exista el flujo para
          // que el invitado acepte.
          Text(
            guest.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: text.labelMedium,
          ),
          Text(
            '@${guest.username}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: text.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// El lugar libre: un control en reposo con el "+", del mismo tamaño que un
/// invitado para que la fila se lea como el escenario con sus cupos.
class _AddGuestSlot extends StatelessWidget {
  const _AddGuestSlot({required this.full, required this.onTap});

  final bool full;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = full ? AppColors.textTertiary : AppColors.textPrimary;
    return Semantics(
      button: true,
      enabled: !full,
      label: full ? 'Cupos completos' : 'Añadir invitado o co-host',
      excludeSemantics: true,
      child: InkWell(
        key: const Key('schedule-add-guest'),
        onTap: onTap,
        borderRadius: AppRadii.medium,
        child: SizedBox(
          width: _slotWidth,
          child: Column(
            children: [
              SizedBox.fromSize(
                size: _stage,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: _avatar,
                    height: _avatar,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.linerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: NexoIcon(NexoGlyph.add, size: 22, color: color),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                full ? 'Completo' : 'Añadir',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: text.labelMedium?.copyWith(color: color),
              ),
              Text(
                'por @usuario',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: text.labelSmall?.copyWith(
                  color: full
                      ? AppColors.textTertiary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddGuestSheet extends StatefulWidget {
  const _AddGuestSheet();

  @override
  State<_AddGuestSheet> createState() => _AddGuestSheetState();
}

class _AddGuestSheetState extends State<_AddGuestSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final username = _controller.text.trim();
    if (username.isEmpty || username == '@') return;
    Navigator.pop(context, username);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      child: Padding(
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
            Text(
              'Invitar al escenario',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Hasta ${ShowDraft.maxGuests} personas pueden subir como '
              'co-host durante el show.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('schedule-guest-field'),
              controller: _controller,
              autofocus: true,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                hintText: 'usuario',
                prefixIcon: Center(
                  widthFactor: 1,
                  child: NexoIcon(
                    NexoGlyph.mention,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                prefixIconConstraints: BoxConstraints(minWidth: 44),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              key: const Key('schedule-guest-invite'),
              onPressed: _submit,
              child: const Text('Invitar'),
            ),
          ],
        ),
      ),
    ),
  );
}
