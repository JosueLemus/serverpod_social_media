enum DataSourceMode { mock, api }

abstract final class Environment {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const enableNetworkLogs = bool.fromEnvironment('NETWORK_LOGS');
  static const dataSource = String.fromEnvironment(
    'DATA_SOURCE',
    defaultValue: 'mock',
  );
  static DataSourceMode get dataSourceMode =>
      dataSource == 'api' ? DataSourceMode.api : DataSourceMode.mock;
}
