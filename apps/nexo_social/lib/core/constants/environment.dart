enum DataSourceMode { mock, api }

/// Authentication is deliberately independent from the source of timeline
/// data. This lets the hackathon keep its mock feed while accounts are real.
enum AuthSourceMode { mock, serverpod }

abstract final class Environment {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/',
  );
  static const enableNetworkLogs = bool.fromEnvironment('NETWORK_LOGS');
  static const dataSource = String.fromEnvironment(
    'DATA_SOURCE',
    defaultValue: 'mock',
  );
  static DataSourceMode get dataSourceMode =>
      dataSource == 'api' ? DataSourceMode.api : DataSourceMode.mock;

  /// Real authentication is the production default. Tests and the interactive
  /// demo opt into mock explicitly, never as a network-failure fallback.
  static const authSource = String.fromEnvironment(
    'AUTH_SOURCE',
    // TEMPORAL: 'mock' para validar Programar Show sin servidor. El default
    // real es 'serverpod' — revertir antes de commitear.
    defaultValue: 'mock',
  );
  static AuthSourceMode get authSourceMode =>
      authSource == 'mock' ? AuthSourceMode.mock : AuthSourceMode.serverpod;
}
