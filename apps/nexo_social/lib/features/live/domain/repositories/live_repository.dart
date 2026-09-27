import '../entities/live_session.dart';

abstract interface class LiveRepository {
  Future<List<LiveSession>> list();
  Future<LiveSession> transition(String id, LiveStatus status);
}
