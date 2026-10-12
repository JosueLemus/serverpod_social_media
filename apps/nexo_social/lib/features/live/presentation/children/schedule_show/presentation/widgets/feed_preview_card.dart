import 'package:flutter/material.dart';

import '../../../../../../../app/theme/app_tokens.dart';
import '../../../../../domain/entities/live_session.dart';
import '../../../../widgets/live_card.dart';
import '../bloc/schedule_show_cubit.dart';
import 'show_section.dart';

/// El show tal como lo va a ver la audiencia en Explorar.
///
/// No es un dibujo aparte: es la misma [LiveCard] de la lista, armada con el
/// borrador como una sesión programada. Así lleva el borde punteado (sigue en
/// la plancha) y no puede prometer algo que la tarjeta real no muestre.
class FeedPreviewCard extends StatelessWidget {
  const FeedPreviewCard({
    super.key,
    required this.draft,
    required this.hostName,
    required this.hostUsername,
    this.hostAvatarUrl,
  });

  final ShowDraft draft;
  final String hostName;
  final String hostUsername;
  final String? hostAvatarUrl;

  static const _placeholderTitle = 'Tu próximo show';

  @override
  Widget build(BuildContext context) {
    final title = draft.title.trim();
    final session = LiveSession(
      id: 'preview',
      title: title.isEmpty ? _placeholderTitle : title,
      hostName: hostName.isEmpty ? 'Tú' : hostName,
      hostUsername: hostUsername,
      hostAvatarUrl: hostAvatarUrl,
      status: LiveStatus.scheduled,
      scheduledAt: draft.startsAt,
      durationMinutes: draft.durationMinutes,
      isPremium: draft.access == ShowAccess.members,
      allowQuestions: draft.allowQuestions,
      recordReplay: draft.recordReplay,
    );
    return ShowSection(
      title: 'Previsualización en Feed',
      subtitle: 'Así lo verán tus seguidores en Explorar.',
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xxs),
        child: LiveCard(
          key: const Key('schedule-feed-preview'),
          session: session,
          onTap: null,
        ),
      ),
    );
  }
}
