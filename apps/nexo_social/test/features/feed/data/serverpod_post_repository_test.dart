import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_client/nexo_client.dart' as api;
import 'package:nexo_social/features/feed/data/repositories/serverpod_post_repository.dart';
import 'package:nexo_social/features/feed/domain/entities/post.dart';

void main() {
  api.PostView view({
    List<api.PostMediaView> media = const [],
    String? authorName = 'Elena Vega',
  }) => api.PostView(
    id: 42,
    authorId: api.UuidValue.fromString('550e8400-e29b-41d4-a716-446655440000'),
    authorUsername: 'elena_ux',
    authorName: authorName,
    body: 'Hola',
    tags: ['uiux'],
    visibility: api.PostVisibility.followers,
    allowComments: false,
    likeCount: 7,
    isLiked: true,
    commentCount: 3,
    media: media,
    createdAt: DateTime.utc(2026, 10, 1, 12),
    canEdit: true,
    canDelete: true,
  );

  test('the server post maps field by field', () {
    final post = ServerpodPostRepository.toPost(view());

    expect(post.id, '42');
    expect(post.author, 'elena_ux');
    expect(post.name, 'Elena Vega');
    expect(post.likes, 7);
    expect(post.isLiked, isTrue);
    expect(post.comments, 3);
    expect(post.canEdit, isTrue);
    expect(post.allowComments, isFalse);
    expect(post.visibility, PostVisibility.followers);
    expect(post.media, isNull);
  });

  test('the first attachment becomes the post media, with its url', () {
    final post = ServerpodPostRepository.toPost(
      view(
        media: [
          api.PostMediaView(
            kind: api.PostMediaKind.video,
            url: Uri.parse('https://cdn.example/clip.mp4'),
            contentType: 'video/mp4',
          ),
        ],
      ),
    );

    expect(post.media, PostMedia.video);
    expect(post.mediaUrl, 'https://cdn.example/clip.mp4');
  });

  /// Las cuentas sin username todavía (antes del módulo identity) no rompen
  /// la tarjeta.
  test('a missing author name falls back to the username', () {
    final post = ServerpodPostRepository.toPost(view(authorName: null));
    expect(post.name, 'elena_ux');
  });
}
