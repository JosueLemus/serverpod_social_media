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

/// En qué punto de su vida está un show. La máquina de estados vive en
/// `LiveRules.transitions`: el cliente sólo ofrece lo que el servidor acepta.
/// Mismos nombres que `LiveStatus` en la app.
enum LiveShowStatus implements _is.SerializableModel {
  draft,
  scheduled,
  live,
  ending,
  recorded,
  published,
  cancelled,
  failed,
  removed;

  static LiveShowStatus fromJson(String name) {
    switch (name) {
      case 'draft':
        return LiveShowStatus.draft;
      case 'scheduled':
        return LiveShowStatus.scheduled;
      case 'live':
        return LiveShowStatus.live;
      case 'ending':
        return LiveShowStatus.ending;
      case 'recorded':
        return LiveShowStatus.recorded;
      case 'published':
        return LiveShowStatus.published;
      case 'cancelled':
        return LiveShowStatus.cancelled;
      case 'failed':
        return LiveShowStatus.failed;
      case 'removed':
        return LiveShowStatus.removed;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "LiveShowStatus"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
