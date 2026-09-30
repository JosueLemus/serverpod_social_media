import '../../../../../../../core/usecases/usecase.dart';
import '../../../../../domain/entities/live_session.dart';
import '../entities/show_draft.dart';
import '../repositories/show_schedule_repository.dart';

class ScheduleShow implements UseCase<LiveSession, ShowDraft> {
  const ScheduleShow(this._repository);

  final ShowScheduleRepository _repository;

  @override
  Future<LiveSession> call(ShowDraft draft) async {
    final session = await _repository.schedule(draft);
    await _repository.clearDraft();
    return session;
  }
}
