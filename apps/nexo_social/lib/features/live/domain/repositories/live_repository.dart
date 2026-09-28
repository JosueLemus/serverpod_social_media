import '../entities/live_session.dart';

abstract interface class LiveRepository {
  Future<List<LiveSession>> list();

  /// Null when the id does not resolve — a deep link to a removed session is
  /// a normal case, not an error the room should crash on.
  Future<LiveSession?> byId(String id);

  Future<LiveSession> transition(String id, LiveStatus status);
}
