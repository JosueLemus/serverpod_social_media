import 'package:serverpod/serverpod.dart';

/// Endpoint público para comprobar que el servidor responde.
/// Desde Flutter: `client.health.ping()`.
class HealthEndpoint extends Endpoint {
  Future<String> ping(Session session) async => 'ok';
}
