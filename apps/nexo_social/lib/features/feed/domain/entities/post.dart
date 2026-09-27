import 'package:equatable/equatable.dart';

class Post extends Equatable {
  const Post({
    required this.id,
    required this.author,
    required this.name,
    required this.body,
    required this.tags,
    required this.likes,
    required this.comments,
    this.isLiked = false,
    this.isSaved = false,
    this.isLive = false,
  });
  final String id;
  final String author;
  final String name;
  final String body;
  final List<String> tags;
  final int likes;
  final int comments;
  final bool isLiked;
  final bool isSaved;
  final bool isLive;
  Post copyWith({bool? isLiked, bool? isSaved}) => Post(
    id: id,
    author: author,
    name: name,
    body: body,
    tags: tags,
    likes: likes,
    comments: comments,
    isLiked: isLiked ?? this.isLiked,
    isSaved: isSaved ?? this.isSaved,
    isLive: isLive,
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
    isLiked,
    isSaved,
    isLive,
  ];

  Map<String, Object> toJson() => {
    'id': id,
    'author': author,
    'name': name,
    'body': body,
    'tags': tags,
    'likes': likes,
    'comments': comments,
    'isLiked': isLiked,
    'isSaved': isSaved,
    'isLive': isLive,
  };
  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: json['id'] as String,
    author: json['author'] as String,
    name: json['name'] as String,
    body: json['body'] as String,
    tags: List<String>.from(json['tags'] as List<dynamic>),
    likes: json['likes'] as int,
    comments: json['comments'] as int,
    isLiked: json['isLiked'] as bool? ?? false,
    isSaved: json['isSaved'] as bool? ?? false,
    isLive: json['isLive'] as bool? ?? false,
  );
}
