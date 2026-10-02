import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../../../generated/protocol.dart';
import '../../../shared/audit/audit_service.dart';
import '../../../shared/auth/auth_context.dart';
import '../../../shared/profiles/profile_lookup.dart';
import '../../content/services/post_service.dart';
import '../../social/services/comment_service.dart';
import 'moderation_rules.dart';

/// Reportes de contenido: cualquiera con sesión reporta; el staff revisa la
/// cola y resuelve.
class ModerationService {
  const ModerationService({
    this._posts = const PostService(),
    this._comments = const CommentService(),
    this._audit = const AuditService(),
  });

  final PostService _posts;
  final CommentService _comments;
  final AuditService _audit;

  /// Reporta un contenido que quien reporta puede ver. Repetir el mismo
  /// reporte mientras sigue abierto no crea otro.
  Future<void> report(
    Session session, {
    required ReportTargetType targetType,
    required int targetId,
    required ModerationReason reason,
    String? details,
  }) async {
    final reporterId = session.requireUserId;
    final note = details?.trim();
    if (note != null && note.length > ModerationRules.maxDetailsLength) {
      throw _error(
        NexoErrorCode.invalidInput,
        'El detalle supera los ${ModerationRules.maxDetailsLength} '
        'caracteres.',
      );
    }

    final authorId = await _authorOf(session, targetType, targetId);
    if (authorId == reporterId) {
      throw _error(
        NexoErrorCode.invalidInput,
        'No puedes reportar tu propio contenido.',
      );
    }

    // Chequear y crear en la misma transacción, con un lock por quien
    // reporta y qué reporta: sin él, dos toques seguidos pasaban los dos el
    // chequeo y quedaban dos reportes iguales abiertos.
    await session.db.transaction((tx) async {
      await session.db.unsafeExecute(
        'SELECT pg_advisory_xact_lock(hashtext(@key))',
        parameters: QueryParameters.named({
          'key': 'report:$reporterId:${targetType.name}:$targetId',
        }),
        transaction: tx,
      );

      final alreadyOpen = await ContentReport.db.count(
        session,
        where: (t) =>
            _sameTarget(t, targetType, targetId) &
            t.reporterId.equals(reporterId) &
            t.resolvedAt.equals(null),
        transaction: tx,
      );
      if (alreadyOpen > 0) return;

      final report = await ContentReport.db.insertRow(
        session,
        ContentReport(
          targetType: targetType,
          targetId: targetId,
          targetAuthorId: authorId,
          reporterId: reporterId,
          reason: reason,
          severity: ModerationRules.severityOf(reason),
          details: note == null || note.isEmpty ? null : note,
        ),
        transaction: tx,
      );
      await _audit.record(
        session,
        actorId: reporterId,
        action: 'moderation.report',
        entityType: targetType.name,
        entityId: '$targetId',
        metadata: {'reportId': report.id, 'reason': reason.name},
        transaction: tx,
      );
    });
  }

  /// Contenidos con reportes abiertos, uno por contenido: primero el de
  /// mayor severidad y, a igual severidad, el que espera hace más tiempo.
  Future<List<ReportQueueItem>> queue(Session session, {int? limit}) async {
    session.requireStaff;
    final size = (limit ?? ModerationRules.defaultQueueSize).clamp(
      1,
      ModerationRules.maxQueueSize,
    );

    // Por lotes y no todo de una: con miles de reportes abiertos, cargar la
    // tabla entera en memoria para mostrar los primeros grupos desperdicia
    // memoria. Se recorre todo —el conteo de cada grupo tiene que ser
    // exacto— pero sólo se guardan los [size] grupos que se van a mostrar.
    //
    // Agrupa por contenido conservando el orden: el primer reporte de cada
    // grupo es el de más severidad y más antigüedad.
    final groups = <(ReportTargetType, int), List<ContentReport>>{};
    var offset = 0;
    while (true) {
      final batch = await ContentReport.db.find(
        session,
        where: (t) => t.resolvedAt.equals(null),
        orderByList: (t) => [t.severity.desc(), t.createdAt.asc(), t.id.asc()],
        limit: ModerationRules.queueScanBatch,
        offset: offset,
      );
      for (final r in batch) {
        final key = (r.targetType, r.targetId);
        // Un grupo nuevo más allá de [size] no entra en esta página; los
        // reportes de grupos ya abiertos sí, para que el conteo sea exacto.
        if (!groups.containsKey(key) && groups.length >= size) continue;
        groups.putIfAbsent(key, () => []).add(r);
      }
      if (batch.length < ModerationRules.queueScanBatch) break;
      offset += batch.length;
    }
    final top = groups.values.take(size).toList();

    final postIds = {
      for (final g in top)
        if (g.first.targetType == ReportTargetType.post) g.first.targetId,
    };
    final commentIds = {
      for (final g in top)
        if (g.first.targetType == ReportTargetType.postComment)
          g.first.targetId,
    };
    final comments = {
      for (final c
          in commentIds.isEmpty
              ? const <PostComment>[]
              : await PostComment.db.find(
                  session,
                  where: (t) => t.id.inSet(commentIds),
                ))
        c.id!: c,
    };
    postIds.addAll(comments.values.map((c) => c.postId));
    final posts = {
      for (final p
          in postIds.isEmpty
              ? const <Post>[]
              : await Post.db.find(session, where: (t) => t.id.inSet(postIds)))
        p.id!: p,
    };
    final profiles = await profilesOf(
      session,
      top.map((g) => g.first.targetAuthorId),
    );

    return [
      for (final g in top)
        _queueItem(g, posts: posts, comments: comments, profiles: profiles),
    ];
  }

  /// Aplica [decision] y cierra **todos** los reportes abiertos del mismo
  /// contenido, en una sola transacción y con una sola entrada de auditoría.
  /// Dos pasos sueltos dejan ocultar sin cerrar, y el siguiente moderador
  /// revisa algo ya resuelto.
  Future<void> resolve(
    Session session,
    int reportId,
    ReportDecision decision,
  ) async {
    final moderatorId = session.requireStaff;

    await session.db.transaction((tx) async {
      final report = await ContentReport.db.findById(
        session,
        reportId,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (report == null) {
        throw _error(NexoErrorCode.notFound, 'El reporte no existe.');
      }
      if (report.resolvedAt != null) {
        throw _error(NexoErrorCode.conflict, 'El reporte ya fue resuelto.');
      }

      if (decision == ReportDecision.hideContent) {
        await _hide(session, report, by: moderatorId, transaction: tx);
      }

      final closed = await ContentReport.db.updateWhere(
        session,
        columnValues: (t) => [
          t.resolvedAt(DateTime.now().toUtc()),
          t.resolvedBy(moderatorId),
          t.decision(decision),
        ],
        where: (t) =>
            _sameTarget(t, report.targetType, report.targetId) &
            t.resolvedAt.equals(null),
        transaction: tx,
      );

      await _audit.record(
        session,
        actorId: moderatorId,
        action: 'moderation.${decision.name}',
        entityType: report.targetType.name,
        entityId: '${report.targetId}',
        metadata: {
          'reportIds': [for (final r in closed) r.id],
          'reasons': {for (final r in closed) r.reason.name}.toList(),
          'targetAuthorId': '${report.targetAuthorId}',
        },
        transaction: tx,
      );
    });
  }

  // --- Internos ------------------------------------------------------------

  Future<UuidValue> _authorOf(
    Session session,
    ReportTargetType type,
    int id,
  ) async => switch (type) {
    ReportTargetType.post => (await _posts.loadVisible(session, id)).authorId,
    ReportTargetType.postComment => (await _comments.loadVisible(
      session,
      id,
    )).$2.authorId,
  };

  /// Si el autor ya lo eliminó, `loadVisible` responde `notFound`: no hay
  /// nada que ocultar y lo que corresponde es descartar.
  Future<void> _hide(
    Session session,
    ContentReport report, {
    required UuidValue by,
    required Transaction transaction,
  }) async {
    switch (report.targetType) {
      case ReportTargetType.post:
        final post = await _posts.loadVisible(
          session,
          report.targetId,
          transaction: transaction,
        );
        await _posts.markRemoved(
          session,
          post,
          by: by,
          transaction: transaction,
        );
      case ReportTargetType.postComment:
        final (post, comment) = await _comments.loadVisible(
          session,
          report.targetId,
          transaction: transaction,
        );
        await _comments.markRemoved(
          session,
          post,
          comment,
          by: by,
          transaction: transaction,
        );
    }
  }

  ReportQueueItem _queueItem(
    List<ContentReport> reports, {
    required Map<int, Post> posts,
    required Map<int, PostComment> comments,
    required Map<UuidValue, UserProfile> profiles,
  }) {
    final first = reports.first;
    final (postId, text, removed) = switch (first.targetType) {
      ReportTargetType.post => (
        first.targetId,
        posts[first.targetId]?.body ?? '',
        posts[first.targetId]?.deletedAt != null,
      ),
      ReportTargetType.postComment => () {
        final comment = comments[first.targetId];
        final post = comment == null ? null : posts[comment.postId];
        return (
          comment?.postId ?? 0,
          comment?.body ?? '',
          comment?.deletedAt != null || post?.deletedAt != null,
        );
      }(),
    };

    return ReportQueueItem(
      reportId: first.id!,
      targetType: first.targetType,
      targetId: first.targetId,
      postId: postId,
      targetAuthorId: first.targetAuthorId,
      targetAuthorUsername: profiles[first.targetAuthorId]?.userName,
      excerpt: ModerationRules.excerpt(text),
      targetRemoved: removed,
      reason: first.reason,
      severity: first.severity,
      reportCount: reports.length,
      firstReportedAt: reports
          .map((r) => r.createdAt)
          .reduce((a, b) => a.isBefore(b) ? a : b),
    );
  }

  static Expression _sameTarget(
    ContentReportTable t,
    ReportTargetType type,
    int id,
  ) => t.targetType.equals(type) & t.targetId.equals(id);

  static NexoException _error(NexoErrorCode code, String message) =>
      NexoException(code: code, message: message);
}
