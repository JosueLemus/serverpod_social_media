import 'dart:async';

import 'package:nexo_client/nexo_client.dart' as api;

import '../../../../core/errors/failures.dart';
import '../../../../core/mock/mock_platform.dart';
import '../../../../core/network/serverpod_failures.dart';
import '../../domain/entities/moderation_action.dart';
import '../../domain/repositories/moderation_repository.dart';

/// La cola de moderación con cuentas reales (SDD 0007, F9).
///
/// Híbrida a propósito, y por poco tiempo: los reportes de posts y de sus
/// comentarios ya van al servidor (`moderation.report` desde el feed), pero
/// ninguna pantalla los leía. Los del chat de vivos y la auditoría completa
/// siguen en [MockPlatform] hasta M6. Esta clase junta las dos colas y manda
/// cada decisión a quien tiene el reporte.
class ServerpodModerationRepository implements ModerationRepository {
  ServerpodModerationRepository(this._client, this._platform);

  final api.Client _client;
  final MockPlatform _platform;
  final _changes = StreamController<void>.broadcast();

  /// Lo que se leyó de la cola del servidor, para armar la entrada de
  /// auditoría al resolver: `resolve` no devuelve nada.
  final _seen = <String, ModerationReport>{};

  /// Las decisiones sobre reportes del servidor tomadas en esta sesión. El
  /// servidor las audita, pero no expone su auditoría todavía.
  final _decided = <ModerationAction>[];

  static const _prefix = 'post-report:';

  @override
  Future<List<ModerationReport>> reports() async {
    final List<api.ReportQueueItem> queue;
    try {
      queue = await _client.moderation.queue();
    } catch (error) {
      throw failureFromServer(error);
    }
    final fromServer = [for (final item in queue) toReport(item)];
    _seen
      ..clear()
      ..addEntries(fromServer.map((report) => MapEntry(report.id, report)));
    return [...fromServer, ..._mockOr(_platform.openReports, const [])]..sort((
      a,
      b,
    ) {
      final bySeverity = b.severity.index.compareTo(a.severity.index);
      return bySeverity != 0 ? bySeverity : b.createdAt.compareTo(a.createdAt);
    });
  }

  @override
  Future<List<ModerationAction>> list() async =>
      [..._decided, ..._mockOr(_platform.moderationActions, const [])]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Los comentarios del chat de vivos se reportan al mock hasta que exista
  /// `ReportTargetType.liveChatMessage` (SDD 0006, fase 3).
  @override
  Future<void> reportComment({
    required String liveId,
    required String commentId,
    required ModerationReason reason,
  }) async => _platform.reportComment(
    liveId: liveId,
    commentId: commentId,
    reason: reason,
  );

  @override
  Future<ModerationAction> resolve(
    String reportId,
    ModerationDecision decision,
  ) async {
    if (!reportId.startsWith(_prefix)) {
      return _platform.resolveReport(reportId, decision);
    }
    final serverDecision = switch (decision.type) {
      ModerationType.hideComment => api.ReportDecision.hideContent,
      ModerationType.dismissReport => api.ReportDecision.dismiss,
      // La View no los ofrece en un reporte del servidor (F10). Si llegan
      // igual, es un rechazo y no una aproximación silenciosa.
      _ => throw const ForbiddenFailure('moderation.resolve: unsupported'),
    };
    await _resolveOnServer(reportId, serverDecision);
    final report = _seen[reportId];
    final action = ModerationAction(
      id: '$reportId:${DateTime.now().microsecondsSinceEpoch}',
      type: decision.type,
      target: report?.author ?? 'contenido reportado',
      reason: report?.reason ?? ModerationReason.other,
      actor: _actorHandle(),
      createdAt: DateTime.now(),
    );
    _decided.add(action);
    _notify();
    return action;
  }

  @override
  Future<void> dismiss(String reportId) async {
    if (!reportId.startsWith(_prefix)) {
      return _platform.dismissReport(reportId);
    }
    await resolve(
      reportId,
      const ModerationDecision(type: ModerationType.dismissReport),
    );
  }

  @override
  Stream<void> changes() {
    late final StreamController<void> merged;
    StreamSubscription<void>? local;
    StreamSubscription<void>? platform;
    merged = StreamController<void>(
      onListen: () {
        local = _changes.stream.listen(merged.add);
        platform = _platform.changes.listen(merged.add);
      },
      onCancel: () async {
        await local?.cancel();
        await platform?.cancel();
      },
    );
    return merged.stream;
  }

  /// Público para los tests: es la traducción que más se puede romper.
  static ModerationReport toReport(api.ReportQueueItem item) =>
      ModerationReport(
        id: '$_prefix${item.reportId}',
        content: item.targetRemoved
            ? 'El autor ya eliminó este contenido.'
            : item.excerpt,
        author: '@${item.targetAuthorUsername ?? 'cuenta'}',
        authorId: item.targetAuthorId.toString(),
        reason: ModerationReason.values.byName(item.reason.name),
        severity: ReportSeverity.values.byName(item.severity.name),
        createdAt: item.firstReportedAt.toLocal(),
        commentId: item.targetType == api.ReportTargetType.postComment
            ? '${item.targetId}'
            : null,
        canSanctionAuthor: false,
      );

  Future<void> _resolveOnServer(
    String reportId,
    api.ReportDecision decision,
  ) async {
    try {
      await _client.moderation.resolve(
        int.parse(reportId.substring(_prefix.length)),
        decision,
      );
    } catch (error) {
      throw failureFromServer(error);
    }
  }

  /// Sin pareja en el mock (una cuenta real nueva), el mock rechaza: su cola
  /// queda vacía y la del servidor se sigue viendo.
  static T _mockOr<T>(T Function() read, T fallback) {
    try {
      return read();
    } on Failure {
      return fallback;
    }
  }

  String _actorHandle() {
    final id = _platform.sessionAccountId;
    final user = id == null ? null : _platform.accountById(id);
    return user == null ? 'moderación' : '@${user.username}';
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }
}
