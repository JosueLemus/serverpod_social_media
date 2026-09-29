import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

import 'session_storage.dart';

class SessionStorageImpl implements SessionStorage {
  // Las preferencias no se usan en web: la sesión es de la pestaña.
  SessionStorageImpl(SharedPreferences _);

  @override
  String? read(String key) => web.window.sessionStorage.getItem(key);

  @override
  Future<void> write(String key, String value) async =>
      web.window.sessionStorage.setItem(key, value);

  @override
  Future<void> remove(String key) async =>
      web.window.sessionStorage.removeItem(key);
}
