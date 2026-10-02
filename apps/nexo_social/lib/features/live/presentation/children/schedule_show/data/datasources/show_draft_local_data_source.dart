import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/show_draft.dart';

// TODO(backend): definir si el borrador queda local o pasa a ser una
// LiveSession en `draft` en Serverpod (sincroniza entre dispositivos).
class ShowDraftLocalDataSource {
  const ShowDraftLocalDataSource(this._preferences);

  final SharedPreferences _preferences;

  static String _key(String accountId) => 'show_draft_v1_$accountId';

  ShowDraft? read(String accountId) {
    final raw = _preferences.getString(_key(accountId));
    if (raw == null) return null;
    try {
      return ShowDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  Future<void> write(String accountId, ShowDraft draft) =>
      _preferences.setString(_key(accountId), jsonEncode(draft.toJson()));

  Future<void> clear(String accountId) => _preferences.remove(_key(accountId));
}
