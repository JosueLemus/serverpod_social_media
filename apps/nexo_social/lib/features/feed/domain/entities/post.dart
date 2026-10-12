import 'package:equatable/equatable.dart';

/// What a post carries besides text. Nullable on [Post]: "no media" is a
/// state, not a kind.
enum PostMedia { image, video }

/// Quién puede ver un post. Es una decisión del dominio, no un adorno: el
/// backend filtra el feed por esto, y "todos" nunca puede ser un default
/// accidental.
enum PostVisibility {
  public('Público', 'Todos'),
  followers('Seguidores', 'Solo quien te sigue'),
  members('Miembros', 'Solo suscriptores Pro');

  const PostVisibility(this.label, this.detail);

  final String label;
  final String detail;
}

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
    this.authorId = '',
    this.media,
    this.mediaUrl,
    this.isLiked = false,
    this.isSaved = false,
    this.isLive = false,
    this.isFollowed = false,
    this.authorIsVerified = false,
    this.authorIsPro = false,
    this.canEdit = false,
    this.canDelete = false,
    this.allowComments = true,
    this.visibility = PostVisibility.public,
    this.editedAt,
  });

  final String id;

  /// El handle del autor, sin `@`.
  final String author;
  final String authorId;
  final String name;
  final String body;
  final List<String> tags;

  /// El total de likes **según el servidor**, incluido el de quien mira si
  /// [isLiked]. Un toque optimista lo mueve en uno y la respuesta del
  /// servidor lo reemplaza: así el número nunca queda inflado.
  final int likes;
  final int comments;

  /// When it was published. Stored, never pre-formatted: a string written at
  /// construction time freezes "hace 25 min" forever, which is exactly what
  /// the feed used to show on every post regardless of age.
  final DateTime createdAt;

  final PostMedia? media;

  /// Dónde está el archivo. Null en los posts del mock, que sólo saben de
  /// qué tipo es.
  final String? mediaUrl;
  final bool isLiked;
  final bool isSaved;
  final bool isLive;

  /// Whether the signed-in user follows the author. Drives the Siguiendo tab.
  final bool isFollowed;

  /// Insignias del autor. Se guardan en el post y no se derivan del nombre
  /// porque son del perfil, no del contenido — y el feed no carga perfiles.
  final bool authorIsVerified;
  final bool authorIsPro;

  /// Qué acciones ofrecer. Las decide el servidor: el cliente no muestra un
  /// botón que se va a rechazar.
  final bool canEdit;
  final bool canDelete;
  final bool allowComments;
  final PostVisibility visibility;
  final DateTime? editedAt;

  int get displayLikes => likes;

  Post copyWith({
    String? body,
    List<String>? tags,
    bool? isLiked,
    int? likes,
    bool? isSaved,
    bool? isFollowed,
    int? comments,
    bool? allowComments,
    PostVisibility? visibility,
    DateTime? editedAt,
  }) => Post(
    id: id,
    author: author,
    authorId: authorId,
    name: name,
    body: body ?? this.body,
    tags: tags ?? this.tags,
    likes: likes ?? this.likes,
    comments: comments ?? this.comments,
    createdAt: createdAt,
    media: media,
    mediaUrl: mediaUrl,
    isLiked: isLiked ?? this.isLiked,
    isSaved: isSaved ?? this.isSaved,
    isLive: isLive,
    isFollowed: isFollowed ?? this.isFollowed,
    authorIsVerified: authorIsVerified,
    authorIsPro: authorIsPro,
    canEdit: canEdit,
    canDelete: canDelete,
    allowComments: allowComments ?? this.allowComments,
    visibility: visibility ?? this.visibility,
    editedAt: editedAt ?? this.editedAt,
  );

  @override
  List<Object?> get props => [
    id,
    author,
    authorId,
    name,
    body,
    tags,
    likes,
    comments,
    createdAt,
    media,
    mediaUrl,
    isLiked,
    isSaved,
    isLive,
    isFollowed,
    authorIsVerified,
    authorIsPro,
    canEdit,
    canDelete,
    allowComments,
    visibility,
    editedAt,
  ];

  Map<String, Object?> toJson() => {
    'id': id,
    'author': author,
    'authorId': authorId,
    'name': name,
    'body': body,
    'tags': tags,
    'likes': likes,
    'comments': comments,
    'createdAt': createdAt.toIso8601String(),
    'media': media?.name,
    'mediaUrl': mediaUrl,
    'isLiked': isLiked,
    'isSaved': isSaved,
    'isLive': isLive,
    'isFollowed': isFollowed,
    'authorIsVerified': authorIsVerified,
    'authorIsPro': authorIsPro,
    'canEdit': canEdit,
    'canDelete': canDelete,
    'allowComments': allowComments,
    'visibility': visibility.name,
  };

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: json['id'] as String,
    author: json['author'] as String,
    authorId: json['authorId'] as String? ?? '',
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
    mediaUrl: json['mediaUrl'] as String?,
    isLiked: json['isLiked'] as bool? ?? false,
    isSaved: json['isSaved'] as bool? ?? false,
    isLive: json['isLive'] as bool? ?? false,
    isFollowed: json['isFollowed'] as bool? ?? false,
    authorIsVerified: json['authorIsVerified'] as bool? ?? false,
    authorIsPro: json['authorIsPro'] as bool? ?? false,
    canEdit: json['canEdit'] as bool? ?? false,
    canDelete: json['canDelete'] as bool? ?? false,
    allowComments: json['allowComments'] as bool? ?? true,
    visibility:
        PostVisibility.values.asNameMap()[json['visibility']] ??
        PostVisibility.public,
  );
}
