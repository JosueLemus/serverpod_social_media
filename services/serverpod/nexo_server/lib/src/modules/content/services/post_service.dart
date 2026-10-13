import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../../shared/audit/audit_service.dart';
import '../../../shared/auth/auth_context.dart';
import '../../../shared/gateways/media_storage_gateway.dart';
import '../../../shared/gateways/serverpod_media_storage_gateway.dart';
import '../../../shared/profiles/avatar_lookup.dart';
import '../../../shared/profiles/profile_lookup.dart';
import '../../search/services/search_rules.dart';
import 'post_rules.dart';

/// Reglas de negocio de los posts: quién ve, publica, edita y elimina.
class PostService {
  const PostService({
    this._storage = const ServerpodMediaStorageGateway(),
    this._audit = const AuditService(),
  });

  final MediaStorageGateway _storage;
  final AuditService _audit;

  // --- Lectura -------------------------------------------------------------

  Future<PostPage> feed(Session session, {PageCursor? after, int? limit}) =>
      _page(session, after: after, limit: limit);

  Future<PostPage> byAuthor(
    Session session,
    UuidValue authorId, {
    PageCursor? after,
    int? limit,
  }) => _page(session, authorId: authorId, after: after, limit: limit);

  Future<PostView> get(Session session, int postId) async =>
      _toView(session, await loadVisible(session, postId));

  /// Los posts visibles de [authors], del más nuevo al más viejo: la sección
  /// `following` del feed de inicio.
  Future<PostPage> byAuthors(
    Session session,
    Set<UuidValue> authors, {
    PageCursor? after,
    int? limit,
  }) async {
    if (authors.isEmpty) return PostPage(items: const []);
    return _page(session, authors: authors, after: after, limit: limit);
  }

  /// Posts públicos de cuentas fuera de [excludeAuthors], del más nuevo al
  /// más viejo. Con [preferredTags], sólo los que comparten alguna etiqueta,
  /// siempre que exista al menos uno; si no, todos (S7 del SDD 0008).
  ///
  /// `tags` se guarda como JSON y la superposición no se expresa en el ORM,
  /// así que el filtro corre en Dart sobre lotes acotados. El cursor sigue
  /// siendo el keyset de siempre: una página no repite ni saltea.
  Future<PostPage> discover(
    Session session, {
    required Set<UuidValue> excludeAuthors,
    Set<String> preferredTags = const {},
    PageCursor? after,
    int? limit,
  }) async {
    final size = PostRules.pageSize(limit);
    final tags = {for (final tag in preferredTags) tag.toLowerCase()};
    bool matches(Post post) =>
        post.tags.any((tag) => tags.contains(tag.toLowerCase()));

    Future<List<Post>> batch(PageCursor? from, int count) => Post.db.find(
      session,
      where: (t) {
        var where =
            t.deletedAt.equals(null) &
            t.visibility.equals(PostVisibility.public);
        if (excludeAuthors.isNotEmpty) {
          where = where & t.authorId.notInSet(excludeAuthors);
        }
        if (from != null) {
          where =
              where &
              ((t.createdAt < from.createdAt) |
                  (t.createdAt.equals(from.createdAt) & (t.id < from.id)));
        }
        return where;
      },
      orderByList: (t) => [t.createdAt.desc(), t.id.desc()],
      limit: count,
      include: _withMedia,
    );

    final filtered =
        tags.isNotEmpty && (await batch(null, _discoverProbe)).any(matches);

    final picked = <Post>[];
    var cursor = after;
    var exhausted = false;
    for (var round = 0; round < _discoverRounds; round++) {
      final rows = await batch(cursor, _discoverBatch);
      for (final post in rows) {
        if (!filtered || matches(post)) picked.add(post);
        if (picked.length > size) break;
      }
      if (rows.length < _discoverBatch) exhausted = true;
      if (picked.length > size || exhausted || rows.isEmpty) break;
      cursor = PageCursor(createdAt: rows.last.createdAt, id: rows.last.id!);
    }

    final hasMore = picked.length > size;
    final items = hasMore ? picked.sublist(0, size) : picked;
    // Si se cortó por el tope de rondas sin agotar la tabla, la próxima
    // página sigue escaneando desde donde quedó.
    final resumeAt = hasMore
        ? PageCursor(createdAt: items.last.createdAt, id: items.last.id!)
        : (!exhausted && cursor != null && cursor != after ? cursor : null);
    return PostPage(
      items: await _toViews(session, items),
      nextCursor: resumeAt,
    );
  }

  /// Los posts que la sesión puede ver cuyo cuerpo o alguna etiqueta
  /// coincide con [pattern], un patrón de `ILIKE` ya escapado y plegado
  /// (`SearchRules.containsPattern`). Del más nuevo al más viejo, con la
  /// misma visibilidad que cualquier lectura.
  Future<List<PostView>> search(
    Session session,
    String pattern, {
    required int limit,
  }) async {
    final followees = await _followeesOf(session);
    final matching = await _idsMatching(session, pattern);
    if (matching.isEmpty) return const [];
    final rows = await Post.db.find(
      session,
      where: (t) => _visibleWhere(t, session, followees) & t.id.inSet(matching),
      orderByList: (t) => [t.createdAt.desc(), t.id.desc()],
      limit: limit,
      include: _withMedia,
    );
    return _toViews(session, rows);
  }

  /// Las etiquetas de posts públicos que coinciden con [pattern], de la más
  /// usada a la menos. Sólo públicos: el nombre de una etiqueta también dice
  /// algo de un post que no se puede ver.
  Future<List<String>> tagsLike(
    Session session,
    String pattern, {
    required int limit,
  }) async {
    // `tags` es una columna `json`: el ORM no la desarma, así que va en SQL,
    // con todo lo que viene de afuera como parámetro.
    final rows = await session.db.unsafeQuery(
      'SELECT lower(tag) AS tag, count(*) AS uses '
      'FROM post, json_array_elements_text(post.tags) AS tag '
      'WHERE post."deletedAt" IS NULL AND post.visibility = @public '
      "AND ${SearchRules.foldSql('tag')} ILIKE @pattern ESCAPE '\\' "
      'GROUP BY lower(tag) ORDER BY uses DESC, tag ASC LIMIT @limit',
      parameters: QueryParameters.named({
        'public': PostVisibility.public.name,
        'pattern': pattern,
        'limit': limit,
      }),
    );
    return [for (final row in rows) row[0] as String];
  }

  /// Los ids de posts cuyo cuerpo o alguna etiqueta coincide con [pattern],
  /// del más nuevo al más viejo. Va en SQL porque se compara sin tildes
  /// (`SearchRules.foldSql`) y el ORM no compara una columna transformada.
  /// La visibilidad la aplica quien los usa.
  Future<Set<int>> _idsMatching(Session session, String pattern) async {
    final rows = await session.db.unsafeQuery(
      'SELECT post.id FROM post '
      'WHERE post."deletedAt" IS NULL '
      "AND (${SearchRules.foldSql('post.body')} ILIKE @pattern ESCAPE '\\' "
      'OR EXISTS (SELECT 1 FROM json_array_elements_text(post.tags) AS tag '
      "WHERE ${SearchRules.foldSql('tag')} ILIKE @pattern ESCAPE '\\')) "
      'ORDER BY post."createdAt" DESC, post.id DESC '
      'LIMIT @cap',
      parameters: QueryParameters.named({
        'pattern': pattern,
        'cap': _searchCandidates,
      }),
    );
    return {for (final row in rows) row[0] as int};
  }

  /// Tope de candidatos: la búsqueda muestra una página, no recorre la tabla
  /// entera. Son los más nuevos, que es el orden en que se muestran.
  static const _searchCandidates = 500;

  /// Las etiquetas de los posts que [userId] likeó en los últimos [days]
  /// días, para `discover`.
  Future<Set<String>> likedTags(
    Session session,
    UuidValue userId, {
    int days = 30,
  }) async {
    final since = DateTime.now().toUtc().subtract(Duration(days: days));
    final likes = await PostLike.db.find(
      session,
      where: (t) => t.userId.equals(userId) & (t.createdAt > since),
      limit: 200,
    );
    if (likes.isEmpty) return const {};
    final posts = await Post.db.find(
      session,
      where: (t) => t.id.inSet(<int>{for (final like in likes) like.postId}),
    );
    return {
      for (final post in posts)
        for (final tag in post.tags) tag.toLowerCase(),
    };
  }

  static const _discoverBatch = 50;
  static const _discoverRounds = 6;
  static const _discoverProbe = 300;

  // --- Escritura -----------------------------------------------------------

  /// Reserva una clave y devuelve el permiso para subir el archivo. El tipo
  /// y el tamaño se validan acá y el storage los vuelve a exigir al subir.
  Future<MediaUploadTicket> requestMediaUpload(
    Session session, {
    required PostMediaKind kind,
    required String contentType,
    required int sizeBytes,
  }) async {
    final ownerId = session.requireUserId;

    final ext = MediaPolicy.extensionFor(kind, contentType);
    if (ext == null) {
      throw _error(
        NexoErrorCode.invalidInput,
        'Ese tipo de archivo no se acepta como ${kind.name}.',
      );
    }
    final maxBytes = MediaPolicy.maxBytes(kind);
    if (sizeBytes <= 0 || sizeBytes > maxBytes) {
      throw _error(
        NexoErrorCode.invalidInput,
        'El archivo supera el máximo de ${maxBytes ~/ (1024 * 1024)} MB.',
      );
    }

    final key = MediaPolicy.newKey(ownerId, kind, ext);
    final description = await _storage.createUploadDescription(
      session,
      key,
      contentType: contentType.toLowerCase(),
      contentLength: sizeBytes,
      maxBytes: maxBytes,
    );
    if (description == null) {
      throw StateError('El storage configurado no admite subidas directas.');
    }
    return MediaUploadTicket(
      key: key,
      uploadDescription: description,
      maxBytes: maxBytes,
    );
  }

  Future<PostView> create(Session session, PostDraft draft) async {
    final authorId = session.requireUserId;
    final body = PostRules.normalizeBody(draft.body);
    final tags = PostRules.normalizeTags(draft.tags);
    final media = await _verifiedMedia(session, authorId, draft.mediaKeys);

    if (body.isEmpty && media.isEmpty) {
      throw _error(
        NexoErrorCode.invalidInput,
        'Escribe algo o adjunta un archivo.',
      );
    }

    final postId = await session.db.transaction((tx) async {
      final post = await Post.db.insertRow(
        session,
        Post(
          authorId: authorId,
          body: body,
          tags: tags,
          visibility: draft.visibility,
          allowComments: draft.allowComments,
        ),
        transaction: tx,
      );
      await PostMedia.db.insert(session, [
        for (final (i, m) in media.indexed)
          PostMedia(
            postId: post.id!,
            kind: m.parsed.kind,
            storageKey: m.key,
            contentType: m.parsed.contentType,
            position: i,
          ),
      ], transaction: tx);
      return post.id!;
    });

    return get(session, postId);
  }

  /// Solo el autor edita. Los adjuntos no cambian.
  Future<PostView> update(Session session, int postId, PostEdit edit) async {
    final userId = session.requireUserId;

    final changed = [
      if (edit.body != null) 'body',
      if (edit.tags != null) 'tags',
      if (edit.visibility != null) 'visibility',
      if (edit.allowComments != null) 'allowComments',
    ];
    if (changed.isEmpty) {
      throw _error(NexoErrorCode.invalidInput, 'No hay cambios para guardar.');
    }

    await session.db.transaction((tx) async {
      final post = await loadVisible(session, postId, transaction: tx);
      if (post.authorId != userId) {
        throw _error(NexoErrorCode.forbidden, 'Solo el autor puede editar.');
      }

      final body = edit.body == null
          ? post.body
          : PostRules.normalizeBody(edit.body!);
      if (body.isEmpty &&
          await PostMedia.db.count(
                session,
                where: (t) => t.postId.equals(postId),
                transaction: tx,
              ) ==
              0) {
        throw _error(
          NexoErrorCode.invalidInput,
          'Un post sin adjuntos necesita texto.',
        );
      }

      await Post.db.updateRow(
        session,
        post.copyWith(
          body: body,
          tags: edit.tags == null ? null : PostRules.normalizeTags(edit.tags!),
          visibility: edit.visibility,
          allowComments: edit.allowComments,
          editedAt: DateTime.now().toUtc(),
        ),
        transaction: tx,
      );
      await _audit.record(
        session,
        actorId: userId,
        action: 'post.update',
        entityType: 'post',
        entityId: '$postId',
        metadata: {'fields': changed},
        transaction: tx,
      );
    });

    return get(session, postId);
  }

  /// El autor, un moderador o un operador. No borra la fila: la marca.
  Future<void> delete(Session session, int postId) async {
    final userId = session.requireUserId;

    await session.db.transaction((tx) async {
      final post = await loadVisible(session, postId, transaction: tx);
      final isAuthor = post.authorId == userId;
      if (!isAuthor && !session.isStaff) {
        throw _error(
          NexoErrorCode.forbidden,
          'Solo el autor o un moderador puede eliminar.',
        );
      }

      await markRemoved(session, post, by: userId, transaction: tx);
      await _audit.record(
        session,
        actorId: userId,
        action: 'post.delete',
        entityType: 'post',
        entityId: '$postId',
        metadata: {'asModerator': !isAuthor},
        transaction: tx,
      );
    });
  }

  // --- Para otros módulos --------------------------------------------------
  //
  // `social` y `moderation` actúan sobre posts. Pasan por acá en vez de leer
  // la tabla, para que "quién ve un post" siga siendo una sola regla.

  /// Un post que [session] puede ver, o `notFound`. Uno que existe pero no le
  /// corresponde ver también es `notFound`: `forbidden` confirmaría que existe.
  ///
  /// Con [transaction], bloquea la fila hasta el commit: quien la cambia
  /// después (un contador, un borrado) no pisa a otro que la cambió a la vez.
  Future<Post> loadVisible(
    Session session,
    int postId, {
    Transaction? transaction,
  }) async {
    final post = await Post.db.findById(
      session,
      postId,
      transaction: transaction,
      lockMode: transaction == null ? null : LockMode.forUpdate,
    );
    if (post == null ||
        post.deletedAt != null ||
        !await _canSee(session, post, transaction: transaction)) {
      throw _error(NexoErrorCode.notFound, 'La publicación no existe.');
    }
    return post;
  }

  /// Saca [post] de toda lectura. No audita: lo hace quien decide, que es
  /// quien sabe por qué (el autor, un moderador al resolver un reporte).
  Future<void> markRemoved(
    Session session,
    Post post, {
    required UuidValue by,
    required Transaction transaction,
  }) async {
    await Post.db.updateRow(
      session,
      post.copyWith(deletedAt: DateTime.now().toUtc(), deletedBy: by),
      columns: (t) => [t.deletedAt, t.deletedBy],
      transaction: transaction,
    );
  }

  /// Suma [likes] y [comments] a los contadores. [post] tiene que venir de
  /// [loadVisible] con la misma [transaction], que es la que tiene el bloqueo.
  Future<void> adjustCounts(
    Session session,
    Post post, {
    int likes = 0,
    int comments = 0,
    required Transaction transaction,
  }) async {
    await Post.db.updateRow(
      session,
      post.copyWith(
        likeCount: post.likeCount + likes,
        commentCount: post.commentCount + comments,
      ),
      columns: (t) => [t.likeCount, t.commentCount],
      transaction: transaction,
    );
  }

  // --- Internos ------------------------------------------------------------

  /// Público para todos; `followers` para quien sigue al autor; `members`
  /// sólo el autor hasta que exista billing. El autor y el staff ven todo.
  Future<bool> _canSee(
    Session session,
    Post post, {
    Transaction? transaction,
  }) async {
    final viewer = session.userIdOrNull;
    if (post.visibility == PostVisibility.public ||
        post.authorId == viewer ||
        session.isStaff) {
      return true;
    }
    if (post.visibility != PostVisibility.followers || viewer == null) {
      return false;
    }
    return await Follow.db.count(
          session,
          where: (t) =>
              t.followerId.equals(viewer) & t.followeeId.equals(post.authorId),
          transaction: transaction,
        ) >
        0;
  }

  /// Las cuentas que sigue la sesión, para la visibilidad `followers`. El
  /// staff y los invitados no la necesitan.
  Future<Set<UuidValue>> _followeesOf(Session session) async {
    final viewer = session.userIdOrNull;
    if (viewer == null || session.isStaff) return const {};
    return {
      for (final row in await Follow.db.find(
        session,
        where: (t) => t.followerId.equals(viewer),
      ))
        row.followeeId,
    };
  }

  /// La condición de [_canSee] como filtro de consulta. [followees] sale de
  /// [_followeesOf].
  Expression _visibleWhere(
    PostTable t,
    Session session,
    Set<UuidValue> followees,
  ) {
    final viewer = session.userIdOrNull;
    final visible = t.deletedAt.equals(null);
    if (session.isStaff) return visible;
    Expression allowed = t.visibility.equals(PostVisibility.public);
    if (viewer != null) allowed = allowed | t.authorId.equals(viewer);
    if (followees.isNotEmpty) {
      allowed =
          allowed |
          (t.visibility.equals(PostVisibility.followers) &
              t.authorId.inSet(followees));
    }
    return visible & allowed;
  }

  /// Keyset sobre `(createdAt, id)` descendente: una página no repite ni
  /// saltea posts aunque se publique algo mientras se scrollea.
  Future<PostPage> _page(
    Session session, {
    UuidValue? authorId,
    Set<UuidValue>? authors,
    PageCursor? after,
    int? limit,
  }) async {
    final size = PostRules.pageSize(limit);
    final followees = await _followeesOf(session);
    final rows = await Post.db.find(
      session,
      where: (t) {
        var where = _visibleWhere(t, session, followees);
        if (authorId != null) where = where & t.authorId.equals(authorId);
        if (authors != null) where = where & t.authorId.inSet(authors);
        if (after != null) {
          where =
              where &
              ((t.createdAt < after.createdAt) |
                  (t.createdAt.equals(after.createdAt) & (t.id < after.id)));
        }
        return where;
      },
      orderByList: (t) => [t.createdAt.desc(), t.id.desc()],
      limit: size + 1,
      include: _withMedia,
    );

    final hasMore = rows.length > size;
    final items = hasMore ? rows.sublist(0, size) : rows;
    return PostPage(
      items: await _toViews(session, items),
      nextCursor: hasMore
          ? PageCursor(createdAt: items.last.createdAt, id: items.last.id!)
          : null,
    );
  }

  static final _withMedia = Post.include(
    media: PostMedia.includeList(orderBy: (t) => t.position),
  );

  /// Valida cada clave: armada por el servidor, del autor, subida y sin usar
  /// en otro post.
  Future<List<({String key, MediaKey parsed})>> _verifiedMedia(
    Session session,
    UuidValue authorId,
    List<String> keys,
  ) async {
    if (keys.length > PostRules.maxMedia) {
      throw _error(
        NexoErrorCode.invalidInput,
        'Un post admite hasta ${PostRules.maxMedia} archivos.',
      );
    }
    if (keys.toSet().length != keys.length) {
      throw _error(NexoErrorCode.invalidInput, 'Hay archivos repetidos.');
    }

    final result = <({String key, MediaKey parsed})>[];
    for (final key in keys) {
      final parsed = MediaPolicy.parseKey(key);
      if (parsed == null) {
        throw _error(NexoErrorCode.invalidInput, 'Archivo no válido.');
      }
      if (parsed.ownerId != authorId) {
        throw _error(NexoErrorCode.forbidden, 'Ese archivo no es tuyo.');
      }
      if (!await _storage.verifyUpload(session, key)) {
        throw _error(
          NexoErrorCode.invalidInput,
          'El archivo todavía no terminó de subirse.',
        );
      }
      result.add((key: key, parsed: parsed));
    }

    if (keys.isNotEmpty &&
        await PostMedia.db.count(
              session,
              where: (t) => t.storageKey.inSet(keys.toSet()),
            ) >
            0) {
      throw _error(NexoErrorCode.conflict, 'Ese archivo ya está publicado.');
    }
    return result;
  }

  Future<PostView> _toView(Session session, Post post) async {
    final withMedia = post.media == null
        ? await Post.db.findById(session, post.id!, include: _withMedia)
        : post;
    return (await _toViews(session, [withMedia!])).single;
  }

  Future<List<PostView>> _toViews(Session session, List<Post> posts) async {
    if (posts.isEmpty) return const [];

    final profiles = await profilesOf(session, posts.map((p) => p.authorId));
    final avatars = await avatarsOf(
      session,
      posts.map((p) => p.authorId),
      storage: _storage,
    );
    final viewer = session.userIdOrNull;
    final isStaff = session.isStaff;

    // Lee la tabla de `social` en vez de pedirle el dato: una sola consulta
    // por página, y el feed llega con el corazón ya pintado.
    final liked = viewer == null
        ? const <int>{}
        : {
            for (final like in await PostLike.db.find(
              session,
              where: (t) =>
                  t.userId.equals(viewer) &
                  t.postId.inSet(posts.map((p) => p.id!).toSet()),
            ))
              like.postId,
          };

    return Future.wait(
      posts.map((post) async {
        final profile = profiles[post.authorId];
        final isAuthor = post.authorId == viewer;
        return PostView(
          id: post.id!,
          authorId: post.authorId,
          authorUsername: profile?.userName,
          authorName: profile?.fullName,
          authorAvatarUrl: avatars[post.authorId],
          body: post.body,
          tags: post.tags,
          visibility: post.visibility,
          allowComments: post.allowComments,
          likeCount: post.likeCount,
          isLiked: liked.contains(post.id),
          commentCount: post.commentCount,
          media: await _mediaViews(session, post.media ?? const []),
          createdAt: post.createdAt,
          editedAt: post.editedAt,
          canEdit: isAuthor,
          canDelete: isAuthor || isStaff,
        );
      }),
    );
  }

  /// Un archivo que ya no está en el storage se omite en vez de romper el
  /// post entero.
  Future<List<PostMediaView>> _mediaViews(
    Session session,
    List<PostMedia> media,
  ) async {
    final views = <PostMediaView>[];
    for (final m in media) {
      final url = await _storage.publicUrl(session, m.storageKey);
      if (url == null) continue;
      views.add(
        PostMediaView(kind: m.kind, url: url, contentType: m.contentType),
      );
    }
    return views;
  }

  static NexoException _error(NexoErrorCode code, String message) =>
      NexoException(code: code, message: message);
}
