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

/// La decide el servidor según el motivo, nunca quien reporta. Se guarda
/// por índice para que ordenar la cola sea ordenar un número.
enum ReportSeverity implements _isc.SerializableModel {
  low,
  medium,
  high;

  static ReportSeverity fromJson(int index) {
    switch (index) {
      case 0:
        return ReportSeverity.low;
      case 1:
        return ReportSeverity.medium;
      case 2:
        return ReportSeverity.high;
      default:
        throw ArgumentError(
          'Value "$index" cannot be converted to "ReportSeverity"',
        );
    }
  }

  @override
  int toJson() => index;

  @override
  String toString() => name;
}
