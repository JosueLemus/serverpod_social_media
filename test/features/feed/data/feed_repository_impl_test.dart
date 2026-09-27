import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_social/features/feed/data/datasources/feed_remote_data_source.dart';
import 'package:nexo_social/features/feed/data/repositories/feed_repository_impl.dart';

class MockRemoteDataSource extends Mock implements FeedRemoteDataSource {}

void main() {
  test('maps datasource availability to domain status', () async {
    final source = MockRemoteDataSource();
    when(() => source.healthCheck()).thenAnswer((_) async => true);
    final result = await FeedRepositoryImpl(source).getStatus();
    expect(result.isReady, isTrue);
  });
}
