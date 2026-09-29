import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

/// Bridges Serverpod's official serialised-session storage contract to the
/// platform secure store. The namespace prevents a development token for one
/// backend being restored against another backend.
class ServerpodSecureKeyValueStorage implements KeyValueStorage {
  ServerpodSecureKeyValueStorage(this._storage, {required String apiBaseUrl})
    : _namespace = base64Url
          .encode(utf8.encode(apiBaseUrl))
          .replaceAll('=', '');

  final FlutterSecureStorage _storage;
  final String _namespace;

  String _key(String key) => 'nexo.auth.$_namespace.$key';

  @override
  Future<String?> get(String key) => _storage.read(key: _key(key));

  @override
  Future<void> set(String key, String? value) => value == null
      ? _storage.delete(key: _key(key))
      : _storage.write(key: _key(key), value: value);
}
