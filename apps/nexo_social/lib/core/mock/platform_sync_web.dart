import 'package:web/web.dart' as web;

import 'platform_sync.dart';

class PlatformSyncImpl implements PlatformSync {
  PlatformSyncImpl(String storageKey)
    // shared_preferences guarda cada clave con el prefijo `flutter.`.
    : _key = 'flutter.$storageKey';

  final String _key;

  /// `storage` sólo se dispara en las **otras** pestañas, nunca en la que
  /// escribió: justo lo que hace falta para no re-hidratar lo propio.
  @override
  Stream<void> get externalChanges => web.EventStreamProviders.storageEvent
      .forTarget(web.window)
      .where((event) => event.key == _key)
      .map((_) {});
}
