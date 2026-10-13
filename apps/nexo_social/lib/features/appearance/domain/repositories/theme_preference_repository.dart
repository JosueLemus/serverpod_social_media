/// Qué tema eligió el usuario. Es una preferencia del dispositivo, no de la
/// cuenta: cerrar sesión no la borra, y dos cuentas en el mismo teléfono ven
/// el mismo tema.
abstract interface class ThemePreferenceRepository {
  /// El id guardado, o `null` si nunca eligió uno.
  ///
  /// Sincrónico a propósito: se lee antes del primer frame, para que la app
  /// no pinte un tema y salte a otro.
  String? read();

  Future<void> write(String themeId);
}
