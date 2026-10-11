import '../../domain/entities/post.dart';

/// Lo que se comparte de una publicación: quién, qué dijo y sus etiquetas.
///
/// Sin enlace por ahora: no hay una pantalla de publicación a la que llevar.
/// Un texto largo se corta en 280 para que entre en un mensaje sin
/// convertirse en el post entero pegado.
String postShareText(Post post) {
  final who = post.author.isEmpty
      ? post.name
      : '${post.name} (@${post.author})';
  final body = post.body.trim();
  final quote = body.length > 280
      ? '${body.substring(0, 279).trimRight()}…'
      : body;
  final tags = post.tags.map((tag) => '#$tag').join(' ');
  return [
    '$who en Nexo:',
    if (quote.isNotEmpty) '“$quote”',
    if (tags.isNotEmpty) tags,
  ].join('\n\n');
}
