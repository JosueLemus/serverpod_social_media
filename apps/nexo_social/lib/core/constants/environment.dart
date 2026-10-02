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

  /// App ID de Agora para el video de los vivos. Vacío = video simulado.
  ///
  /// En la etapa A del SDD 0005 el proyecto de Agora está en modo de prueba
  /// (sin certificado ni token). En la etapa B el token lo emite el servidor
  /// y este valor viene en su respuesta en lugar de compilarse.
  static const agoraAppId = String.fromEnvironment('AGORA_APP_ID');

  /// Contraseña de las cuentas sembradas por la demo local (`tool/demo.sh`).
  /// Con valor, el selector de cuentas demo entra contra el servidor real;
  /// vacío y en modo mock, entra contra el mock. En un build de producción
  /// no se define y el selector no existe.
  static const demoPassword = String.fromEnvironment('DEMO_PASSWORD');
  static const dataSource = String.fromEnvironment(
    'DATA_SOURCE',
    defaultValue: 'mock',
  );
  static DataSourceMode get dataSourceMode =>
      dataSource == 'api' ? DataSourceMode.api : DataSourceMode.mock;

  /// De dónde salen las cuentas. Nunca es un fallback ante un fallo de red:
  /// se elige al compilar.
  ///
  /// El default sigue en `mock` a propósito, hasta que vivos, moderación y
  /// la consola tengan backend: esas pantallas todavía leen la sesión de
  /// `MockPlatform`, y con una cuenta real la rechazan. Para probar el login
  /// real: `--dart-define=AUTH_SOURCE=serverpod`. Cuando esos módulos estén
  /// conectados, el default pasa a `serverpod`.
  static const authSource = String.fromEnvironment(
    'AUTH_SOURCE',
    defaultValue: 'mock',
  );
  static AuthSourceMode get authSourceMode =>
      authSource == 'mock' ? AuthSourceMode.mock : AuthSourceMode.serverpod;
}
