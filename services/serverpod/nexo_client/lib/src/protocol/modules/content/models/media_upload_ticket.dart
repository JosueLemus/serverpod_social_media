/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// Permiso para subir un archivo. El cliente lo sube con
/// `FileUploader(uploadDescription)` y después publica con [key].
abstract class MediaUploadTicket
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  MediaUploadTicket._({
    required this.key,
    required this.uploadDescription,
    required this.maxBytes,
  });

  factory MediaUploadTicket({
    required String key,
    required String uploadDescription,
    required int maxBytes,
  }) = _MediaUploadTicketImpl;

  factory MediaUploadTicket.fromJson(Map<String, dynamic> jsonSerialization) {
    return MediaUploadTicket(
      key: jsonSerialization['key'] as String,
      uploadDescription: jsonSerialization['uploadDescription'] as String,
      maxBytes: jsonSerialization['maxBytes'] as int,
    );
  }

  String key;

  String uploadDescription;

  int maxBytes;

  /// Returns a shallow copy of this [MediaUploadTicket]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MediaUploadTicket copyWith({
    String? key,
    String? uploadDescription,
    int? maxBytes,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MediaUploadTicket',
      'key': key,
      'uploadDescription': uploadDescription,
      'maxBytes': maxBytes,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MediaUploadTicket',
      'key': key,
      'uploadDescription': uploadDescription,
      'maxBytes': maxBytes,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _MediaUploadTicketImpl extends MediaUploadTicket {
  _MediaUploadTicketImpl({
    required String key,
    required String uploadDescription,
    required int maxBytes,
  }) : super._(
         key: key,
         uploadDescription: uploadDescription,
         maxBytes: maxBytes,
       );

  /// Returns a shallow copy of this [MediaUploadTicket]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MediaUploadTicket copyWith({
    String? key,
    String? uploadDescription,
    int? maxBytes,
  }) {
    return MediaUploadTicket(
      key: key ?? this.key,
      uploadDescription: uploadDescription ?? this.uploadDescription,
      maxBytes: maxBytes ?? this.maxBytes,
    );
  }
}
