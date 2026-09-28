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
import '../../shared/errors/nexo_error_code.dart' as _iz6tle5p;

/// Error de negocio tipado. Nunca incluir datos sensibles: se envía al cliente.
abstract class NexoException
    implements
        _isc.SerializableException,
        _isc.SerializableModel,
        _isc.ProtocolSerialization {
  NexoException._({
    required this.code,
    required this.message,
  });

  factory NexoException({
    required _iz6tle5p.NexoErrorCode code,
    required String message,
  }) = _NexoExceptionImpl;

  factory NexoException.fromJson(Map<String, dynamic> jsonSerialization) {
    return NexoException(
      code: _iz6tle5p.NexoErrorCode.fromJson(
        (jsonSerialization['code'] as String),
      ),
      message: jsonSerialization['message'] as String,
    );
  }

  _iz6tle5p.NexoErrorCode code;

  String message;

  /// Returns a shallow copy of this [NexoException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  NexoException copyWith({
    _iz6tle5p.NexoErrorCode? code,
    String? message,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NexoException',
      'code': code.toJson(),
      'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'NexoException',
      'code': code.toJson(),
      'message': message,
    };
  }

  @override
  String toString() {
    return 'NexoException(code: $code, message: $message)';
  }
}

class _NexoExceptionImpl extends NexoException {
  _NexoExceptionImpl({
    required _iz6tle5p.NexoErrorCode code,
    required String message,
  }) : super._(
         code: code,
         message: message,
       );

  /// Returns a shallow copy of this [NexoException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  NexoException copyWith({
    _iz6tle5p.NexoErrorCode? code,
    String? message,
  }) {
    return NexoException(
      code: code ?? this.code,
      message: message ?? this.message,
    );
  }
}
