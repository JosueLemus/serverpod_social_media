import 'platform_sync_stub.dart'
    if (dart.library.js_interop) 'platform_sync_web.dart'
    as impl;

/// Avisa cuando **otra pestaña** escribió el estado mock.
///
/// Existe sólo para la demo de dos pestañas: el operador suspende en una y la
/// otra, donde está la cuenta sancionada, tiene que enterarse sin recargar.
/// En web, las pestañas del mismo origen comparten `localStorage` y el
/// navegador dispara `storage` en las demás; fuera de web no hay otra
/// instancia con la que sincronizar y el stream no emite nunca.
///
/// El día que exista Serverpod esto se borra: el aviso llega por el stream
/// del servidor.
abstract interface class PlatformSync {
  factory PlatformSync(String storageKey) = impl.PlatformSyncImpl;

  Stream<void> get externalChanges;
}
