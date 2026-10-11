import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/features/auth/domain/entities/app_user.dart';
import 'package:nexo_social/features/feed/domain/entities/post_extras.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';
import 'package:nexo_social/features/live/domain/repositories/live_repository.dart';
import 'package:nexo_social/features/profile/domain/entities/public_profile.dart';
import 'package:nexo_social/features/profile/domain/repositories/profile_repository.dart';
import 'package:nexo_social/features/profile/presentation/bloc/public_profile_cubit.dart';

import '../../../support/fake_post_repository.dart';

class _MockProfiles extends Mock implements ProfileRepository {}

class _MockLives extends Mock implements LiveRepository {}

const _carlos = PublicProfile(
  id: 'uuid-carlos',
  username: 'carlos_mendez',
  name: 'Carlos Méndez',
  isCreator: true,
  verification: VerificationStatus.verified,
);

void main() {
  late _MockProfiles profiles;
  late _MockLives lives;
  late FakePostRepository posts;

  setUpAll(() => registerFallbackValue(_carlos));

  setUp(() {
    profiles = _MockProfiles();
    lives = _MockLives();
    posts = FakePostRepository();
    when(() => lives.list()).thenAnswer(
      (_) async => const [
        LiveSession(
          id: 'live-c',
          title: 'Flutter en vivo',
          hostName: 'Carlos Méndez',
          status: LiveStatus.scheduled,
        ),
        LiveSession(
          id: 'live-e',
          title: 'Masterclass',
          hostName: 'Elena Vega',
          status: LiveStatus.scheduled,
        ),
      ],
    );
  });

  PublicProfileCubit cubit() =>
      PublicProfileCubit(profiles, lives, posts, 'carlos_mendez');

  test('loads the account, its posts and only its lives', () async {
    when(
      () => profiles.byUsername('carlos_mendez'),
    ).thenAnswer((_) async => _carlos);
    when(
      () => profiles.postsOf(any(), cursor: any(named: 'cursor')),
    ).thenAnswer((_) async => PostPage([fakePost('p1')], nextCursor: 'c1'));
    final subject = cubit();

    await subject.load();

    final state = subject.state as PublicProfileLoaded;
    expect(state.profile, _carlos);
    expect(state.posts.map((post) => post.id), ['p1']);
    expect(state.hasMore, isTrue);
    expect(state.lives.map((live) => live.id), ['live-c']);
    await subject.close();
  });

  test('an unknown username is "not found", not an error', () async {
    when(
      () => profiles.byUsername('carlos_mendez'),
    ).thenThrow(const NotFoundFailure('profile'));
    final subject = cubit();

    await subject.load();

    expect(subject.state, const PublicProfileNotFound());
    await subject.close();
  });

  test('no network reads as offline', () async {
    when(
      () => profiles.byUsername('carlos_mendez'),
    ).thenThrow(const NetworkFailure('offline'));
    final subject = cubit();

    await subject.load();

    expect(subject.state, const PublicProfileFailure(offline: true));
    await subject.close();
  });

  test('the next page is appended without duplicates', () async {
    when(
      () => profiles.byUsername('carlos_mendez'),
    ).thenAnswer((_) async => _carlos);
    when(
      () => profiles.postsOf(any()),
    ).thenAnswer((_) async => PostPage([fakePost('p1')], nextCursor: 'c1'));
    when(
      () => profiles.postsOf(any(), cursor: 'c1'),
    ).thenAnswer((_) async => PostPage([fakePost('p1'), fakePost('p2')]));
    final subject = cubit();
    await subject.load();

    await subject.loadMore();

    final state = subject.state as PublicProfileLoaded;
    expect(state.posts.map((post) => post.id), ['p1', 'p2']);
    expect(state.hasMore, isFalse);
    await subject.close();
  });

  test('a lives failure still shows the profile', () async {
    when(
      () => profiles.byUsername('carlos_mendez'),
    ).thenAnswer((_) async => _carlos);
    when(
      () => profiles.postsOf(any(), cursor: any(named: 'cursor')),
    ).thenAnswer((_) async => const PostPage([]));
    when(() => lives.list()).thenThrow(const NetworkFailure('offline'));
    final subject = cubit();

    await subject.load();

    expect(subject.state, isA<PublicProfileLoaded>());
    await subject.close();
  });

  test('publishing elsewhere refreshes the profile', () async {
    when(
      () => profiles.byUsername('carlos_mendez'),
    ).thenAnswer((_) async => _carlos);
    var calls = 0;
    when(
      () => profiles.postsOf(any(), cursor: any(named: 'cursor')),
    ).thenAnswer((_) async => PostPage([fakePost('p${++calls}')]));
    final subject = cubit();
    await subject.load();

    posts.emitChange();
    await pumpEventQueue();

    final state = subject.state as PublicProfileLoaded;
    expect(state.posts.single.id, 'p2');
    await subject.close();
  });
}
