import 'package:image_picker/image_picker.dart';

import '../../features/feed/domain/entities/post.dart';
import '../../features/feed/domain/entities/post_extras.dart';

/// Elegir una foto o un video del dispositivo. Una interfaz para que el
/// compositor no toque el plugin (y los tests no abran una galería).
abstract interface class MediaPicker {
  /// Null si la persona cerró el selector sin elegir.
  Future<MediaAttachment?> pick(PostMedia kind);
}

class DeviceMediaPicker implements MediaPicker {
  DeviceMediaPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<MediaAttachment?> pick(PostMedia kind) async {
    final file = switch (kind) {
      // Se achica en el dispositivo: una foto de 12 MP pesa más que el
      // límite del servidor y nadie la ve a ese tamaño en un feed.
      PostMedia.image => await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        imageQuality: 85,
      ),
      PostMedia.video => await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      ),
    };
    if (file == null) return null;
    return MediaAttachment(
      kind: kind,
      bytes: await file.readAsBytes(),
      contentType: file.mimeType ?? contentTypeFor(file.name),
      fileName: file.name,
    );
  }

  /// Algunas plataformas no informan el tipo: se deduce de la extensión.
  static String contentTypeFor(String fileName) =>
      switch (fileName.split('.').last.toLowerCase()) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        'mp4' => 'video/mp4',
        'mov' => 'video/quicktime',
        'webm' => 'video/webm',
        _ => 'application/octet-stream',
      };
}
