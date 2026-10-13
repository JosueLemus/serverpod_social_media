import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/core/mock/mock_platform.dart';
import 'package:nexo_social/features/live/domain/entities/live_moderation.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';

import '../../support/platform_harness.dart';

/// La moderación de la sala en el mock: las mismas reglas que
/// `LiveModerationService` (SDD 0011, Etapa 3). `live-1` es de Elena y está
/// al aire.
void main() {
  const live = 'live-1';
  late MockPlatform platform;

  setUp(() async => platform = await platformAs(DemoAccounts.elena.id));
  tearDown(() => platform.dispose());

  void as(DemoAccount account) => platform.bindSession(account.id);

  test('el host nombra moderador, y nombrar a otro baja al primero', () {
    platform.assignModerator(live, DemoAccounts.viewer.id);
    as(DemoAccounts.viewer);
    expect(platform.roleIn(live), LiveRole.moderator);

    as(DemoAccounts.elena);
    platform.assignModerator(live, DemoAccounts.troll.id);
    as(DemoAccounts.viewer);
    expect(platform.roleIn(live), LiveRole.audience);
  });

  test('un silenciado no escribe hasta que se lo levantan', () {
    platform.muteChat(
      live,
      DemoAccounts.troll.id,
      LiveMuteDuration.fiveMinutes,
    );
    as(DemoAccounts.troll);
    expect(
      () => platform.postComment(live, 'spam'),
      throwsA(isA<MutedFailure>()),
    );
    expect(platform.roomMute(live, DemoAccounts.troll.id), isNotNull);

    as(DemoAccounts.elena);
    platform.unmuteChat(live, DemoAccounts.troll.id);
    as(DemoAccounts.troll);
    expect(platform.postComment(live, 'perdón').body, 'perdón');
  });

  test('un expulsado no vuelve a esta sala y sale del escenario', () {
    platform
      ..inviteToStage(live, DemoAccounts.viewer.id)
      ..kick(live, DemoAccounts.viewer.id);

    expect(
      platform.exclusion(live, DemoAccounts.viewer.id),
      LiveSanctionKind.kick,
    );
    expect(
      platform.stage(live).speakers.map((s) => s.userId),
      isNot(contains(DemoAccounts.viewer.id)),
    );
    as(DemoAccounts.viewer);
    expect(() => platform.raiseHand(live), throwsA(isA<ForbiddenFailure>()));
  });

  test('sólo el host banea, y el baneo vale para todos sus vivos', () {
    platform.assignModerator(live, DemoAccounts.viewer.id);
    as(DemoAccounts.viewer);
    expect(
      () => platform.banFromHost(live, DemoAccounts.troll.id),
      throwsA(isA<ForbiddenFailure>()),
    );

    as(DemoAccounts.elena);
    platform.banFromHost(live, DemoAccounts.troll.id);
    expect(
      platform.exclusion('live-2', DemoAccounts.troll.id),
      LiveSanctionKind.ban,
    );

    platform.unbanFromHost(DemoAccounts.troll.id);
    expect(platform.exclusion('live-2', DemoAccounts.troll.id), isNull);
  });

  test('ocultar es reversible y borrar no', () {
    as(DemoAccounts.troll);
    final hidden = platform.postComment(live, 'uh');
    final deleted = platform.postComment(live, 'basura');

    as(DemoAccounts.elena);
    platform
      ..hideComment(live, hidden.id)
      ..deleteComment(live, deleted.id)
      ..unhideComment(live, hidden.id)
      ..unhideComment(live, deleted.id);

    final ids = platform.comments(live).map((c) => c.id);
    expect(ids, contains(hidden.id));
    expect(ids, isNot(contains(deleted.id)));
  });

  test('el moderador no toca al host', () {
    as(DemoAccounts.elena);
    final mine = platform.postComment(live, 'hola');
    platform.assignModerator(live, DemoAccounts.viewer.id);

    as(DemoAccounts.viewer);
    expect(
      () => platform.deleteComment(live, mine.id),
      throwsA(isA<ForbiddenFailure>()),
    );
    expect(
      () => platform.kick(live, DemoAccounts.elena.id),
      throwsA(isA<ForbiddenFailure>()),
    );
  });

  test('borrar un mensaje fijado lo despega', () {
    as(DemoAccounts.troll);
    final message = platform.postComment(live, 'link');
    as(DemoAccounts.elena);
    platform.pinComment(live, message.id);
    expect(platform.pinnedComment(live)?.id, message.id);

    platform.deleteComment(live, message.id);
    expect(platform.pinnedComment(live), isNull);
  });

  test('un invitado destaca preguntas pero no fija', () {
    platform.inviteToStage(live, DemoAccounts.viewer.id);
    as(DemoAccounts.troll);
    final question = platform.postComment(live, '¿Qué plugin usás?');

    as(DemoAccounts.viewer);
    platform.highlightQuestion(live, question.id);
    expect(platform.highlightedComment(live)?.id, question.id);
    expect(
      () => platform.pinComment(live, question.id),
      throwsA(isA<ForbiddenFailure>()),
    );
  });
}
