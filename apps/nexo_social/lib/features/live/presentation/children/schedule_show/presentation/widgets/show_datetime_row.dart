import 'package:flutter/material.dart';

import '../../../../../../../app/theme/app_tokens.dart';
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
      icon: Icons.calendar_month_outlined,
      title: 'Fecha y Hora del Evento',
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _PickerTile(
                key: const Key('schedule-date'),
                label: 'Fecha',
                icon: Icons.edit_calendar_outlined,
                value: ShowDateFormat.date(startsAt),
                detail: ShowDateFormat.countdown(startsAt, now: now),
                detailIcon: inPast
                    ? Icons.error_outline_rounded
                    : Icons.check_rounded,
                detailColor: inPast ? AppColors.error : AppColors.tertiary,
                onTap: onPickDate,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _PickerTile(
                key: const Key('schedule-time'),
                label: 'Hora',
                icon: Icons.schedule_rounded,
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

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.detail,
    required this.onTap,
    this.detailIcon,
    this.detailColor,
  });

  final String label;
  final IconData icon;
  final String value;
  final String detail;
  final IconData? detailIcon;
  final Color? detailColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = detailColor ?? AppColors.textSecondary;
    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.medium,
        side: BorderSide(color: AppColors.border),
      ),
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
                  Expanded(child: ShowFieldLabel(label)),
                  Icon(icon, size: 18, color: AppColors.primaryDeep),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(value, style: text.titleLarge?.copyWith(fontSize: 15.5)),
              const SizedBox(height: AppSpacing.xxs),
              Row(
                children: [
                  if (detailIcon != null) ...[
                    Icon(detailIcon, size: 13, color: color),
                    const SizedBox(width: AppSpacing.xxs),
                  ],
                  Expanded(
                    child: Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        fontSize: 11.5,
                        color: color,
                        fontWeight: detailColor == null
                            ? FontWeight.w400
                            : FontWeight.w600,
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
