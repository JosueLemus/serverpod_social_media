import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/app_user.dart';

class AuthLocalDataSource {
  AuthLocalDataSource(this._preferences);
  final SharedPreferences _preferences;
  static const _key = 'mock_session';
  AppUser? read() {
    final raw = _preferences.getString(_key);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return AppUser(
      id: json['id'] as String,
      username: json['username'] as String,
      name: json['name'] as String,
      role: UserRole.values.byName(json['role'] as String),
    );
  }

  Future<void> save(AppUser user) => _preferences.setString(
    _key,
    jsonEncode({
      'id': user.id,
      'username': user.username,
      'name': user.name,
      'role': user.role.name,
    }),
  );
  Future<void> clear() => _preferences.remove(_key);
}
