import 'dart:convert';

import '../../../../core/storage/session_storage.dart';

/// Guarda **qué cuenta** tiene la sesión, no la cuenta en sí.
///
/// Guardar el usuario entero congelaba su rol y su estado al momento del
/// login: una cuenta suspendida o desverificada seguía restaurándose como
/// estaba. La cuenta se resuelve siempre contra la fuente de verdad.
class AuthLocalDataSource {
  AuthLocalDataSource(this._storage);
  final SessionStorage _storage;
  static const _key = 'mock_session';

  String? readAccountId() {
    final raw = _storage.read(_key);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as Map<String, dynamic>)['id'] as String?;
    } on FormatException {
      return null;
    }
  }

  Future<void> save(String accountId) =>
      _storage.write(_key, jsonEncode({'id': accountId}));

  Future<void> clear() => _storage.remove(_key);
}
