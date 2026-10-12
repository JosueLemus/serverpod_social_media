import 'package:flutter/material.dart';

import '../../../../../../../app/theme/app_tokens.dart';
import '../../../../../../../core/widgets/nexo_icon.dart';
import 'show_section.dart';

// TODO(backend): la alerta push 15 min antes todavía no se envía; la
// programa Serverpod al agendar.
/// Qué recibe la audiencia al agendar. Un panel liso con su glifo y no un
/// banner de color: es información, no una alerta.
class AudienceNoticeCard extends StatelessWidget {
  const AudienceNoticeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ShowPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NexoIcon(
            NexoGlyph.activity,
            size: 22,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notificación a tu audiencia', style: text.titleSmall),
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
