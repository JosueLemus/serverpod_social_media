import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/theme_preference_repository.dart';

/// La preferencia en `SharedPreferences`. No pasa por `SessionStorage`: en web
/// ése guarda la sesión por pestaña, y el tema es del dispositivo.
class LocalThemePreferenceRepository implements ThemePreferenceRepository {
  LocalThemePreferenceRepository(this._preferences);

  final SharedPreferences _preferences;

  /// **No se renombra**: un teléfono con la clave vieja vuelve al tema por
  /// defecto sin avisar.
  static const _key = 'appearance.theme_id';

  @override
  String? read() => _preferences.getString(_key);

  @override
  Future<void> write(String themeId) async {
    await _preferences.setString(_key, themeId);
  }
}
