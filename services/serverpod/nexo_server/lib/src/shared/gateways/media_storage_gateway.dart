import 'package:serverpod/serverpod.dart';

/// Subida y lectura de archivos mediante URLs firmadas.
/// La base de datos guarda solo la clave y los metadatos, nunca el binario.
abstract interface class MediaStorageGateway {
  /// Devuelve la descripción de subida directa que usa el cliente, o `null`
  /// si el almacenamiento no la soporta. La subida se rechaza si el archivo
  /// no mide exactamente [contentLength] bytes o supera [maxBytes].
  Future<String?> createUploadDescription(
    Session session,
    String key, {
    required String contentType,
    required int contentLength,
    required int maxBytes,
  });

  /// Confirma que el archivo existe tras la subida.
  Future<bool> verifyUpload(Session session, String key);

  Future<Uri?> publicUrl(Session session, String key);
}
