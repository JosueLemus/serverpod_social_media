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
import 'package:nexo_client/src/protocol/protocol.dart' as _il0t1g31;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../../../modules/messages/models/conversation_view.dart' as _i4ynv3xj;
import '../../../shared/pagination/page_cursor.dart' as _i1sbovtz;

/// La bandeja, de la conversación con actividad más reciente a la más vieja.
/// [nextCursor] es `null` cuando no hay más.
abstract class ConversationPage
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ConversationPage._({
    required this.items,
    this.nextCursor,
  });

  factory ConversationPage({
    required List<_i4ynv3xj.ConversationView> items,
    _i1sbovtz.PageCursor? nextCursor,
  }) = _ConversationPageImpl;

  factory ConversationPage.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConversationPage(
      items: _il0t1g31.Protocol().deserialize<List<_i4ynv3xj.ConversationView>>(
        jsonSerialization['items'],
      ),
      nextCursor: jsonSerialization['nextCursor'] == null
          ? null
          : _il0t1g31.Protocol().deserialize<_i1sbovtz.PageCursor>(
              jsonSerialization['nextCursor'],
            ),
    );
  }

  List<_i4ynv3xj.ConversationView> items;

  _i1sbovtz.PageCursor? nextCursor;

  /// Returns a shallow copy of this [ConversationPage]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ConversationPage copyWith({
    List<_i4ynv3xj.ConversationView>? items,
    _i1sbovtz.PageCursor? nextCursor,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationPage',
      'items': items.toJson(valueToJson: (v) => v.toJson()),
      if (nextCursor != null) 'nextCursor': nextCursor?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConversationPage',
      'items': items.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (nextCursor != null) 'nextCursor': nextCursor?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationPageImpl extends ConversationPage {
  _ConversationPageImpl({
    required List<_i4ynv3xj.ConversationView> items,
    _i1sbovtz.PageCursor? nextCursor,
  }) : super._(
         items: items,
         nextCursor: nextCursor,
       );

  /// Returns a shallow copy of this [ConversationPage]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ConversationPage copyWith({
    List<_i4ynv3xj.ConversationView>? items,
    Object? nextCursor = _Undefined,
  }) {
    return ConversationPage(
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
      nextCursor: nextCursor is _i1sbovtz.PageCursor?
          ? nextCursor
          : this.nextCursor?.copyWith(),
    );
  }
}
