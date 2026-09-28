import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/core/mock/mock_platform.dart';
import 'package:nexo_social/features/admin/domain/entities/audit_entry.dart';
import 'package:nexo_social/features/auth/domain/entities/app_user.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';
import 'package:nexo_social/features/moderation/domain/entities/moderation_action.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/platform_harness.dart';

/// Las reglas del servidor falso. Son las mismas que va a tener Serverpod,
/// así que estos tests son también la especificación del backend.
void main() {
  late MockPlatform platform;

  setUp(() async => platform = await platformAs(DemoAccounts.operator.id));
  tearDown(() => platform.dispose());

  final elena = DemoAccounts.elena.id;
  final troll = DemoAccounts.troll.id;

  group('el gate de vivos', () {
    test('un creador verificado inicia su vivo', () {
      platform.bindSession(elena);

      final live = platform.transitionLive('live-2', LiveStatus.live);

      expect(live.status, LiveStatus.live);
    });

    test('un creador desverificado es rechazado por el servidor', () {
      platform.setVerification(
        elena,
        verified: false,
        reason: ModerationReason.impersonation,
      );
      platform.bindSession(elena);

      expect(
        () => platform.transitionLive('live-2', LiveStatus.live),
        throwsA(isA<CreatorNotVerifiedFailure>()),
      );
      expect(platform.live('live-2')!.status, LiveStatus.scheduled);
    });

    test('restaurar la verificación vuelve a habilitarlo', () {
      platform
        ..setVerification(
          elena,
          verified: false,
          reason: ModerationReason.impersonation,
        )
        ..setVerification(elena, verified: true)
        ..bindSession(elena);

      expect(
        platform.transitionLive('live-2', LiveStatus.live).status,
        LiveStatus.live,
      );
    });

    test('nadie inicia el vivo de otro', () {
      platform.bindSession(DemoAccounts.carlos.id);

      expect(
        () => platform.transitionLive('live-2', LiveStatus.live),
        throwsA(isA<ForbiddenFailure>()),
      );
    });

    test('una transición ilegal desde el estado actual es un conflicto', () {
      platform.bindSession(elena);

      expect(
        () => platform.transitionLive('live-2', LiveStatus.published),
        throwsA(isA<ConflictFailure>()),
      );
    });
  });

  group('suspender', () {
    test('la cuenta suspendida no opera ni vuelve a entrar', () {
      platform.suspend(troll, ModerationReason.harassment);

      platform.bindSession(troll);
      expect(
        () => platform.postComment('live-1', 'hola'),
        throwsA(isA<AccountSuspendedFailure>()),
      );
      expect(
        () => platform.signIn(troll),
        throwsA(isA<AccountSuspendedFailure>()),
      );
    });

    test('restaurar la devuelve a activa; un baneo no se restaura', () {
      platform
        ..suspend(troll, ModerationReason.harassment)
        ..restore(troll);
      expect(platform.accountById(troll)!.status, AccountStatus.active);

      platform.ban(troll, ModerationReason.harassment);
      expect(() => platform.restore(troll), throwsA(isA<ConflictFailure>()));
    });

    test('un operador no puede sancionar a otro operador ni a sí mismo', () {
      expect(
        () =>
            platform.suspend(DemoAccounts.operator.id, ModerationReason.other),
        throwsA(isA<ForbiddenFailure>()),
      );
    });
  });

  group('el permiso vive acá, no en la pantalla', () {
    test('una cuenta común no lee la consola', () {
      platform.bindSession(DemoAccounts.viewer.id);

      expect(
        () => platform.searchAccounts(''),
        throwsA(isA<ForbiddenFailure>()),
      );
      expect(
        () => platform.suspend(troll, ModerationReason.spam),
        throwsA(isA<ForbiddenFailure>()),
      );
    });

    test('un moderador lee la cola pero no la consola', () {
      platform.bindSession(DemoAccounts.moderator.id);

      expect(platform.openReports(), isNotEmpty);
      expect(
        () => platform.audit(const AuditFilter()),
        throwsA(isA<ForbiddenFailure>()),
      );
    });
  });

  group('la auditoría', () {
    test('cada acción queda registrada con actor, motivo y objetivo', () {
      platform.suspend(troll, ModerationReason.harassment);

      final entry = platform.audit(const AuditFilter()).items.single;
      expect(entry.action, AuditAction.accountSuspended);
      expect(entry.actor, '@${DemoAccounts.operator.username}');
      expect(entry.target, '@${DemoAccounts.troll.username}');
      expect(entry.reason, ModerationReason.harassment);
    });

    test('una acción que falla no deja registro', () {
      platform.ban(troll, ModerationReason.harassment);
      final before = platform.audit(const AuditFilter()).items.length;

      expect(() => platform.restore(troll), throwsA(isA<ConflictFailure>()));

      expect(platform.audit(const AuditFilter()).items, hasLength(before));
    });

    test('filtra por entidad', () {
      platform
        ..suspend(troll, ModerationReason.harassment)
        ..forceEndLive('live-4', ModerationReason.violence);

      final lives = platform.audit(const AuditFilter(entity: AuditEntity.live));
      expect(lives.items.single.action, AuditAction.liveForceEnded);
    });
  });

  group('resolver un reporte', () {
    test('aplica la acción y cierra el reporte en un paso', () {
      platform.resolveReport(
        'report-1',
        const ModerationDecision(type: ModerationType.hideComment),
      );

      expect(
        platform.openReports().map((report) => report.id),
        isNot(contains('report-1')),
      );
      expect(
        platform.comments('live-1').map((comment) => comment.id),
        isNot(contains('c-troll')),
      );
    });

    test('silenciar 24 h impide comentar', () {
      platform
        ..resolveReport(
          'report-1',
          const ModerationDecision(
            type: ModerationType.muteUser,
            muteFor: MuteDuration.oneDay,
          ),
        )
        ..bindSession(troll);

      expect(
        () => platform.postComment('live-1', 'otra vez'),
        throwsA(isA<MutedFailure>()),
      );
    });

    test('un reporte ya cerrado no se resuelve dos veces', () {
      platform.dismissReport('report-2');

      expect(
        () => platform.resolveReport(
          'report-2',
          const ModerationDecision(type: ModerationType.hideComment),
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });
  });

  test('el estado sobrevive a una nueva instancia (otra pestaña)', () async {
    platform.suspend(troll, ModerationReason.harassment);
    // Deja que termine la escritura que _commit lanza sin esperar.
    await Future<void>.delayed(Duration.zero);

    final other = MockPlatform(await SharedPreferences.getInstance());
    addTearDown(other.dispose);

    expect(other.accountById(troll)!.status, AccountStatus.suspended);
  });
}
