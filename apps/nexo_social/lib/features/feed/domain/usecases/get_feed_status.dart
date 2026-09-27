import '../../../../core/usecases/usecase.dart';
import '../entities/feed_status.dart';
import '../repositories/feed_repository.dart';

class GetFeedStatus implements UseCase<FeedStatus, NoParams> {
  const GetFeedStatus(this._repository);
  final FeedRepository _repository;
  @override
  Future<FeedStatus> call(NoParams params) => _repository.getStatus();
}
