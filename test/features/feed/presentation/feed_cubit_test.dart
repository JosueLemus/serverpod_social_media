import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_social/core/usecases/usecase.dart';
import 'package:nexo_social/features/feed/domain/entities/feed_status.dart';
import 'package:nexo_social/features/feed/domain/usecases/get_feed_status.dart';
import 'package:nexo_social/features/feed/presentation/bloc/feed_cubit.dart';

class MockGetFeedStatus extends Mock implements GetFeedStatus {}

void main() {
  blocTest<FeedCubit, FeedState>(
    'emits loading then posts when service is available',
    build: () {
      final useCase = MockGetFeedStatus();
      when(
        () => useCase(const NoParams()),
      ).thenAnswer((_) async => const FeedStatus(isReady: true));
      return FeedCubit(useCase);
    },
    act: (cubit) => cubit.checkStatus(),
    expect: () => [isA<FeedLoading>(), isA<FeedLoaded>()],
  );
}
