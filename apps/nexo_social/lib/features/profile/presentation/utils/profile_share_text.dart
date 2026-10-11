import '../../../../app/router/app_routes.dart';
import '../../../../core/share/share_sheet.dart';
import '../../domain/entities/public_profile.dart';

/// Lo que se comparte de un perfil: a quién seguir y, si hay, su bio.
String profileShareText(PublicProfile profile, {String? baseUrl}) {
  final bio = profile.bio?.trim() ?? '';
  final link = baseUrl == null
      ? shareLink(AppRoutes.profileOf(profile.username))
      : shareLink(AppRoutes.profileOf(profile.username), baseUrl: baseUrl);
  return [
    'Seguí a ${profile.name} (@${profile.username}) en Nexo',
    if (bio.isNotEmpty) bio,
    ?link,
  ].join('\n\n');
}
