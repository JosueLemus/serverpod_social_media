import 'package:equatable/equatable.dart';

/// A chat message in the room. A value type rather than a formatted string:
/// the list needs to know who wrote it to render the author differently, and
/// moderation needs an id to hide the right one.
class LiveComment extends Equatable {
  const LiveComment({
    required this.id,
    required this.author,
    required this.body,
    this.authorId = '',
    this.isMine = false,
  });

  final String id;
  final String author;
  final String authorId;
  final String body;
  final bool isMine;

  @override
  List<Object?> get props => [id, author, authorId, body, isMine];
}
