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
import 'package:serverpod/serverpod.dart' as _is;

/// Códigos de error de negocio que el cliente puede mapear a un Failure.
enum NexoErrorCode implements _is.SerializableModel {
  unauthenticated,
  forbidden,
  notFound,
  conflict,
  invalidInput,
  rateLimited;

  static NexoErrorCode fromJson(String name) {
    switch (name) {
      case 'unauthenticated':
        return NexoErrorCode.unauthenticated;
      case 'forbidden':
        return NexoErrorCode.forbidden;
      case 'notFound':
        return NexoErrorCode.notFound;
      case 'conflict':
        return NexoErrorCode.conflict;
      case 'invalidInput':
        return NexoErrorCode.invalidInput;
      case 'rateLimited':
        return NexoErrorCode.rateLimited;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "NexoErrorCode"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
