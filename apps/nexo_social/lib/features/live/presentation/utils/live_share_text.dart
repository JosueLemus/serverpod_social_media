import '../../../../app/router/app_routes.dart';
import '../../../../core/share/share_sheet.dart';
import '../../domain/entities/live_session.dart';
import 'live_status_ui.dart';

/// Lo que se comparte de un vivo, según si está al aire o todavía no.
String liveShareText(LiveSession session, {String? baseUrl}) {
  final host = session.hostUsername.isEmpty
      ? session.hostName
      : '${session.hostName} (@${session.hostUsername})';
  final headline = switch (session.status) {
    _ when session.status.isOnAir => '$host está en vivo en Nexo',
    LiveStatus.scheduled => '$host va a transmitir en Nexo',
    _ => 'Mirá el vivo de $host en Nexo',
  };
  final link = baseUrl == null
      ? shareLink(AppRoutes.liveRoom(session.id))
      : shareLink(AppRoutes.liveRoom(session.id), baseUrl: baseUrl);
  return ['$headline: «${session.title}»', ?link].join('\n\n');
}
