import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../../../../../app/theme/app_tokens.dart';
import '../../../../../../../core/widgets/pills.dart';
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
      icon: Icons.person_add_alt_outlined,
      title: 'Invitados y Co-hosts',
      trailing: ShowHintPill(
        label: '${guests.length} de ${ShowDraft.maxGuests} cupos',
      ),
      child: ShowCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final guest in guests) ...[
              _GuestTile(guest: guest, onRemove: () => onRemove(guest.id)),
              const SizedBox(height: AppSpacing.sm),
            ],
            _AddGuestButton(full: full, onTap: full ? null : onAdd),
          ],
        ),
      ),
    );
  }
}

class _GuestTile extends StatelessWidget {
  const _GuestTile({required this.guest, required this.onRemove});

  final ShowGuest guest;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      key: Key('schedule-guest-${guest.id}'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xxs,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: AppRadii.large,
      ),
      child: Row(
        children: [
          UserAvatar(name: guest.name, size: 40),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      guest.name,
                      style: text.titleMedium?.copyWith(fontSize: 14),
                    ),
                    // TODO(backend): mostrar "Confirmado" cuando exista el
                    // flujo para que el invitado acepte.
                    const StatusBadge(
                      label: 'Invitado',
                      color: AppColors.successSurface,
                      foreground: AppColors.tertiary,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '@${guest.username} · Co-host',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            key: Key('schedule-guest-remove-${guest.id}'),
            tooltip: 'Quitar a ${guest.name}',
            onPressed: onRemove,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddGuestButton extends StatelessWidget {
  const _AddGuestButton({required this.full, required this.onTap});

  final bool full;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = full ? AppColors.textSecondary : AppColors.primaryDeep;
    return CustomPaint(
      painter: _DashedPillPainter(
        color: full ? AppColors.border : AppColors.primary,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadii.pill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('schedule-add-guest'),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.buttonHeightDense,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 18, color: color),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      full
                          ? 'Cupos completos'
                          : 'Añadir invitado o co-host por @usuario',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedPillPainter extends CustomPainter {
  const _DashedPillPainter({required this.color});

  final Color color;

  static const _dash = 5.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect.deflate(.75),
          Radius.circular(size.height / 2),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final PathMetric metric in path.computeMetrics()) {
      for (
        var distance = 0.0;
        distance < metric.length;
        distance += _dash + _gap
      ) {
        canvas.drawPath(metric.extractPath(distance, distance + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPillPainter oldDelegate) =>
      oldDelegate.color != color;
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
                prefixIcon: Icon(Icons.alternate_email_rounded, size: 18),
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
