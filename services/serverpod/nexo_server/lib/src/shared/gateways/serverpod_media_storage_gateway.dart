import 'package:serverpod/serverpod.dart';

import 'media_storage_gateway.dart';

/// [MediaStorageGateway] sobre el storage configurado en `server.dart`:
/// Serverpod Cloud en producción y la base de datos en desarrollo y tests.
class ServerpodMediaStorageGateway implements MediaStorageGateway {
  const ServerpodMediaStorageGateway({this.storageId = 'public'});

  final String storageId;

  @override
  Future<String?> createUploadDescription(
    Session session,
    String key, {
    required String contentType,
    required int contentLength,
    required int maxBytes,
  }) async {
    try {
      return await session.storage.createUploadDescription(
        storageId: storageId,
        path: key,
        options: UploadOptions(
          maxFileSize: maxBytes,
          contentLength: contentLength,
          preventOverwrite: true,
          metadata: FileMetadata(contentType: contentType),
        ),
      );
    } on CloudStorageUnsupportedOperationException {
      return null;
    }
  }

  /// `storage.verifyUpload` solo devuelve `true` la primera vez que confirma
  /// un archivo. Si el cliente reintenta publicar después de un fallo, el
  /// archivo ya está confirmado y lo que hay que preguntar es si existe.
  @override
  Future<bool> verifyUpload(Session session, String key) async =>
      await session.storage.verifyUpload(storageId: storageId, path: key) ||
      await session.storage.fileExists(storageId: storageId, path: key);

  @override
  Future<Uri?> publicUrl(Session session, String key) async {
    try {
      return await session.storage.publicDownloadUrl(
        storageId: storageId,
        path: key,
      );
    } on CloudStorageFileNotFoundException {
      return null;
    }
  }
}
