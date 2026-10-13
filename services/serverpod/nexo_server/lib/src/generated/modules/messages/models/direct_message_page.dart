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
import '../../../modules/messages/models/direct_message_view.dart' as _iuqibrgc;

/// Un tramo de la historia, del mensaje más viejo al más nuevo. [hasMore]
/// dice si hay anteriores al primero.
abstract class DirectMessagePage
    implements _is.SerializableModel, _is.ProtocolSerialization {
  DirectMessagePage._({
    required this.items,
    required this.hasMore,
  });

  factory DirectMessagePage({
    required List<_iuqibrgc.DirectMessageView> items,
    required bool hasMore,
  }) = _DirectMessagePageImpl;

  factory DirectMessagePage.fromJson(Map<String, dynamic> jsonSerialization) {
    return DirectMessagePage(
      items: _i8p6m2v0.Protocol()
          .deserialize<List<_iuqibrgc.DirectMessageView>>(
            jsonSerialization['items'],
          ),
      hasMore: _is.BoolJsonExtension.fromJson(jsonSerialization['hasMore']),
    );
  }

  List<_iuqibrgc.DirectMessageView> items;

  bool hasMore;

  /// Returns a shallow copy of this [DirectMessagePage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DirectMessagePage copyWith({
    List<_iuqibrgc.DirectMessageView>? items,
    bool? hasMore,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DirectMessagePage',
      'items': items.toJson(valueToJson: (v) => v.toJson()),
      'hasMore': hasMore,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DirectMessagePage',
      'items': items.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'hasMore': hasMore,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _DirectMessagePageImpl extends DirectMessagePage {
  _DirectMessagePageImpl({
    required List<_iuqibrgc.DirectMessageView> items,
    required bool hasMore,
  }) : super._(
         items: items,
         hasMore: hasMore,
       );

  /// Returns a shallow copy of this [DirectMessagePage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DirectMessagePage copyWith({
    List<_iuqibrgc.DirectMessageView>? items,
    bool? hasMore,
  }) {
    return DirectMessagePage(
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
      hasMore: hasMore ?? this.hasMore,
    );
  }
}
