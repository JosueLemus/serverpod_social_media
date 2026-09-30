import 'package:flutter/material.dart';

import '../../../../../../../app/theme/app_tokens.dart';
import '../../../../../../../core/widgets/pills.dart';
import '../../../../../domain/entities/live_session.dart';
import '../../../../utils/live_status_ui.dart';
import '../bloc/schedule_show_cubit.dart';
import '../utils/show_date_format.dart';
import 'show_section.dart';

class FeedPreviewCard extends StatelessWidget {
  const FeedPreviewCard({
    super.key,
    required this.draft,
    required this.now,
    required this.hostUsername,
  });

  final ShowDraft draft;
  final DateTime now;
  final String hostUsername;

  static const _placeholderTitle = 'Tu próximo show';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final title = draft.title.trim().isEmpty
        ? _placeholderTitle
        : draft.title.trim();
    return ShowSection(
      icon: Icons.preview_outlined,
      title: 'Previsualización en Feed',
      trailing: Text(
        'MODO SEGUIDOR',
        style: text.labelSmall?.copyWith(
          color: AppColors.tertiary,
          fontWeight: FontWeight.w800,
          letterSpacing: .6,
        ),
      ),
      child: Card(
        key: const Key('schedule-feed-preview'),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // TODO(backend): portada real cuando haya subida de media.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.stageDark, AppColors.primaryDeep],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xl,
                      AppSpacing.md,
                      AppSpacing.xl,
                    ),
                    child: Center(
                      child: Text(
                        title.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: text.headlineSmall?.copyWith(
                          color: Colors.white,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        StatusBadge(
                          label: LiveStatus.scheduled.label,
                          color: LiveStatus.scheduled.color,
                          icon: Icons.event_available_rounded,
                        ),
                        StatusBadge(
                          label: ShowDateFormat.duration(draft.durationMinutes),
                          color: AppColors.stageScrim,
                        ),
                        if (draft.access == ShowAccess.members)
                          const StatusBadge(
                            label: 'Pro',
                            color: AppColors.warning,
                            icon: Icons.star_rounded,
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _PreviewFooter(draft: draft, now: now),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleLarge?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'por @$hostUsername',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewFooter extends StatelessWidget {
  const _PreviewFooter({required this.draft, required this.now});

  final ShowDraft draft;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final startsAt = draft.startsAt;
    const style = TextStyle(
      color: Colors.white,
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, AppColors.stageScrim],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.xs,
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded, size: 13, color: Colors.white),
            const SizedBox(width: AppSpacing.xxs),
            Expanded(
              child: Text(
                '${ShowDateFormat.shortDate(startsAt)} · '
                '${ShowDateFormat.time(startsAt)} '
                '${ShowDateFormat.gmtOffset(startsAt.timeZoneOffset)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            StatusBadge(
              label: ShowDateFormat.countdown(startsAt, now: now),
              color: AppColors.stageScrim,
            ),
          ],
        ),
      ),
    );
  }
}
