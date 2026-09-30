import '../../../../../domain/entities/live_session.dart';
import '../entities/show_draft.dart';

abstract interface class ShowScheduleRepository {
  Future<ShowDraft?> loadDraft();

  Future<void> saveDraft(ShowDraft draft);

  Future<void> clearDraft();

  Future<ShowGuest> findGuest(String username);

  Future<LiveSession> schedule(ShowDraft draft);
}
