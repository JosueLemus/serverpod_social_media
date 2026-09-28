import '../../domain/entities/moderation_action.dart';
import '../../domain/repositories/moderation_repository.dart';

class MockModerationRepository implements ModerationRepository {
  final _actions = <ModerationAction>[];

  final _reports = <ModerationReport>[
    ModerationReport(
      id: 'report-1',
      content: 'Esto no aporta nada a la conversación, ándate de aquí',
      author: '@usuario_demo',
      reason: 'Acoso',
      severity: ReportSeverity.high,
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    ModerationReport(
      id: 'report-2',
      content: 'Compra seguidores baratos en este enlace',
      author: '@promo_bot',
      reason: 'Spam',
      severity: ReportSeverity.medium,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  @override
  Future<List<ModerationReport>> reports() async =>
      List.of(_reports)
        ..sort((a, b) => b.severity.index.compareTo(a.severity.index));

  @override
  Future<List<ModerationAction>> list() async => List.of(_actions);

  @override
  Future<ModerationAction> create(
    ModerationType type,
    String target,
    String reason,
  ) async {
    final action = ModerationAction(
      id: 'audit-${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      target: target,
      reason: reason,
      actor: 'moderador_demo',
      createdAt: DateTime.now(),
    );
    _actions.insert(0, action);
    return action;
  }

  @override
  Future<void> resolve(String reportId) async =>
      _reports.removeWhere((report) => report.id == reportId);
}
