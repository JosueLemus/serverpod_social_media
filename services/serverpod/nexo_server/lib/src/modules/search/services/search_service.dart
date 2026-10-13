import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../../../generated/protocol.dart';
import '../../../shared/profiles/profile_lookup.dart';
import '../../content/services/post_service.dart';
import '../../identity/services/identity_service.dart';
import '../../live/services/live_service.dart';
import 'search_rules.dart';

/// El buscador de Explorar: cuentas, publicaciones, vivos y etiquetas.
///
/// No tiene reglas propias de quién ve qué: cada sección le pregunta al
/// módulo dueño, así que un post `followers` aparece en la búsqueda
/// exactamente para quien lo vería en el feed.
class SearchService {
  SearchService({
    this._identity = const IdentityService(),
    this._posts = const PostService(),
    LiveService? live,
  }) : _live = live ?? LiveService();

  final IdentityService _identity;
  final PostService _posts;
  final LiveService _live;

  /// Candidatos por fuente antes de ordenar: más que el límite, para que el
  /// orden (empieza con / contiene) elija entre suficientes.
  static const _accountCandidates = 50;

  Future<SearchResults> query(
    Session session,
    String text, {
    int? limit,
  }) async {
    final normalized = SearchRules.normalize(text);
    if (!SearchRules.isSearchable(normalized)) {
      return SearchResults(
        query: normalized,
        accounts: const [],
        posts: const [],
        lives: const [],
        tags: const [],
      );
    }
    final size = SearchRules.limit(limit);
    final pattern = SearchRules.containsPattern(normalized);

    // En serie: comparten la sesión, y en los tests corren dentro de una
    // transacción que no admite consultas a la vez.
    final accounts = await _accounts(session, normalized, pattern, size);
    final posts = await _posts.search(session, pattern, limit: size);
    final lives = await _live.search(session, pattern, limit: size);
    final tags = await _posts.tagsLike(session, pattern, limit: size);
    return SearchResults(
      query: normalized,
      accounts: accounts,
      posts: posts,
      lives: lives,
      tags: tags,
    );
  }

  /// Cuentas activas por nombre de usuario o nombre visible. Primero las que
  /// empiezan con el texto, después las que sólo lo contienen; en cada grupo,
  /// la más seguida primero.
  Future<List<ProfileView>> _accounts(
    Session session,
    String normalized,
    String pattern,
    int limit,
  ) async {
    final byUsername = await AccountProfile.db.find(
      session,
      where: (t) =>
          t.status.equals(AccountStatus.active) & t.username.ilike(pattern),
      limit: _accountCandidates,
    );
    final byName = await UserProfile.db.find(
      session,
      where: (t) => t.fullName.ilike(pattern),
      limit: _accountCandidates,
    );
    final missing = {for (final user in byName) user.authUserId}
      ..removeAll(byUsername.map((a) => a.authUserId));
    final accounts = [
      ...byUsername,
      if (missing.isNotEmpty)
        ...await AccountProfile.db.find(
          session,
          where: (t) =>
              t.status.equals(AccountStatus.active) &
              t.authUserId.inSet(missing),
        ),
    ];
    if (accounts.isEmpty) return const [];

    final names = await profilesOf(session, accounts.map((a) => a.authUserId));
    int rank(AccountProfile a) =>
        SearchRules.isPrefixMatch(normalized, [
          a.username,
          names[a.authUserId]?.fullName,
        ])
        ? 0
        : 1;
    accounts.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      final byFollowers = b.followerCount.compareTo(a.followerCount);
      return byFollowers != 0 ? byFollowers : a.username.compareTo(b.username);
    });
    return _identity.viewsOf(session, accounts.take(limit).toList());
  }
}
