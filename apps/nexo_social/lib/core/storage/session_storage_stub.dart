import 'package:shared_preferences/shared_preferences.dart';

import 'session_storage.dart';

class SessionStorageImpl implements SessionStorage {
  SessionStorageImpl(this._preferences);

  final SharedPreferences _preferences;

  @override
  String? read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> remove(String key) => _preferences.remove(key);
}
