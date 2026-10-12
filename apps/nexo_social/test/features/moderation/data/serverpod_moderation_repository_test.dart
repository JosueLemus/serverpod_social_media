import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_client/nexo_client.dart' as api;
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/core/mock/mock_platform.dart';
import 'package:nexo_social/features/moderation/data/repositories/serverpod_moderation_repository.dart';
import 'package:nexo_social/features/moderation/domain/entities/moderation_action.dart';

import '../../../support/platform_harness.dart';

class _MockClient extends Mock implements api.Client {}

class _MockModeration extends Mock implements api.EndpointModeration {}

api.ReportQueueItem _item({
  int reportId = 7,
  api.ReportTargetType targetType = api.ReportTargetType.post,
  bool removed = false,
}) => api.ReportQueueItem(
  reportId: reportId,
  targetType: targetType,
  targetId: 42,
  postId: 42,
  targetAuthorId: api.UuidValue.fromString(
    '550e8400-e29b-41d4-a716-446655440000',
  ),
  targetAuthorUsername: 'troll_99',
  excerpt: 'Compren seguidores',
  targetRemoved: removed,
  reason: api.ModerationReason.spam,
  severity: api.ReportSeverity.high,
  reportCount: 3,
  firstReportedAt: DateTime.utc(2026, 10, 11, 12),
);

void main() {
  late MockPlatform platform;
  late _MockClient client;
  late _MockModeration moderation;

  setUpAll(() => registerFallbackValue(api.ReportDecision.dismiss));

  setUp(() async {
    platform = await platformAs(DemoAccounts.moderator.id);
    client = _MockClient();
    moderation = _MockModeration();
    when(() => client.moderation).thenReturn(moderation);
  });
  tearDown(() => platform.dispose());

  group('toReport', () {
    test('a post report keeps its text, author and severity', () {
      final report = ServerpodModerationRepository.toReport(_item());

      expect(report.content, 'Compren seguidores');
      expect(report.author, '@troll_99');
      expect(report.reason, ModerationReason.spam);
      expect(report.severity, ReportSeverity.high);
      expect(report.commentId, isNull);
    });

    test(
      'the server cannot mute or ban yet, so the queue must not offer it',
      () {
        expect(
          ServerpodModerationRepository.toReport(_item()).canSanctionAuthor,
          isFalse,
        );
      },
    );

    test('a comment report points at the comment', () {
      final report = ServerpodModerationRepository.toReport(
        _item(targetType: api.ReportTargetType.postComment),
      );
      expect(report.commentId, '42');
    });

    test('content its author already deleted says so', () {
      final report = ServerpodModerationRepository.toReport(
        _item(removed: true),
      );
      expect(report.content, isNot('Compren seguidores'));
    });
  });

  /// Regresión: los reportes del feed iban al servidor y la cola leía sólo
  /// el mock, así que nunca aparecían.
  test('the queue shows the server reports next to the chat ones', () async {
    when(() => moderation.queue()).thenAnswer((_) async => [_item()]);
    final repository = ServerpodModerationRepository(client, platform);

    final reports = await repository.reports();

    expect(reports.where((report) => !report.canSanctionAuthor), hasLength(1));
    expect(reports.where((report) => report.canSanctionAuthor), isNotEmpty);
  });

  test('resolving a server report goes to the server and is audited', () async {
    when(() => moderation.queue()).thenAnswer((_) async => [_item()]);
    when(() => moderation.resolve(any(), any())).thenAnswer((_) async {});
    final repository = ServerpodModerationRepository(client, platform);
    // El mock también tiene un reporte sobre troll_99: se elige el del
    // servidor, que es el que no ofrece sanciones.
    final report = (await repository.reports()).firstWhere(
      (report) => !report.canSanctionAuthor,
    );

    final action = await repository.resolve(
      report.id,
      const ModerationDecision(type: ModerationType.hideComment),
    );

    verify(
      () => moderation.resolve(7, api.ReportDecision.hideContent),
    ).called(1);
    expect(action.actor, '@${DemoAccounts.moderator.username}');
    expect(await repository.list(), contains(action));
  });

  test('muting on a server report is refused, not approximated', () async {
    final repository = ServerpodModerationRepository(client, platform);

    await expectLater(
      repository.resolve(
        'post-report:7',
        const ModerationDecision(
          type: ModerationType.muteUser,
          muteFor: MuteDuration.oneHour,
        ),
      ),
      throwsA(isA<ForbiddenFailure>()),
    );
    verifyNever(() => moderation.resolve(any(), any()));
  });

  test('a chat report is still resolved by the mock', () async {
    when(() => moderation.queue()).thenAnswer((_) async => const []);
    final repository = ServerpodModerationRepository(client, platform);
    final chat = (await repository.reports()).first;

    await repository.dismiss(chat.id);

    verifyNever(() => moderation.resolve(any(), any()));
    expect(
      (await repository.reports()).map((report) => report.id),
      isNot(contains(chat.id)),
    );
  });

  test('without a mock twin the server queue still shows', () async {
    platform.bindSession(null);
    when(() => moderation.queue()).thenAnswer((_) async => [_item()]);
    final repository = ServerpodModerationRepository(client, platform);

    expect((await repository.reports()).single.author, '@troll_99');
  });
}
