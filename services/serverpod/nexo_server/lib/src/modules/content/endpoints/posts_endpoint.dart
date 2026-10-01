import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../services/post_service.dart';

/// Publicaciones: leer el feed, publicar con fotos o videos, editar y
/// eliminar. Desde Flutter: `client.posts`.
///
/// Leer es público: un invitado ve los posts públicos. Todo lo que escribe
/// exige sesión y responde [NexoException] con el código del motivo.
class PostsEndpoint extends Endpoint {
  static const _posts = PostService();

  /// Feed principal, del más nuevo al más viejo. Pasar el `nextCursor` de la
  /// página anterior como [after] para seguir. [limit] va de 1 a 50 (20 por
  /// defecto).
  Future<PostPage> feed(
    Session session, {
    PageCursor? after,
    int? limit,
  }) => _posts.feed(session, after: after, limit: limit);

  /// Posts de un autor, para su perfil. Misma paginación que [feed].
  Future<PostPage> byAuthor(
    Session session,
    UuidValue authorId, {
    PageCursor? after,
    int? limit,
  }) => _posts.byAuthor(session, authorId, after: after, limit: limit);

  /// Un post. `notFound` si no existe, se eliminó o no se puede ver.
  Future<PostView> get(Session session, int postId) =>
      _posts.get(session, postId);

  /// Paso 1 de publicar con un archivo: pide permiso para subirlo. Se sube
  /// con `FileUploader(ticket.uploadDescription)` y la `ticket.key` va en
  /// [PostDraft.mediaKeys]. Imágenes JPEG, PNG, WebP o GIF de hasta 10 MB;
  /// videos MP4, MOV o WebM de hasta 50 MB.
  Future<MediaUploadTicket> requestMediaUpload(
    Session session, {
    required PostMediaKind kind,
    required String contentType,
    required int sizeBytes,
  }) => _posts.requestMediaUpload(
    session,
    kind: kind,
    contentType: contentType,
    sizeBytes: sizeBytes,
  );

  /// Paso 2: publica. Necesita texto, archivos o ambos (hasta 4 archivos).
  Future<PostView> create(Session session, PostDraft draft) =>
      _posts.create(session, draft);

  /// Edita texto, etiquetas, visibilidad o comentarios. Solo el autor.
  Future<PostView> update(Session session, int postId, PostEdit edit) =>
      _posts.update(session, postId, edit);

  /// Elimina un post. El autor, un moderador o un operador. Queda auditado.
  Future<void> delete(Session session, int postId) =>
      _posts.delete(session, postId);
}
