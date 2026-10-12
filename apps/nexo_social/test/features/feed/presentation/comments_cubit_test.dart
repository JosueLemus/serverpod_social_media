import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/features/feed/domain/entities/post_extras.dart';
import 'package:nexo_social/features/feed/presentation/bloc/comments_cubit.dart';
import 'package:nexo_social/features/moderation/domain/entities/moderation_action.dart';

import '../../../support/fake_post_repository.dart';

void main() {
  late FakePostRepository repository;
  late CommentsCubit cubit;

  setUp(() {
    repository = FakePostRepository();
    cubit = CommentsCubit(repository, '1');
  });
  tearDown(() => cubit.close());

  test('an empty thread is loaded, not failed', () async {
    await cubit.load();

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.failed, isFalse);
    expect(cubit.state.comments, isEmpty);
  });

  test('a comment sent shows up at the end of the thread', () async {
    await cubit.load();

    final sent = await cubit.send('  Gran post  ');

    expect(sent, isTrue);
    expect(cubit.state.comments.single.body, 'Gran post');
  });

  test('blank or over-long comments are not sent', () async {
    expect(await cubit.send('   '), isFalse);
    expect(await cubit.send('x' * (CommentsCubit.maxLength + 1)), isFalse);
    expect(repository.threads, isEmpty);
  });

  /// `forbidden` al comentar es un post con los comentarios cerrados: se
  /// dice eso, no un error genérico.
  test('a closed thread says so, and the text is kept', () async {
    repository.failNext = const ForbiddenFailure('comments off');

    final sent = await cubit.send('Hola');

    expect(sent, isFalse);
    expect(cubit.state.notice, CommentsNotice.closed);
  });

  test('deleting removes it; reporting sends the typed reason', () async {
    await cubit.send('uno');
    await cubit.send('dos');
    final first = cubit.state.comments.first;

    await cubit.delete(first);
    await cubit.report(cubit.state.comments.single, ModerationReason.spam);

    expect(cubit.state.comments.single.body, 'dos');
    expect(repository.reports.single.$1, ReportTarget.comment);
    expect(cubit.state.notice, CommentsNotice.reported);
  });

  test('a thread that cannot be read is a failure, not empty', () async {
    repository.failNext = const NetworkFailure('offline');

    await cubit.load();

    expect(cubit.state.failed, isTrue);
  });

  /// Regresión: el servidor pagina del más viejo al más nuevo, así que un
  /// comentario propio enviado con páginas pendientes volvía en la última y
  /// se veía dos veces.
  test('paging does not repeat a comment already sent', () {
    PostComment comment(String id, int minute) => PostComment(
      id: id,
      postId: '1',
      author: 'a',
      name: 'A',
      body: id,
      createdAt: DateTime(2026, 10, 11, 12, minute),
    );
    final mine = comment('mine', 30);

    final merged = CommentsCubit.mergeComments(
      [comment('c1', 1), comment('c2', 2), mine],
      [comment('c3', 3), comment('c4', 4), mine],
    );

    expect(merged.map((c) => c.id), ['c1', 'c2', 'c3', 'c4', 'mine']);
  });
}
