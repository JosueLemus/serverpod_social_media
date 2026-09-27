import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_social/core/usecases/usecase.dart';
import 'package:nexo_social/features/feed/domain/entities/feed_status.dart';
import 'package:nexo_social/features/feed/domain/repositories/feed_repository.dart';
import 'package:nexo_social/features/feed/domain/usecases/get_feed_status.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  late MockFeedRepository repository;
  late GetFeedStatus useCase;
  setUp(() {
    repository = MockFeedRepository();
    useCase = GetFeedStatus(repository);
  });
  test('obtains status from the repository', () async {
    when(
      () => repository.getStatus(),
    ).thenAnswer((_) async => const FeedStatus(isReady: true));
    final result = await useCase(const NoParams());
    expect(result.isReady, isTrue);
    verify(() => repository.getStatus()).called(1);
  });
}
