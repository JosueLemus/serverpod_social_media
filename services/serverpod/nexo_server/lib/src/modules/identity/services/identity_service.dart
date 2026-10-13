import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../../../generated/protocol.dart';
import '../../../shared/audit/audit_service.dart';
import '../../../shared/auth/auth_context.dart';
import '../../../shared/gateways/media_storage_gateway.dart';
import '../../../shared/gateways/serverpod_media_storage_gateway.dart';
import '../../../shared/profiles/avatar_lookup.dart';
import 'avatar_policy.dart';
import 'username_rules.dart';

/// El perfil de Nexo de cada cuenta: nombre de usuario, si crea contenido,
/// su verificación y su estado.
class IdentityService {
  const IdentityService({
    this._audit = const AuditService(),
    this._storage = const ServerpodMediaStorageGateway(),
  });

  final AuditService _audit;
  final MediaStorageGateway _storage;

  /// La cuenta de la sesión. La primera vez crea su perfil de Nexo con un
  /// nombre de usuario libre derivado del correo, así que una cuenta recién
  /// registrada nunca aparece como un id.
  Future<AccountView> me(Session session) async {
    final userId = session.requireUserId;
    final account = await ensure(session, userId);
    final user = await _userProfile(session, userId);
    return AccountView(
      profile: (await viewsOf(session, [account])).single,
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
    return (await viewsOf(session, [account])).single;
  }

  /// El perfil público de cada cuenta en [accounts], en el mismo orden, con
  /// `viewerFollows` calculado para la sesión. Una consulta por tabla, nunca
  /// una por cuenta.
  Future<List<ProfileView>> viewsOf(
    Session session,
    List<AccountProfile> accounts,
  ) async {
    if (accounts.isEmpty) return const [];
    final ids = {for (final a in accounts) a.authUserId};
    final users = {
      for (final user in await UserProfile.db.find(
        session,
        where: (t) => t.authUserId.inSet(ids),
        include: UserProfile.include(image: UserProfileImage.include()),
      ))
        user.authUserId: user,
    };
    final avatars = await avatarsOf(session, ids, storage: _storage);
    final viewer = session.userIdOrNull;
    final followed = viewer == null
        ? const <UuidValue>{}
        : {
            for (final row in await Follow.db.find(
              session,
              where: (t) =>
                  t.followerId.equals(viewer) & t.followeeId.inSet(ids),
            ))
              row.followeeId,
          };
    return [
      for (final account in accounts)
        _view(
          account,
          users[account.authUserId],
          avatarUrl: avatars[account.authUserId],
          viewerFollows: followed.contains(account.authUserId),
        ),
    ];
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

  /// El permiso para subir un avatar: JPEG, PNG o WebP de hasta 5 MB. El
  /// cliente lo sube con `FileUploader` y después lo confirma con
  /// [setAvatar]. Mismo patrón que los adjuntos de posts.
  Future<MediaUploadTicket> requestAvatarUpload(
    Session session, {
    required String contentType,
    required int sizeBytes,
  }) async {
    final userId = session.requireUserId;
    final ext = AvatarPolicy.extensionFor(contentType);
    if (ext == null) {
      throw _error(
        NexoErrorCode.invalidInput,
        'El avatar tiene que ser JPEG, PNG o WebP.',
      );
    }
    if (sizeBytes <= 0 || sizeBytes > AvatarPolicy.maxBytes) {
      throw _error(
        NexoErrorCode.invalidInput,
        'El avatar supera el máximo de '
        '${AvatarPolicy.maxBytes ~/ (1024 * 1024)} MB.',
      );
    }
    final key = AvatarPolicy.newKey(userId, ext);
    final description = await _storage.createUploadDescription(
      session,
      key,
      contentType: contentType.toLowerCase(),
      contentLength: sizeBytes,
      maxBytes: AvatarPolicy.maxBytes,
    );
    if (description == null) {
      throw StateError('El storage configurado no admite subidas directas.');
    }
    return MediaUploadTicket(
      key: key,
      uploadDescription: description,
      maxBytes: AvatarPolicy.maxBytes,
    );
  }

  /// Confirma [key] como avatar de la sesión, o lo quita con `null`. La
  /// clave tiene que ser de [requestAvatarUpload], de la misma cuenta y ya
  /// subida. El archivo anterior queda en el storage.
  Future<AccountView> setAvatar(Session session, String? key) async {
    final userId = session.requireUserId;
    await requireActive(session, userId);
    if (key != null) {
      final owner = AvatarPolicy.ownerOf(key);
      if (owner == null) {
        throw _error(NexoErrorCode.invalidInput, 'Archivo no válido.');
      }
      if (owner != userId) {
        throw _error(NexoErrorCode.forbidden, 'Ese archivo no es tuyo.');
      }
      if (!await _storage.verifyUpload(session, key)) {
        throw _error(
          NexoErrorCode.invalidInput,
          'El avatar todavía no terminó de subirse.',
        );
      }
    }

    await session.db.transaction((tx) async {
      final account = (await AccountProfile.db.findFirstRow(
        session,
        where: (t) => t.authUserId.equals(userId),
        transaction: tx,
        lockMode: LockMode.forUpdate,
      ))!;
      await AccountProfile.db.updateRow(
        session,
        account.copyWith(avatarKey: key, updatedAt: DateTime.now().toUtc()),
        columns: (t) => [t.avatarKey, t.updatedAt],
        transaction: tx,
      );
      await _audit.record(
        session,
        actorId: userId,
        action: 'identity.setAvatar',
        entityType: 'account',
        entityId: '$userId',
        metadata: {'removed': key == null},
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
        // Un lock por cuenta: la app pide `profiles.me` dos veces al entrar
        // con una cuenta recién creada, y sin él las dos transacciones
        // intentaban crear el perfil y una chocaba contra el índice único.
        // Con el lock se ordenan y la segunda encuentra la fila de la primera.
        await session.db.unsafeExecute(
          'SELECT pg_advisory_xact_lock(hashtext(@key))',
          parameters: QueryParameters.named({'key': 'account:$userId'}),
          transaction: tx,
        );
        final raced = await AccountProfile.db.findFirstRow(
          session,
          where: (t) => t.authUserId.equals(userId),
          transaction: tx,
        );
        if (raced != null) return raced;
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
      // Red de seguridad: otro camino que cree el perfil sin pasar por este
      // lock. El índice único lo frena y la fila ya está.
      final raced = await _account(session, userId);
      if (raced != null) return raced;
      rethrow;
    }
  }

  /// El perfil de [userId] si la cuenta puede escribir; si está suspendida o
  /// baneada, lanza `accountSuspended` (D4 del SDD 0004).
  Future<AccountProfile> requireActive(
    Session session,
    UuidValue userId,
  ) async {
    final account = await ensure(session, userId);
    if (account.status != AccountStatus.active) {
      throw _error(
        NexoErrorCode.accountSuspended,
        'Tu cuenta está suspendida.',
      );
    }
    return account;
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

  ProfileView _view(
    AccountProfile account,
    UserProfile? user, {
    String? avatarUrl,
    bool viewerFollows = false,
  }) => ProfileView(
    userId: account.authUserId,
    username: account.username,
    displayName: (user?.fullName?.trim().isNotEmpty ?? false)
        ? user!.fullName!.trim()
        : account.username,
    bio: account.bio,
    avatarUrl: avatarUrl ?? user?.image?.url.toString(),
    isCreator: account.isCreator,
    verification: account.verification,
    status: account.status,
    followerCount: account.followerCount,
    followingCount: account.followingCount,
    viewerFollows: viewerFollows,
    createdAt: account.createdAt,
  );

  static NexoException _error(NexoErrorCode code, String message) =>
      NexoException(code: code, message: message);
}
