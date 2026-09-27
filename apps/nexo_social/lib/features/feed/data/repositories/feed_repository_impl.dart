import '../../domain/entities/feed_status.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_remote_data_source.dart';

class FeedRepositoryImpl implements FeedRepository {
  const FeedRepositoryImpl(this._remote);
  final FeedRemoteDataSource _remote;
  @override
  Future<FeedStatus> getStatus() async =>
      FeedStatus(isReady: await _remote.healthCheck());
}
