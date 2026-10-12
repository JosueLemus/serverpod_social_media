import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'post.dart';

/// Una página del feed. [nextCursor] es opaco para la app: se devuelve tal
/// cual para pedir la siguiente. Null en la última.
class PostPage extends Equatable {
  const PostPage(this.posts, {this.nextCursor});

  final List<Post> posts;
  final String? nextCursor;

  @override
  List<Object?> get props => [posts, nextCursor];
}

class PostComment extends Equatable {
  const PostComment({
    required this.id,
    required this.postId,
    required this.author,
    required this.name,
    required this.body,
    required this.createdAt,
    this.canDelete = false,
  });

  final String id;
  final String postId;

  /// Handle, sin `@`.
  final String author;
  final String name;
  final String body;
  final DateTime createdAt;

  /// El autor del comentario, el autor del post o el staff. Lo decide el
  /// servidor.
  final bool canDelete;

  @override
  List<Object?> get props => [
    id,
    postId,
    author,
    name,
    body,
    createdAt,
    canDelete,
  ];
}

class CommentPage extends Equatable {
  const CommentPage(this.comments, {this.nextCursor});

  final List<PostComment> comments;
  final String? nextCursor;

  @override
  List<Object?> get props => [comments, nextCursor];
}

class PostLiker extends Equatable {
  const PostLiker({required this.username, required this.name});

  final String username;
  final String name;

  @override
  List<Object?> get props => [username, name];
}

/// El resultado de dar o quitar like: lo que dice el servidor, que reemplaza
/// lo que la app supuso con el toque optimista.
class LikeResult extends Equatable {
  const LikeResult({required this.isLiked, required this.likes});

  final bool isLiked;
  final int likes;

  @override
  List<Object?> get props => [isLiked, likes];
}

/// Un archivo elegido para publicar, todavía en la memoria del dispositivo.
class MediaAttachment extends Equatable {
  const MediaAttachment({
    required this.kind,
    required this.bytes,
    required this.contentType,
    required this.fileName,
  });

  final PostMedia kind;
  final Uint8List bytes;
  final String contentType;
  final String fileName;

  int get sizeBytes => bytes.lengthInBytes;

  // Los bytes no entran en la igualdad: comparar megas en cada emit del
  // compositor es caro, y el nombre más el tamaño ya distinguen dos archivos.
  @override
  List<Object?> get props => [kind, contentType, fileName, sizeBytes];
}

class PostDraftInput extends Equatable {
  const PostDraftInput({
    required this.body,
    this.tags = const [],
    this.visibility = PostVisibility.public,
    this.allowComments = true,
    this.attachment,
  });

  final String body;
  final List<String> tags;
  final PostVisibility visibility;
  final bool allowComments;
  final MediaAttachment? attachment;

  @override
  List<Object?> get props => [
    body,
    tags,
    visibility,
    allowComments,
    attachment,
  ];
}

/// Qué se reporta. Los motivos son los de moderación.
enum ReportTarget { post, comment }
