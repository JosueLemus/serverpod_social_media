import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../../../generated/protocol.dart';
import '../../../shared/auth/auth_context.dart';
import '../../content/services/post_rules.dart';
import '../../identity/services/identity_service.dart';
import '../../notifications/services/notification_service.dart';

/// Seguir y dejar de seguir. Las dos operaciones son idempotentes: repetir la
/// llamada deja el mismo estado, así que un doble toque o un reintento de red
/// no descuadra los contadores.
class FollowService {
  const FollowService({
    this._identity = const IdentityService(),
    this._notifications = const NotificationService(),
  });

  static const defaultSuggestions = 10;
  static const maxSuggestions = 20;

  final IdentityService _identity;
  final NotificationService _notifications;

  Future<FollowState> follow(Session session, UuidValue userId) =>
      _set(session, userId, follow: true);

  Future<FollowState> unfollow(Session session, UuidValue userId) =>
      _set(session, userId, follow: false);

  /// Quién sigue a [userId], del más reciente al más viejo.
  Future<FollowPage> followers(
    Session session,
    UuidValue userId, {
    PageCursor? after,
    int? limit,
  }) => _page(session, userId, followersOf: true, after: after, limit: limit);

  /// A quién sigue [userId], del más reciente al más viejo.
  Future<FollowPage> following(
    Session session,
    UuidValue userId, {
    PageCursor? after,
    int? limit,
  }) => _page(session, userId, followersOf: false, after: after, limit: limit);

  /// Creadores verificados y activos que la sesión todavía no sigue, por
  /// cantidad de seguidores. Sin sesión, los más seguidos.
  Future<List<ProfileView>> suggestions(Session session, {int? limit}) async {
    final size = (limit ?? defaultSuggestions).clamp(1, maxSuggestions);
    final viewer = session.userIdOrNull;
    final excluded = {
      ?viewer,
      if (viewer != null) ...await followeesOf(session, viewer),
    };
    final accounts = await AccountProfile.db.find(
      session,
      where: (t) {
        var where =
            t.isCreator.equals(true) &
            t.verification.equals(VerificationStatus.verified) &
            t.status.equals(AccountStatus.active);
        if (excluded.isNotEmpty) {
          where = where & t.authUserId.notInSet(excluded);
        }
        return where;
      },
      orderByList: (t) => [t.followerCount.desc(), t.username.asc()],
      limit: size,
    );
    return _identity.viewsOf(session, accounts);
  }

  // --- Para otros módulos --------------------------------------------------

  /// Las cuentas que sigue [userId]. Lo usan el feed y la visibilidad
  /// `followers` de los posts.
  Future<Set<UuidValue>> followeesOf(
    Session session,
    UuidValue userId, {
    Transaction? transaction,
  }) async => {
    for (final row in await Follow.db.find(
      session,
      where: (t) => t.followerId.equals(userId),
      transaction: transaction,
    ))
      row.followeeId,
  };

  /// Quién sigue a [userId]. Lo usan las notificaciones de un vivo.
  Future<List<UuidValue>> followerIdsOf(
    Session session,
    UuidValue userId, {
    Transaction? transaction,
  }) async => [
    for (final row in await Follow.db.find(
      session,
      where: (t) => t.followeeId.equals(userId),
      transaction: transaction,
    ))
      row.followerId,
  ];

  // --- Internos ------------------------------------------------------------

  /// Bloquea las dos cuentas en orden fijo: si A sigue a B mientras B sigue a
  /// A, las dos transacciones piden los locks en el mismo orden y ninguna
  /// espera a la otra para siempre.
  Future<FollowState> _set(
    Session session,
    UuidValue followeeId, {
    required bool follow,
  }) async {
    final followerId = session.requireUserId;
    if (follow) {
      if (followerId == followeeId) {
        throw _error(NexoErrorCode.invalidInput, 'No podés seguirte.');
      }
      await _identity.requireActive(session, followerId);
    } else {
      await _identity.ensure(session, followerId);
    }
    await _requireAccount(session, followeeId);

    var notices = const <UserNotification>[];
    final state = await session.db.transaction((tx) async {
      final locked = <UuidValue, AccountProfile>{};
      final ordered = [followerId, followeeId]
        ..sort((a, b) => '$a'.compareTo('$b'));
      for (final id in ordered.toSet()) {
        locked[id] = (await AccountProfile.db.findFirstRow(
          session,
          where: (t) => t.authUserId.equals(id),
          transaction: tx,
          lockMode: LockMode.forUpdate,
        ))!;
      }

      final existing = await Follow.db.findFirstRow(
        session,
        where: (t) =>
            t.followerId.equals(followerId) & t.followeeId.equals(followeeId),
        transaction: tx,
      );

      var delta = 0;
      if (follow && existing == null) {
        await Follow.db.insertRow(
          session,
          Follow(followerId: followerId, followeeId: followeeId),
          transaction: tx,
        );
        delta = 1;
      } else if (!follow && existing != null) {
        await Follow.db.deleteRow(session, existing, transaction: tx);
        delta = -1;
      }

      final followee = locked[followeeId]!;
      if (delta != 0) {
        final follower = locked[followerId]!;
        await AccountProfile.db.updateRow(
          session,
          follower.copyWith(
            followingCount: _floor(follower.followingCount + delta),
          ),
          columns: (t) => [t.followingCount],
          transaction: tx,
        );
        await AccountProfile.db.updateRow(
          session,
          followee.copyWith(
            followerCount: _floor(followee.followerCount + delta),
          ),
          columns: (t) => [t.followerCount],
          transaction: tx,
        );
      }
      if (delta > 0) {
        notices = await _notifications.create(
          session,
          recipients: [followeeId],
          kind: NotificationKind.newFollower,
          actorId: followerId,
          transaction: tx,
        );
      }

      return FollowState(
        userId: followeeId,
        viewerFollows: follow,
        followerCount: _floor(followee.followerCount + delta),
      );
    });
    await _notifications.publish(session, notices);
    return state;
  }

  Future<FollowPage> _page(
    Session session,
    UuidValue userId, {
    required bool followersOf,
    PageCursor? after,
    int? limit,
  }) async {
    await _requireAccount(session, userId);
    final size = PostRules.pageSize(limit);
    final rows = await Follow.db.find(
      session,
      where: (t) {
        var where = followersOf
            ? t.followeeId.equals(userId)
            : t.followerId.equals(userId);
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
    );

    final hasMore = rows.length > size;
    final items = hasMore ? rows.sublist(0, size) : rows;
    final ids = [
      for (final row in items) followersOf ? row.followerId : row.followeeId,
    ];
    final accounts = {
      for (final account in await AccountProfile.db.find(
        session,
        where: (t) => t.authUserId.inSet(ids.toSet()),
      ))
        account.authUserId: account,
    };
    return FollowPage(
      items: await _identity.viewsOf(session, [
        for (final id in ids) ?accounts[id],
      ]),
      nextCursor: hasMore
          ? PageCursor(createdAt: items.last.createdAt, id: items.last.id!)
          : null,
    );
  }

  /// La cuenta de Nexo de [userId]. Una cuenta de Serverpod que todavía no
  /// abrió la app no tiene perfil: se crea, como hace `profiles.me`.
  Future<AccountProfile> _requireAccount(
    Session session,
    UuidValue userId,
  ) async {
    final account = await AccountProfile.db.findFirstRow(
      session,
      where: (t) => t.authUserId.equals(userId),
    );
    if (account != null) return account;
    if (await AuthUser.db.findById(session, userId) == null) {
      throw _error(NexoErrorCode.notFound, 'Ese perfil no existe.');
    }
    return _identity.ensure(session, userId);
  }

  /// Un contador nunca baja de cero, aunque una fila se haya borrado a mano.
  static int _floor(int value) => value < 0 ? 0 : value;

  static NexoException _error(NexoErrorCode code, String message) =>
      NexoException(code: code, message: message);
}
