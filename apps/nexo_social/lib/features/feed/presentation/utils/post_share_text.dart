import '../../../../app/router/app_routes.dart';
import '../../../../core/share/share_sheet.dart';
import '../../domain/entities/post.dart';

/// Lo que se comparte de una publicación: quién, qué dijo, sus etiquetas y,
/// con `SHARE_BASE_URL`, el enlace a la publicación (`/p/<id>`).
///
/// Un texto largo se corta en 280 para que entre en un mensaje sin
/// convertirse en el post entero pegado.
String postShareText(Post post, {String? baseUrl}) {
  final who = post.author.isEmpty
      ? post.name
      : '${post.name} (@${post.author})';
  final body = post.body.trim();
  final quote = body.length > 280
      ? '${body.substring(0, 279).trimRight()}…'
      : body;
  final tags = post.tags.map((tag) => '#$tag').join(' ');
  final link = baseUrl == null
      ? shareLink(AppRoutes.post(post.id))
      : shareLink(AppRoutes.post(post.id), baseUrl: baseUrl);
  return [
    '$who en Nexo:',
    if (quote.isNotEmpty) '“$quote”',
    if (tags.isNotEmpty) tags,
    ?link,
  ].join('\n\n');
}
