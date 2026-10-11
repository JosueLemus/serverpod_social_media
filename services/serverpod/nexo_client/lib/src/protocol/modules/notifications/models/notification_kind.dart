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

/// Qué pasó. La app decide el ícono y el texto; el servidor nunca manda
/// copy armada.
enum NotificationKind implements _isc.SerializableModel {
  newFollower,
  postLiked,
  postCommented,
  liveStarted,
  showStartingSoon,
  reportResolved;

  static NotificationKind fromJson(String name) {
    switch (name) {
      case 'newFollower':
        return NotificationKind.newFollower;
      case 'postLiked':
        return NotificationKind.postLiked;
      case 'postCommented':
        return NotificationKind.postCommented;
      case 'liveStarted':
        return NotificationKind.liveStarted;
      case 'showStartingSoon':
        return NotificationKind.showStartingSoon;
      case 'reportResolved':
        return NotificationKind.reportResolved;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "NotificationKind"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
