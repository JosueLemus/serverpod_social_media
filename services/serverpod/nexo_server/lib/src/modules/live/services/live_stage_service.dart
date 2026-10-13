import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../../shared/audit/audit_service.dart';
import '../../../shared/auth/auth_context.dart';
import '../../../shared/profiles/avatar_lookup.dart';
import '../../../shared/profiles/profile_lookup.dart';
import '../../identity/services/identity_service.dart';
import 'live_permissions.dart';
import 'live_rules.dart';
import 'live_sanctions.dart';

/// El escenario de una sala (SDD 0011, Etapa 2): quién habla, quién pidió la
/// palabra, y subir y bajar gente.
///
/// Cada cambio corre en una transacción que bloquea la fila del show —así dos
/// aprobaciones simultáneas no pasan el cupo de 16—, deja su auditoría si es
/// una acción sobre otra persona (S13), y se publica **después** del commit:
/// el escenario completo para todos y, si cambió un rol, un `roleChanged`
/// para que la app de esa persona se entere.
class LiveStageService {
  LiveStageService({
    this._identity = const IdentityService(),
    this._audit = const AuditService(),
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc());

  final IdentityService _identity;
  final AuditService _audit;
  final DateTime Function() _now;

  // --- Roles ---------------------------------------------------------------

  /// El rol de [userId] en [show]. El host es el host; el staff de Nexo es
  /// moderador en cualquier vivo (S7); después manda la fila de la sala, y sin
  /// fila, un invitado de la agenda que no rechazó es invitado. No hay todavía
  /// un paso de "aceptar" la invitación: todo invitado queda en `invited`, y
  /// filtrar por `accepted` dejaba a la agenda entera abajo.
  ///
  /// [isStaff] es sólo para quien hace el pedido: de otra persona no se sabe
  /// si es staff sin leer sus scopes, y para la regla de rango alcanza con su
  /// lugar en la sala.
  Future<LiveShowRole> roleOf(
    Session session,
    LiveShow show,
    UuidValue? userId, {
    bool isStaff = false,
    Transaction? transaction,
  }) async {
    if (userId == null) return LiveShowRole.audience;
    if (show.hostId == userId) return LiveShowRole.host;
    if (isStaff) return LiveShowRole.moderator;
    final row = await _row(session, show.id!, userId, transaction);
    if (row != null) return row.role;
    final guest = await LiveShowGuest.db.count(
      session,
      where: (t) =>
          t.showId.equals(show.id) &
          t.userId.equals(userId) &
          t.status.notEquals(LiveShowGuestStatus.declined),
      transaction: transaction,
    );
    return guest > 0 ? LiveShowRole.cohost : LiveShowRole.audience;
  }

  /// Si [userId] está en el escenario. Es lo que decide quién publica audio y
  /// video en `mediaToken`.
  Future<bool> isOnStage(Session session, int showId, UuidValue userId) async =>
      (await _row(session, showId, userId, null))?.onStage ?? false;

  /// Al salir al aire: el host sube primero y, detrás, los invitados de la
  /// agenda que no rechazaron. Corre dentro de la transacción del cambio de
  /// estado, así que un show al aire nunca existe sin su escenario.
  Future<void> seedOnAir(
    Session session,
    LiveShow show,
    Transaction transaction,
  ) async {
    final guests = await LiveShowGuest.db.find(
      session,
      where: (t) =>
          t.showId.equals(show.id) &
          t.status.notEquals(LiveShowGuestStatus.declined),
      orderBy: (t) => t.id,
      transaction: transaction,
    );
    final rows = [
      _fresh(show.id!, show.hostId, LiveShowRole.host, onStage: true),
      for (final g in guests.take(LiveRules.maxGuests))
        _fresh(show.id!, g.userId, LiveShowRole.cohost, onStage: true),
    ];
    for (final row in rows) {
      final existing = await _row(session, show.id!, row.userId, transaction);
      if (existing == null) {
        await LiveParticipant.db.insertRow(
          session,
          row,
          transaction: transaction,
        );
      }
    }
  }

  // --- Lectura -------------------------------------------------------------

  Future<LiveStageView> view(
    Session session,
    int showId, {
    Transaction? transaction,
  }) async {
    final rows = await LiveParticipant.db.find(
      session,
      where: (t) =>
          t.showId.equals(showId) &
          (t.onStage.equals(true) | t.handRaisedAt.notEquals(null)),
      orderBy: (t) => t.id,
      transaction: transaction,
    );
    final ids = rows.map((r) => r.userId);
    final profiles = await profilesOf(session, ids);
    final avatars = await avatarsOf(session, ids);

    final speakers = rows.where((r) => r.onStage).toList()
      ..sort((a, b) {
        // El host siempre primero; el resto, por orden de llegada a la sala.
        final host =
            (b.role == LiveShowRole.host ? 1 : 0) -
            (a.role == LiveShowRole.host ? 1 : 0);
        return host != 0 ? host : a.id!.compareTo(b.id!);
      });
    final hands =
        rows.where((r) => !r.onStage && r.handRaisedAt != null).toList()
          ..sort((a, b) => a.handRaisedAt!.compareTo(b.handRaisedAt!));

    return LiveStageView(
      speakers: [
        for (final r in speakers)
          LiveSpeakerView(
            userId: r.userId,
            username: profiles[r.userId]?.userName,
            name: profiles[r.userId]?.fullName,
            avatarUrl: avatars[r.userId],
            role: r.role,
            micMuted: r.micMuted,
            cameraOn: r.cameraOn,
          ),
      ],
      hands: [
        for (final r in hands)
          LiveHandView(
            userId: r.userId,
            username: profiles[r.userId]?.userName,
            name: profiles[r.userId]?.fullName,
            avatarUrl: avatars[r.userId],
            raisedAt: r.handRaisedAt!,
          ),
      ],
    );
  }

  // --- Acciones sobre uno mismo ---------------------------------------------

  /// Pedir la palabra. Si ya la había pedido, conserva su lugar en la cola.
  Future<void> raiseHand(Session session, int showId) => _change(
    session,
    showId,
    (show, actor, role, tx) async {
      _require(role, LiveAction.raiseHand);
      final row = await _row(session, showId, actor, tx);
      if (row?.onStage ?? false) {
        throw _error(NexoErrorCode.conflict, 'Ya estás en el escenario.');
      }
      if (row?.handRaisedAt != null) return const [];
      await _save(
        session,
        row ?? _fresh(showId, actor, role),
        (r) => r.copyWith(handRaisedAt: _now()),
        tx,
      );
      return const [];
    },
  );

  Future<void> lowerHand(Session session, int showId) => _change(
    session,
    showId,
    (show, actor, role, tx) async {
      final row = await _row(session, showId, actor, tx);
      if (row?.handRaisedAt == null) return const [];
      await _save(session, row!, (r) => r.copyWith(handRaisedAt: null), tx);
      return const [];
    },
  );

  /// Bajarse del escenario. Un invitado vuelve a ser oyente; un moderador
  /// sigue siendo moderador (S5).
  Future<void> leaveStage(Session session, int showId) => _change(
    session,
    showId,
    (show, actor, role, tx) async {
      _require(role, LiveAction.leaveStage);
      final row = await _row(session, showId, actor, tx);
      if (row == null || !row.onStage) return const [];
      return [await _offStage(session, row, tx)];
    },
  );

  /// El micrófono propio, o el de otro para **silenciarlo**. Volver a
  /// activar el de otro no se puede: es suave, el invitado lo reactiva él
  /// mismo (S11).
  Future<void> setMicMuted(
    Session session,
    int showId,
    UuidValue userId,
    bool muted,
  ) => _change(session, showId, (show, actor, role, tx) async {
    if (userId == actor) {
      _require(role, LiveAction.speak);
    } else {
      if (!muted) {
        throw _error(
          NexoErrorCode.forbidden,
          'Sólo esa persona puede volver a activar su micrófono.',
        );
      }
      await _requireOver(session, show, role, LiveAction.muteMic, userId, tx);
    }
    final row = await _row(session, showId, userId, tx);
    if (row == null || !row.onStage) {
      throw _error(NexoErrorCode.conflict, 'No está en el escenario.');
    }
    if (row.micMuted == muted) return const [];
    await _save(session, row, (r) => r.copyWith(micMuted: muted), tx);
    if (userId != actor) {
      await _record(session, actor, 'live.stage.muteMic', showId, userId, tx);
    }
    return const [];
  });

  Future<void> setCamera(Session session, int showId, bool on) => _change(
    session,
    showId,
    (show, actor, role, tx) async {
      _require(role, LiveAction.speak);
      final row = await _row(session, showId, actor, tx);
      if (row == null || !row.onStage) {
        throw _error(NexoErrorCode.conflict, 'No estás en el escenario.');
      }
      if (row.cameraOn == on) return const [];
      await _save(session, row, (r) => r.copyWith(cameraOn: on), tx);
      return const [];
    },
  );

  // --- Acciones sobre otra persona -----------------------------------------

  /// Sube a alguien que pidió la palabra.
  Future<void> approveRequest(Session session, int showId, UuidValue userId) =>
      _change(session, showId, (show, actor, role, tx) async {
        await _requireOver(
          session,
          show,
          role,
          LiveAction.approveRequest,
          userId,
          tx,
        );
        final row = await _row(session, showId, userId, tx);
        if (row?.handRaisedAt == null) {
          throw _error(NexoErrorCode.conflict, 'No pidió la palabra.');
        }
        final change = await _onStage(session, row!, tx);
        await _record(session, actor, 'live.stage.approve', showId, userId, tx);
        return [?change];
      });

  /// Rechaza un pedido de palabra: la persona sigue en la sala, sin la mano
  /// levantada.
  Future<void> denyRequest(Session session, int showId, UuidValue userId) =>
      _change(session, showId, (show, actor, role, tx) async {
        await _requireOver(
          session,
          show,
          role,
          LiveAction.approveRequest,
          userId,
          tx,
        );
        final row = await _row(session, showId, userId, tx);
        if (row?.handRaisedAt == null) return const [];
        await _save(session, row!, (r) => r.copyWith(handRaisedAt: null), tx);
        await _record(session, actor, 'live.stage.deny', showId, userId, tx);
        return const [];
      });

  /// Sube a alguien directo, haya pedido la palabra o no. Sólo el host.
  Future<void> inviteToStage(Session session, int showId, UuidValue userId) =>
      _change(session, showId, (show, actor, role, tx) async {
        await _requireOver(
          session,
          show,
          role,
          LiveAction.inviteToStage,
          userId,
          tx,
        );
        final account = await AccountProfile.db.findFirstRow(
          session,
          where: (t) => t.authUserId.equals(userId),
          transaction: tx,
        );
        if (account == null) {
          throw _error(NexoErrorCode.notFound, 'La cuenta no existe.');
        }
        if (account.status != AccountStatus.active) {
          throw _error(
            NexoErrorCode.forbidden,
            'Esa cuenta no puede participar ahora.',
          );
        }
        final target = await roleOf(session, show, userId, transaction: tx);
        final row =
            await _row(session, showId, userId, tx) ??
            await LiveParticipant.db.insertRow(
              session,
              _fresh(showId, userId, target),
              transaction: tx,
            );
        if (row.onStage) return const [];
        final change = await _onStage(session, row, tx);
        await _record(session, actor, 'live.stage.invite', showId, userId, tx);
        return [?change];
      });

  /// Baja a alguien del escenario. Sólo el host.
  Future<void> removeFromStage(
    Session session,
    int showId,
    UuidValue userId,
  ) => _change(session, showId, (show, actor, role, tx) async {
    await _requireOver(
      session,
      show,
      role,
      LiveAction.removeFromStage,
      userId,
      tx,
    );
    final row = await _row(session, showId, userId, tx);
    if (row == null || !row.onStage) return const [];
    final change = await _offStage(session, row, tx);
    await _record(session, actor, 'live.stage.remove', showId, userId, tx);
    return [change];
  });

  // --- Internos ------------------------------------------------------------

  /// El esqueleto de toda acción: sesión activa, show al aire y bloqueado,
  /// [body] dentro de la transacción y la publicación después del commit.
  /// [body] devuelve los cambios de rol a avisar.
  Future<void> _change(
    Session session,
    int showId,
    Future<List<LiveEvent>> Function(
      LiveShow show,
      UuidValue actor,
      LiveShowRole role,
      Transaction tx,
    )
    body,
  ) async {
    final actor = session.requireUserId;
    await _identity.requireActive(session, actor);
    final roleChanges = await session.db.transaction((tx) async {
      final show = await LiveShow.db.findById(
        session,
        showId,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (show == null || show.status == LiveShowStatus.removed) {
        throw _error(NexoErrorCode.notFound, 'El show no existe.');
      }
      if (show.status != LiveShowStatus.live) {
        throw _error(NexoErrorCode.conflict, 'El show no está al aire.');
      }
      await LiveSanctions.requireAdmitted(
        session,
        show,
        actor,
        transaction: tx,
      );
      final role = await roleOf(
        session,
        show,
        actor,
        isStaff: session.isStaff,
        transaction: tx,
      );
      return body(show, actor, role, tx);
    });

    final channel = LiveChannels.show(showId);
    await session.messages.postMessage(
      channel,
      LiveEvent(kind: LiveEventKind.stage, stage: await view(session, showId)),
    );
    for (final event in roleChanges) {
      await session.messages.postMessage(channel, event);
    }
  }

  /// Sube [row] al escenario si hay lugar. Devuelve el `roleChanged` si su
  /// rol cambió (un oyente pasa a invitado; un moderador sigue moderador).
  Future<LiveEvent?> _onStage(
    Session session,
    LiveParticipant row,
    Transaction tx,
  ) async {
    final taken = await LiveParticipant.db.count(
      session,
      where: (t) =>
          t.showId.equals(row.showId) &
          t.onStage.equals(true) &
          t.role.notEquals(LiveShowRole.host),
      transaction: tx,
    );
    if (LiveRules.stageFull(taken)) {
      throw _error(
        NexoErrorCode.conflict,
        'El escenario está lleno: ${LiveRules.maxGuests} invitados.',
      );
    }
    final role = row.role == LiveShowRole.moderator
        ? LiveShowRole.moderator
        : LiveShowRole.cohost;
    await _save(
      session,
      row,
      (r) => r.copyWith(
        onStage: true,
        handRaisedAt: null,
        micMuted: false,
        cameraOn: false,
        role: role,
      ),
      tx,
    );
    return role == row.role ? null : _roleChanged(row.userId, role);
  }

  Future<LiveEvent> _offStage(
    Session session,
    LiveParticipant row,
    Transaction tx,
  ) async {
    final role = row.role == LiveShowRole.moderator
        ? LiveShowRole.moderator
        : LiveShowRole.audience;
    await _save(
      session,
      row,
      (r) => r.copyWith(
        onStage: false,
        micMuted: false,
        cameraOn: false,
        role: role,
      ),
      tx,
    );
    return _roleChanged(row.userId, role);
  }

  LiveEvent _roleChanged(UuidValue userId, LiveShowRole role) => LiveEvent(
    kind: LiveEventKind.roleChanged,
    targetId: userId,
    role: role,
  );

  /// La regla de rango (S1) con el rol de la persona sobre la que recae.
  Future<void> _requireOver(
    Session session,
    LiveShow show,
    LiveShowRole actorRole,
    LiveAction action,
    UuidValue target,
    Transaction tx,
  ) async {
    final targetRole = await roleOf(session, show, target, transaction: tx);
    if (!LivePermissions.can(actorRole, action, target: targetRole)) {
      throw _error(
        NexoErrorCode.forbidden,
        'Tu rol en la sala no permite esto sobre esa persona.',
      );
    }
  }

  void _require(LiveShowRole role, LiveAction action) {
    if (!LivePermissions.can(role, action)) {
      throw _error(
        NexoErrorCode.forbidden,
        'Tu rol en la sala no permite esto.',
      );
    }
  }

  Future<LiveParticipant?> _row(
    Session session,
    int showId,
    UuidValue userId,
    Transaction? transaction,
  ) => LiveParticipant.db.findFirstRow(
    session,
    where: (t) => t.showId.equals(showId) & t.userId.equals(userId),
    transaction: transaction,
  );

  LiveParticipant _fresh(
    int showId,
    UuidValue userId,
    LiveShowRole role, {
    bool onStage = false,
  }) => LiveParticipant(
    showId: showId,
    userId: userId,
    role: role,
    onStage: onStage,
    micMuted: false,
    cameraOn: false,
    updatedAt: _now(),
  );

  /// Guarda [row] con [change] aplicado. Si la fila todavía no existe, la
  /// inserta.
  Future<void> _save(
    Session session,
    LiveParticipant row,
    LiveParticipant Function(LiveParticipant) change,
    Transaction tx,
  ) async {
    final next = change(row).copyWith(updatedAt: _now());
    if (row.id == null) {
      await LiveParticipant.db.insertRow(session, next, transaction: tx);
    } else {
      await LiveParticipant.db.updateRow(session, next, transaction: tx);
    }
  }

  Future<void> _record(
    Session session,
    UuidValue actor,
    String action,
    int showId,
    UuidValue target,
    Transaction tx,
  ) => _audit.record(
    session,
    actorId: actor,
    action: action,
    entityType: 'liveShow',
    entityId: '$showId',
    metadata: {'target': target.uuid},
    transaction: tx,
  );

  static NexoException _error(NexoErrorCode code, String message) =>
      NexoException(code: code, message: message);
}
