import 'package:equatable/equatable.dart';

/// Un hashtag en tendencia.
class TrendingTopic extends Equatable {
  const TrendingTopic({
    required this.tag,
    required this.posts,
    this.isFollowed = false,
  });

  /// Sin `#`: el símbolo es presentación, y guardarlo dentro del valor obliga
  /// a recortarlo en cada lugar que lo use como clave.
  final String tag;
  final int posts;
  final bool isFollowed;

  TrendingTopic copyWith({bool? isFollowed}) => TrendingTopic(
    tag: tag,
    posts: posts,
    isFollowed: isFollowed ?? this.isFollowed,
  );

  @override
  List<Object?> get props => [tag, posts, isFollowed];
}

/// Un creador sugerido.
class SuggestedCreator extends Equatable {
  const SuggestedCreator({
    required this.username,
    required this.name,
    required this.headline,
    this.userId = '',
    this.isVerified = false,
    this.isPro = false,
    this.isLive = false,
    this.isFollowed = false,
    this.avatarUrl,
  });

  /// El id en el servidor, que es lo que pide seguir. Vacío en el mock, que
  /// sigue por username.
  final String userId;
  final String username;
  final String name;

  /// Una línea sobre qué hace. Es lo que convierte una lista de nombres en una
  /// razón para seguir a alguien.
  final String headline;

  final bool isVerified;
  final bool isPro;
  final bool isLive;
  final bool isFollowed;
  final String? avatarUrl;

  SuggestedCreator copyWith({bool? isFollowed}) => SuggestedCreator(
    userId: userId,
    username: username,
    name: name,
    headline: headline,
    isVerified: isVerified,
    isPro: isPro,
    isLive: isLive,
    isFollowed: isFollowed ?? this.isFollowed,
    avatarUrl: avatarUrl,
  );

  @override
  List<Object?> get props => [
    userId,
    username,
    name,
    headline,
    isVerified,
    isPro,
    isLive,
    isFollowed,
    avatarUrl,
  ];
}
