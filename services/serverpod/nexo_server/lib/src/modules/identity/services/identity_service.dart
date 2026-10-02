import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../../../generated/protocol.dart';
import '../../../shared/audit/audit_service.dart';
import '../../../shared/auth/auth_context.dart';
import 'username_rules.dart';

/// El perfil de Nexo de cada cuenta: nombre de usuario, si crea contenido,
/// su verificación y su estado.
class IdentityService {
  const IdentityService({this._audit = const AuditService()});

  final AuditService _audit;

  /// La cuenta de la sesión. La primera vez crea su perfil de Nexo con un
  /// nombre de usuario libre derivado del correo, así que una cuenta recién
  /// registrada nunca aparece como un id.
  Future<AccountView> me(Session session) async {
    final userId = session.requireUserId;
    final account = await ensure(session, userId);
    final user = await _userProfile(session, userId);
    return AccountView(
      profile: _view(account, user),
      email: user?.email,
      isModerator: session.hasScope(NexoScopes.moderator),
      isAdmin: session.hasScope(NexoScopes.admin),
    );
  }

  Future<ProfileView> byUsername(Session session, String username) async {
    final account = await AccountProfile.db.findFirstRow(
      session,
      where: (t) => t.username.equals(UsernameRules.normalize(username)),
    );
    if (account == null) {
      throw _error(NexoErrorCode.notFound, 'Ese perfil no existe.');
    }
    return _view(account, await _userProfile(session, account.authUserId));
  }

  Future<AccountView> update(Session session, ProfileEdit edit) async {
    final userId = session.requireUserId;
    await ensure(session, userId);

    final username = edit.username == null
        ? null
        : UsernameRules.normalize(edit.username!);
    if (username != null) {
      final problem = UsernameRules.problemWith(username);
      if (problem != null) throw _error(NexoErrorCode.invalidInput, problem);
    }
    final displayName = edit.displayName?.trim();
    if (displayName != null &&
        (displayName.isEmpty ||
            displayName.length > UsernameRules.maxDisplayNameLength)) {
      throw _error(
        NexoErrorCode.invalidInput,
        'El nombre debe tener entre 1 y '
        '${UsernameRules.maxDisplayNameLength} caracteres.',
      );
    }
    final bio = edit.bio?.trim();
    if (bio != null && bio.length > UsernameRules.maxBioLength) {
      throw _error(
        NexoErrorCode.invalidInput,
        'La bio supera los ${UsernameRules.maxBioLength} caracteres.',
      );
    }

    await session.db.transaction((tx) async {
      final account = (await AccountProfile.db.findFirstRow(
        session,
        where: (t) => t.authUserId.equals(userId),
        transaction: tx,
        lockMode: LockMode.forUpdate,
      ))!;

      if (username != null && username != account.username) {
        final taken = await AccountProfile.db.count(
          session,
          where: (t) => t.username.equals(username),
          transaction: tx,
        );
        if (taken > 0) {
          throw _error(
            NexoErrorCode.conflict,
            'Ese nombre de usuario ya está en uso.',
          );
        }
      }

      await AccountProfile.db.updateRow(
        session,
        account.copyWith(
          username: username ?? account.username,
          bio: bio == null ? account.bio : (bio.isEmpty ? null : bio),
          updatedAt: DateTime.now().toUtc(),
        ),
        transaction: tx,
      );
      await _syncUserProfile(
        session,
        userId,
        userName: username,
        fullName: displayName,
        transaction: tx,
      );
    });
    return me(session);
  }

  /// Declara la cuenta como creadora. No la verifica: verificar es decisión
  /// del operador, y es lo que habilita a transmitir.
  Future<AccountView> becomeCreator(Session session) async {
    final userId = session.requireUserId;
    final account = await ensure(session, userId);
    if (!account.isCreator) {
      await session.db.transaction((tx) async {
        await AccountProfile.db.updateRow(
          session,
          account.copyWith(isCreator: true, updatedAt: DateTime.now().toUtc()),
          transaction: tx,
        );
        await _audit.record(
          session,
          actorId: userId,
          action: 'identity.becomeCreator',
          entityType: 'account',
          entityId: '$userId',
          transaction: tx,
        );
      });
    }
    return me(session);
  }

  /// El perfil de Nexo de [userId], creándolo si todavía no existe.
  Future<AccountProfile> ensure(Session session, UuidValue userId) async {
    final existing = await _account(session, userId);
    if (existing != null) return existing;

    final user = await _userProfile(session, userId);
    final base = UsernameRules.suggestFrom(user?.userName ?? user?.email);
    try {
      return await session.db.transaction((tx) async {
        final username = await _freeUsername(session, base, tx);
        final created = await AccountProfile.db.insertRow(
          session,
          AccountProfile(authUserId: userId, username: username),
          transaction: tx,
        );
        await _syncUserProfile(
          session,
          userId,
          userName: username,
          transaction: tx,
        );
        return created;
      });
    } on DatabaseQueryException {
      // Dos pedidos simultáneos de la misma cuenta nueva: el índice único lo
      // frenó y el otro ya lo creó.
      final raced = await _account(session, userId);
      if (raced != null) return raced;
      rethrow;
    }
  }

  // --- Internos ------------------------------------------------------------

  Future<AccountProfile?> _account(Session session, UuidValue userId) =>
      AccountProfile.db.findFirstRow(
        session,
        where: (t) => t.authUserId.equals(userId),
      );

  Future<UserProfile?> _userProfile(Session session, UuidValue userId) =>
      UserProfile.db.findFirstRow(
        session,
        where: (t) => t.authUserId.equals(userId),
        include: UserProfile.include(image: UserProfileImage.include()),
      );

  Future<String> _freeUsername(
    Session session,
    String base,
    Transaction tx,
  ) async {
    final taken = {
      for (final row in await AccountProfile.db.find(
        session,
        where: (t) => t.username.like('$base%'),
        transaction: tx,
      ))
        row.username,
    };
    if (!taken.contains(base)) return base;
    for (var suffix = 1; ; suffix++) {
      final candidate = '${base}_$suffix';
      if (!taken.contains(candidate)) return candidate;
    }
  }

  /// Copia el nombre al `UserProfile` de Serverpod, que es de donde lo leen
  /// los módulos que muestran autores (`profilesOf`).
  Future<void> _syncUserProfile(
    Session session,
    UuidValue userId, {
    String? userName,
    String? fullName,
    required Transaction transaction,
  }) async {
    if (userName == null && fullName == null) return;
    final profile = await UserProfile.db.findFirstRow(
      session,
      where: (t) => t.authUserId.equals(userId),
      transaction: transaction,
    );
    if (profile == null) return;
    await UserProfile.db.updateRow(
      session,
      profile.copyWith(
        userName: userName ?? profile.userName,
        fullName: fullName ?? profile.fullName,
      ),
      transaction: transaction,
    );
  }

  ProfileView _view(AccountProfile account, UserProfile? user) => ProfileView(
    userId: account.authUserId,
    username: account.username,
    displayName: (user?.fullName?.trim().isNotEmpty ?? false)
        ? user!.fullName!.trim()
        : account.username,
    bio: account.bio,
    avatarUrl: user?.image?.url.toString(),
    isCreator: account.isCreator,
    verification: account.verification,
    status: account.status,
    createdAt: account.createdAt,
  );

  static NexoException _error(NexoErrorCode code, String message) =>
      NexoException(code: code, message: message);
}
