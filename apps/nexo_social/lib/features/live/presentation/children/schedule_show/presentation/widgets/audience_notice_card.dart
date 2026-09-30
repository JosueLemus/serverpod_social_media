import 'package:flutter/material.dart';

import '../../../../../../../app/theme/app_tokens.dart';

class AudienceNoticeCard extends StatelessWidget {
  const AudienceNoticeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: AppRadii.medium,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primaryDeep,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notificación a tu audiencia', style: text.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Se enviará una alerta push 15 min antes con opción de '
                  'agendar en Google Calendar o Apple iCal en 1 tap.',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
