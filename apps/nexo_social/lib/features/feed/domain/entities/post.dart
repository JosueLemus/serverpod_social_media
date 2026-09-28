import 'package:equatable/equatable.dart';

/// What a post carries besides text. Nullable on [Post]: "no media" is a
/// state, not a kind.
enum PostMedia { image, video }

class Post extends Equatable {
  const Post({
    required this.id,
    required this.author,
    required this.name,
    required this.body,
    required this.tags,
    required this.likes,
    required this.comments,
    required this.createdAt,
    this.media,
    this.isLiked = false,
    this.isSaved = false,
    this.isLive = false,
    this.isFollowed = false,
    this.authorIsVerified = false,
    this.authorIsPro = false,
  });

  final String id;
  final String author;
  final String name;
  final String body;
  final List<String> tags;
  final int likes;
  final int comments;

  /// When it was published. Stored, never pre-formatted: a string written at
  /// construction time freezes "hace 25 min" forever, which is exactly what
  /// the feed used to show on every post regardless of age.
  final DateTime createdAt;

  final PostMedia? media;
  final bool isLiked;
  final bool isSaved;
  final bool isLive;

  /// Whether the signed-in user follows the author. Drives the Siguiendo tab.
  final bool isFollowed;

  /// Insignias del autor. Se guardan en el post y no se derivan del nombre
  /// porque son del perfil, no del contenido — y el feed no carga perfiles.
  final bool authorIsVerified;
  final bool authorIsPro;

  /// The count to render. The base [likes] never changes locally, so the
  /// user's own like is added on read — that keeps an optimistic tap from
  /// permanently inflating the stored number if it is later reconciled with
  /// the server.
  int get displayLikes => likes + (isLiked ? 1 : 0);

  Post copyWith({
    bool? isLiked,
    bool? isSaved,
    bool? isFollowed,
    int? comments,
  }) => Post(
    id: id,
    author: author,
    name: name,
    body: body,
    tags: tags,
    likes: likes,
    comments: comments ?? this.comments,
    createdAt: createdAt,
    media: media,
    isLiked: isLiked ?? this.isLiked,
    isSaved: isSaved ?? this.isSaved,
    isLive: isLive,
    isFollowed: isFollowed ?? this.isFollowed,
    authorIsVerified: authorIsVerified,
    authorIsPro: authorIsPro,
  );

  @override
  List<Object?> get props => [
    id,
    author,
    name,
    body,
    tags,
    likes,
    comments,
    createdAt,
    media,
    isLiked,
    isSaved,
    isLive,
    isFollowed,
    authorIsVerified,
    authorIsPro,
  ];

  Map<String, Object?> toJson() => {
    'id': id,
    'author': author,
    'name': name,
    'body': body,
    'tags': tags,
    'likes': likes,
    'comments': comments,
    'createdAt': createdAt.toIso8601String(),
    'media': media?.name,
    'isLiked': isLiked,
    'isSaved': isSaved,
    'isLive': isLive,
    'isFollowed': isFollowed,
    'authorIsVerified': authorIsVerified,
    'authorIsPro': authorIsPro,
  };

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: json['id'] as String,
    author: json['author'] as String,
    name: json['name'] as String,
    body: json['body'] as String,
    tags: List<String>.from(json['tags'] as List<dynamic>),
    likes: json['likes'] as int,
    comments: json['comments'] as int,
    // Absent for anything written by an older build. Falling back to "now"
    // keeps a cached post readable instead of throwing on parse.
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    media: switch (json['media'] as String?) {
      'image' => PostMedia.image,
      'video' => PostMedia.video,
      _ => null,
    },
    isLiked: json['isLiked'] as bool? ?? false,
    isSaved: json['isSaved'] as bool? ?? false,
    isLive: json['isLive'] as bool? ?? false,
    isFollowed: json['isFollowed'] as bool? ?? false,
    authorIsVerified: json['authorIsVerified'] as bool? ?? false,
    authorIsPro: json['authorIsPro'] as bool? ?? false,
  );
}
