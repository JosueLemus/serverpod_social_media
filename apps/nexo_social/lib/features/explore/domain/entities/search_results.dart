import 'package:equatable/equatable.dart';

import '../../../feed/domain/entities/post.dart';
import '../../../live/domain/entities/live_session.dart';
import '../../../profile/domain/entities/follow.dart';

/// Lo que encontró el buscador de Explorar para [query].
///
/// [query] es el texto ya normalizado por el servidor: la búsqueda que lo
/// pidió puede no ser la última que escribió la persona, y con él se descarta
/// una respuesta que llegó tarde.
class SearchResults extends Equatable {
  const SearchResults({
    required this.query,
    this.accounts = const [],
    this.posts = const [],
    this.lives = const [],
    this.tags = const [],
  });

  final String query;
  final List<ProfileSummary> accounts;
  final List<Post> posts;
  final List<LiveSession> lives;

  /// Sin `#`.
  final List<String> tags;

  bool get isEmpty =>
      accounts.isEmpty && posts.isEmpty && lives.isEmpty && tags.isEmpty;

  SearchResults copyWith({List<ProfileSummary>? accounts}) => SearchResults(
    query: query,
    accounts: accounts ?? this.accounts,
    posts: posts,
    lives: lives,
    tags: tags,
  );

  @override
  List<Object?> get props => [query, accounts, posts, lives, tags];
}
