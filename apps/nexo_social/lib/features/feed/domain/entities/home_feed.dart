import 'package:equatable/equatable.dart';

import '../../../live/domain/entities/live_session.dart';
import '../../../profile/domain/entities/follow.dart';
import 'post.dart';

/// Qué reúne una sección del inicio. El servidor arma las secciones (D6 del
/// SDD 0004): el orden y qué entra en cada una no lo decide la pantalla.
enum FeedSectionKind { liveNow, following, suggestedAccounts, discover }

/// Un elemento del feed. Sellado: el feed mezcla publicaciones y vivos, y
/// un `switch` que olvida un tipo tiene que fallar al compilar, no dibujar
/// un hueco.
sealed class FeedItem extends Equatable {
  const FeedItem();
}

final class PostFeedItem extends FeedItem {
  const PostFeedItem(this.post);

  final Post post;

  @override
  List<Object?> get props => [post];
}

final class LiveFeedItem extends FeedItem {
  const LiveFeedItem(this.session);

  final LiveSession session;

  @override
  List<Object?> get props => [session];
}

class FeedSection extends Equatable {
  const FeedSection({
    required this.kind,
    this.items = const [],
    this.accounts = const [],
  });

  final FeedSectionKind kind;
  final List<FeedItem> items;

  /// Sólo en [FeedSectionKind.suggestedAccounts].
  final List<ProfileSummary> accounts;

  List<Post> get posts => [
    for (final item in items)
      if (item case PostFeedItem(:final post)) post,
  ];

  List<LiveSession> get lives => [
    for (final item in items)
      if (item case LiveFeedItem(:final session)) session,
  ];

  @override
  List<Object?> get props => [kind, items, accounts];
}

/// Una página del inicio. La primera trae todas las secciones que tengan
/// algo; las siguientes, sólo publicaciones (primero de quienes seguís,
/// después para descubrir).
class HomeFeedPage extends Equatable {
  const HomeFeedPage(this.sections, {this.nextCursor});

  final List<FeedSection> sections;

  /// Opaco: la pantalla lo devuelve tal cual. Null cuando no hay más.
  final String? nextCursor;

  FeedSection? section(FeedSectionKind kind) =>
      sections.where((section) => section.kind == kind).firstOrNull;

  @override
  List<Object?> get props => [sections, nextCursor];
}
