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
import 'package:nexo_server/src/generated/protocol.dart' as _i8p6m2v0;
import 'package:serverpod/serverpod.dart' as _is;
import '../../../modules/notifications/models/notification_view.dart'
    as _i5xslsmj;
import '../../../shared/pagination/page_cursor.dart' as _i1sbovtz;

/// Avisos de la más nueva a la más vieja. [nextCursor] es `null` cuando no
/// hay más.
abstract class NotificationPage
    implements _is.SerializableModel, _is.ProtocolSerialization {
  NotificationPage._({
    required this.items,
    this.nextCursor,
  });

  factory NotificationPage({
    required List<_i5xslsmj.NotificationView> items,
    _i1sbovtz.PageCursor? nextCursor,
  }) = _NotificationPageImpl;

  factory NotificationPage.fromJson(Map<String, dynamic> jsonSerialization) {
    return NotificationPage(
      items: _i8p6m2v0.Protocol().deserialize<List<_i5xslsmj.NotificationView>>(
        jsonSerialization['items'],
      ),
      nextCursor: jsonSerialization['nextCursor'] == null
          ? null
          : _i8p6m2v0.Protocol().deserialize<_i1sbovtz.PageCursor>(
              jsonSerialization['nextCursor'],
            ),
    );
  }

  List<_i5xslsmj.NotificationView> items;

  _i1sbovtz.PageCursor? nextCursor;

  /// Returns a shallow copy of this [NotificationPage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  NotificationPage copyWith({
    List<_i5xslsmj.NotificationView>? items,
    _i1sbovtz.PageCursor? nextCursor,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NotificationPage',
      'items': items.toJson(valueToJson: (v) => v.toJson()),
      if (nextCursor != null) 'nextCursor': nextCursor?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'NotificationPage',
      'items': items.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (nextCursor != null) 'nextCursor': nextCursor?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _NotificationPageImpl extends NotificationPage {
  _NotificationPageImpl({
    required List<_i5xslsmj.NotificationView> items,
    _i1sbovtz.PageCursor? nextCursor,
  }) : super._(
         items: items,
         nextCursor: nextCursor,
       );

  /// Returns a shallow copy of this [NotificationPage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  NotificationPage copyWith({
    List<_i5xslsmj.NotificationView>? items,
    Object? nextCursor = _Undefined,
  }) {
    return NotificationPage(
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
      nextCursor: nextCursor is _i1sbovtz.PageCursor?
          ? nextCursor
          : this.nextCursor?.copyWith(),
    );
  }
}
