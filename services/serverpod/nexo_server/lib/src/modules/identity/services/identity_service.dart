import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../../../generated/protocol.dart';
import '../../../shared/audit/audit_service.dart';
import '../../../shared/auth/auth_context.dart';
import '../../../shared/gateways/media_storage_gateway.dart';
import '../../../shared/gateways/serverpod_media_storage_gateway.dart';
import '../../../shared/profiles/avatar_lookup.dart';
import 'profile_image_policy.dart';
import 'username_rules.dart';
import 'website_rules.dart';

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
    final covers = <UuidValue, String>{};
    for (final account in accounts) {
      final key = account.coverKey;
      if (key == null) continue;
      final url = await _storage.publicUrl(session, key);
      if (url != null) covers[account.authUserId] = url.toString();
    }
    final posts = await _postCounts(session, ids);
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
          coverUrl: covers[account.authUserId],
          postCount: posts[account.authUserId] ?? 0,
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
    // `null` no toca el enlace; un texto vacío lo quita.
    final website = edit.website == null
        ? null
        : WebsiteRules.normalize(edit.website!);
    if (website != null) {
      final problem = WebsiteRules.problemWith(website);
      if (problem != null) throw _error(NexoErrorCode.invalidInput, problem);
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
          website: edit.website == null ? account.website : website,
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
  }) => _requestImageUpload(
    session,
    ProfileImagePolicy.avatar,
    contentType: contentType,
    sizeBytes: sizeBytes,
  );

  /// El permiso para subir el banner del perfil: JPEG, PNG o WebP de hasta
  /// 8 MB, confirmado después con [setCover].
  Future<MediaUploadTicket> requestCoverUpload(
    Session session, {
    required String contentType,
    required int sizeBytes,
  }) => _requestImageUpload(
    session,
    ProfileImagePolicy.cover,
    contentType: contentType,
    sizeBytes: sizeBytes,
  );

  /// Confirma [key] como avatar de la sesión, o lo quita con `null`. La
  /// clave tiene que ser de [requestAvatarUpload], de la misma cuenta y ya
  /// subida. El archivo anterior queda en el storage.
  Future<AccountView> setAvatar(Session session, String? key) =>
      _setImage(session, ProfileImagePolicy.avatar, key);

  /// Confirma [key] como banner de la sesión, o lo quita con `null`. Mismas
  /// reglas que [setAvatar].
  Future<AccountView> setCover(Session session, String? key) =>
      _setImage(session, ProfileImagePolicy.cover, key);

  Future<MediaUploadTicket> _requestImageUpload(
    Session session,
    ProfileImagePolicy policy, {
    required String contentType,
    required int sizeBytes,
  }) async {
    final userId = session.requireUserId;
    final ext = policy.extensionFor(contentType);
    if (ext == null) {
      throw _error(
        NexoErrorCode.invalidInput,
        '${policy.label} tiene que ser JPEG, PNG o WebP.',
      );
    }
    if (sizeBytes <= 0 || sizeBytes > policy.maxBytes) {
      throw _error(
        NexoErrorCode.invalidInput,
        '${policy.label} supera el máximo de '
        '${policy.maxBytes ~/ (1024 * 1024)} MB.',
      );
    }
    final key = policy.newKey(userId, ext);
    final description = await _storage.createUploadDescription(
      session,
      key,
      contentType: contentType.toLowerCase(),
      contentLength: sizeBytes,
      maxBytes: policy.maxBytes,
    );
    if (description == null) {
      throw StateError('El storage configurado no admite subidas directas.');
    }
    return MediaUploadTicket(
      key: key,
      uploadDescription: description,
      maxBytes: policy.maxBytes,
    );
  }

  Future<AccountView> _setImage(
    Session session,
    ProfileImagePolicy policy,
    String? key,
  ) async {
    final userId = session.requireUserId;
    await requireActive(session, userId);
    if (key != null) {
      final owner = policy.ownerOf(key);
      if (owner == null) {
        throw _error(NexoErrorCode.invalidInput, 'Archivo no válido.');
      }
      if (owner != userId) {
        throw _error(NexoErrorCode.forbidden, 'Ese archivo no es tuyo.');
      }
      if (!await _storage.verifyUpload(session, key)) {
        throw _error(
          NexoErrorCode.invalidInput,
          '${policy.label} todavía no terminó de subirse.',
        );
      }
    }

    final isCover = identical(policy, ProfileImagePolicy.cover);
    await session.db.transaction((tx) async {
      final account = (await AccountProfile.db.findFirstRow(
        session,
        where: (t) => t.authUserId.equals(userId),
        transaction: tx,
        lockMode: LockMode.forUpdate,
      ))!;
      final now = DateTime.now().toUtc();
      await AccountProfile.db.updateRow(
        session,
        isCover
            ? account.copyWith(coverKey: key, updatedAt: now)
            : account.copyWith(avatarKey: key, updatedAt: now),
        columns: (t) => [isCover ? t.coverKey : t.avatarKey, t.updatedAt],
        transaction: tx,
      );
      await _audit.record(
        session,
        actorId: userId,
        action: isCover ? 'identity.setCover' : 'identity.setAvatar',
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

  /// Publicaciones no borradas de cada cuenta en [ids], en una consulta.
  /// Los ids son `UuidValue` validados: interpolarlos no abre una inyección.
  Future<Map<UuidValue, int>> _postCounts(
    Session session,
    Set<UuidValue> ids,
  ) async {
    if (ids.isEmpty) return const {};
    final list = ids.map((id) => "'$id'").join(',');
    final rows = await session.db.unsafeQuery(
      'SELECT "authorId"::text, COUNT(*)::int FROM "post" '
      'WHERE "deletedAt" IS NULL AND "authorId" IN ($list) '
      'GROUP BY "authorId"',
    );
    return {
      for (final row in rows)
        UuidValue.withValidation(row[0] as String): row[1] as int,
    };
  }

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
    String? coverUrl,
    int postCount = 0,
    bool viewerFollows = false,
  }) => ProfileView(
    userId: account.authUserId,
    username: account.username,
    displayName: (user?.fullName?.trim().isNotEmpty ?? false)
        ? user!.fullName!.trim()
        : account.username,
    bio: account.bio,
    avatarUrl: avatarUrl ?? user?.image?.url.toString(),
    coverUrl: coverUrl,
    website: account.website,
    postCount: postCount,
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
