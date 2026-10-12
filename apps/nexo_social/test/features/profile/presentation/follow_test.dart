import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/features/auth/domain/entities/app_user.dart';
import 'package:nexo_social/features/feed/domain/entities/post_extras.dart';
import 'package:nexo_social/features/live/domain/repositories/live_repository.dart';
import 'package:nexo_social/features/profile/domain/entities/follow.dart';
import 'package:nexo_social/features/profile/domain/entities/public_profile.dart';
import 'package:nexo_social/features/profile/domain/repositories/follow_repository.dart';
import 'package:nexo_social/features/profile/domain/repositories/profile_repository.dart';
import 'package:nexo_social/features/profile/presentation/bloc/follow_cubit.dart';
import 'package:nexo_social/features/profile/presentation/bloc/follow_list_cubit.dart';
import 'package:nexo_social/features/profile/presentation/bloc/public_profile_cubit.dart';

import '../../../support/fake_post_repository.dart';

class _MockProfiles extends Mock implements ProfileRepository {}

class _MockLives extends Mock implements LiveRepository {}

class _MockFollows extends Mock implements FollowRepository {}

const _carlos = PublicProfile(
  id: 'uuid-carlos',
  username: 'carlos_mendez',
  name: 'Carlos Méndez',
  isCreator: true,
  verification: VerificationStatus.verified,
  followers: 10,
  following: 2,
);

ProfileSummary _summary(String id) =>
    ProfileSummary(id: id, username: 'u$id', name: 'User $id');

void main() {
  late _MockProfiles profiles;
  late _MockLives lives;
  late _MockFollows follows;

  setUpAll(() {
    registerFallbackValue(_carlos);
    registerFallbackValue(FollowListKind.followers);
  });

  setUp(() {
    profiles = _MockProfiles();
    lives = _MockLives();
    follows = _MockFollows();
    when(() => lives.list()).thenAnswer((_) async => const []);
    when(
      () => profiles.byUsername('carlos_mendez'),
    ).thenAnswer((_) async => _carlos);
    when(
      () => profiles.postsOf(any(), cursor: any(named: 'cursor')),
    ).thenAnswer((_) async => const PostPage([]));
  });

  group('following from the profile', () {
    Future<PublicProfileCubit> loaded() async {
      final cubit = PublicProfileCubit(
        profiles,
        lives,
        FakePostRepository(),
        'carlos_mendez',
        follows,
      );
      await cubit.load();
      return cubit;
    }

    PublicProfile profileOf(PublicProfileCubit cubit) =>
        (cubit.state as PublicProfileLoaded).profile;

    /// El botón y el contador cambian en el turno del tap; la respuesta del
    /// servidor deja el número real, que puede no ser "lo de antes más uno".
    test('is optimistic and then takes the server count', () async {
      when(() => follows.follow('uuid-carlos')).thenAnswer(
        (_) async => const FollowState(
          userId: 'uuid-carlos',
          viewerFollows: true,
          followerCount: 12,
        ),
      );
      final cubit = await loaded();
      final states = <PublicProfileState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.toggleFollow();

      final optimistic = (states.first as PublicProfileLoaded).profile;
      expect(optimistic.viewerFollows, isTrue);
      expect(optimistic.followers, 11);
      expect(profileOf(cubit).followers, 12);
      expect(profileOf(cubit).viewerFollows, isTrue);
      await sub.cancel();
      await cubit.close();
    });

    test('rolls back and says why when the server refuses', () async {
      when(
        () => follows.follow('uuid-carlos'),
      ).thenThrow(const NetworkFailure('offline'));
      final cubit = await loaded();

      await cubit.toggleFollow();

      final state = cubit.state as PublicProfileLoaded;
      expect(state.profile, _carlos);
      expect(state.notice, ProfileNotice.followFailed);
      expect(state.noticeSerial, 1);
      await cubit.close();
    });

    test('a visitor is asked to sign in', () async {
      when(
        () => follows.follow('uuid-carlos'),
      ).thenThrow(const ForbiddenFailure('unauthenticated'));
      final cubit = await loaded();

      await cubit.toggleFollow();

      expect(
        (cubit.state as PublicProfileLoaded).notice,
        ProfileNotice.signInToFollow,
      );
      await cubit.close();
    });
  });

  group('following the host of a live', () {
    test('reads whether it is already followed before offering', () async {
      when(
        () => profiles.byUsername('carlos_mendez'),
      ).thenAnswer((_) async => _carlos.copyWith(viewerFollows: true));
      final cubit = FollowCubit(follows, profiles, 'carlos_mendez');
      expect(cubit.state.isReady, isFalse);

      await cubit.load();

      expect(cubit.state.isReady, isTrue);
      expect(cubit.state.following, isTrue);
      await cubit.close();
    });

    test('toggles optimistically and rolls back on failure', () async {
      when(
        () => follows.follow('uuid-carlos'),
      ).thenThrow(const ServerFailure('500'));
      final cubit = FollowCubit(follows, profiles, 'carlos_mendez');
      await cubit.load();

      await cubit.toggle();

      expect(cubit.state.following, isFalse);
      expect(cubit.state.notice, ProfileNotice.followFailed);
      await cubit.close();
    });
  });

  group('follower lists', () {
    test('page until there is no cursor, without repeating', () async {
      when(
        () => follows.list('uuid-carlos', FollowListKind.followers),
      ).thenAnswer(
        (_) async =>
            FollowPage([_summary('1'), _summary('2')], nextCursor: 'c'),
      );
      when(
        () =>
            follows.list('uuid-carlos', FollowListKind.followers, cursor: 'c'),
      ).thenAnswer((_) async => FollowPage([_summary('2'), _summary('3')]));
      final cubit = FollowListCubit(
        follows,
        'uuid-carlos',
        FollowListKind.followers,
      );

      await cubit.load();
      await cubit.loadMore();

      final state = cubit.state as FollowListLoaded;
      expect(state.items.map((item) => item.id), ['1', '2', '3']);
      expect(state.hasMore, isFalse);
      await cubit.close();
    });

    test('a failed first page is its own state', () async {
      when(
        () => follows.list('uuid-carlos', FollowListKind.following),
      ).thenThrow(const NetworkFailure('offline'));
      final cubit = FollowListCubit(
        follows,
        'uuid-carlos',
        FollowListKind.following,
      );

      await cubit.load();

      expect(cubit.state, const FollowListFailure(offline: true));
      await cubit.close();
    });
  });
}
