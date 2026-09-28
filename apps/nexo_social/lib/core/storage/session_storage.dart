import 'package:shared_preferences/shared_preferences.dart';

import 'session_storage_stub.dart'
    if (dart.library.js_interop) 'session_storage_web.dart'
    as impl;

/// Dónde se guarda la sesión mock.
///
/// En web va a `sessionStorage`, que es **de cada pestaña**. Con
/// `SharedPreferences` (o sea `localStorage`) dos pestañas comparten la
/// sesión, y la demo de dos pestañas —el operador en una, la cuenta
/// sancionada en la otra— no se puede hacer: loguearse en una cambia a la
/// otra. Fuera de web sigue en `SharedPreferences`.
abstract interface class SessionStorage {
  factory SessionStorage(SharedPreferences preferences) =
      impl.SessionStorageImpl;

  String? read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}
