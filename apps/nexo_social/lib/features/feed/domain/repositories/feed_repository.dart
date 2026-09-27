import '../entities/feed_status.dart';

abstract interface class FeedRepository {
  Future<FeedStatus> getStatus();
}
