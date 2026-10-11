import 'package:flutter/material.dart';

import '../../../../../../../app/theme/app_tokens.dart';
import '../../../../../../../core/widgets/nexo_icon.dart';
import '../utils/show_date_format.dart';
import 'show_section.dart';

class ShowDateTimeRow extends StatelessWidget {
  const ShowDateTimeRow({
    super.key,
    required this.startsAt,
    required this.now,
    required this.onPickDate,
    required this.onPickTime,
  });

  final DateTime startsAt;
  final DateTime now;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final inPast = !startsAt.isAfter(now);
    return ShowSection(
      title: 'Fecha y Hora del Evento',
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _PickerTile(
                key: const Key('schedule-date'),
                label: 'Fecha',
                glyph: NexoGlyph.calendar,
                value: ShowDateFormat.date(startsAt),
                detail: ShowDateFormat.countdown(startsAt, now: now),
                detailColor: inPast ? AppColors.error : AppColors.tertiary,
                onTap: onPickDate,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _PickerTile(
                key: const Key('schedule-time'),
                label: 'Hora',
                glyph: NexoGlyph.clock,
                value:
                    '${ShowDateFormat.time(startsAt)} '
                    '${ShowDateFormat.gmtOffset(startsAt.timeZoneOffset)}',
                detail: 'Hora de tu dispositivo',
                onTap: onPickTime,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un control en reposo: `linerHigh`, sin filete, con el valor grande en la
/// voz de sticker porque es lo que se vino a elegir.
class _PickerTile extends StatelessWidget {
  const _PickerTile({
    super.key,
    required this.label,
    required this.glyph,
    required this.value,
    required this.detail,
    required this.onTap,
    this.detailColor,
  });

  final String label;
  final NexoGlyph glyph;
  final String value;
  final String detail;

  /// Con color, el detalle es un estado (verde a tiempo, rojo ya pasó) y
  /// lleva su punto delante. Sin color es una aclaración.
  final Color? detailColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = detailColor;
    return Material(
      color: AppColors.linerHigh,
      borderRadius: AppRadii.medium,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  NexoIcon(glyph, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: text.titleLarge?.copyWith(
                  fontSize: 16,
                  height: 1.2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  if (color != null) ...[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(
                        color: color ?? AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
