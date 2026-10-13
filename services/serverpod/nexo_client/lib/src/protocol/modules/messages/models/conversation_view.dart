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
import '../../../modules/identity/models/profile_view.dart' as _iucarp80;
import '../../../modules/messages/models/direct_message_view.dart' as _iuqibrgc;

/// Una conversación desde el punto de vista de quien pregunta: [other] es el
/// otro miembro y [unreadCount] lo que esta cuenta todavía no leyó.
abstract class ConversationView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ConversationView._({
    required this.id,
    required this.other,
    this.lastMessage,
    required this.unreadCount,
    required this.lastActivityAt,
  });

  factory ConversationView({
    required int id,
    required _iucarp80.ProfileView other,
    _iuqibrgc.DirectMessageView? lastMessage,
    required int unreadCount,
    required DateTime lastActivityAt,
  }) = _ConversationViewImpl;

  factory ConversationView.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConversationView(
      id: jsonSerialization['id'] as int,
      other: _il0t1g31.Protocol().deserialize<_iucarp80.ProfileView>(
        jsonSerialization['other'],
      ),
      lastMessage: jsonSerialization['lastMessage'] == null
          ? null
          : _il0t1g31.Protocol().deserialize<_iuqibrgc.DirectMessageView>(
              jsonSerialization['lastMessage'],
            ),
      unreadCount: jsonSerialization['unreadCount'] as int,
      lastActivityAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastActivityAt'],
      ),
    );
  }

  int id;

  _iucarp80.ProfileView other;

  _iuqibrgc.DirectMessageView? lastMessage;

  int unreadCount;

  DateTime lastActivityAt;

  /// Returns a shallow copy of this [ConversationView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ConversationView copyWith({
    int? id,
    _iucarp80.ProfileView? other,
    _iuqibrgc.DirectMessageView? lastMessage,
    int? unreadCount,
    DateTime? lastActivityAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConversationView',
      'id': id,
      'other': other.toJson(),
      if (lastMessage != null) 'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'lastActivityAt': lastActivityAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ConversationView',
      'id': id,
      'other': other.toJsonForProtocol(),
      if (lastMessage != null) 'lastMessage': lastMessage?.toJsonForProtocol(),
      'unreadCount': unreadCount,
      'lastActivityAt': lastActivityAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConversationViewImpl extends ConversationView {
  _ConversationViewImpl({
    required int id,
    required _iucarp80.ProfileView other,
    _iuqibrgc.DirectMessageView? lastMessage,
    required int unreadCount,
    required DateTime lastActivityAt,
  }) : super._(
         id: id,
         other: other,
         lastMessage: lastMessage,
         unreadCount: unreadCount,
         lastActivityAt: lastActivityAt,
       );

  /// Returns a shallow copy of this [ConversationView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ConversationView copyWith({
    int? id,
    _iucarp80.ProfileView? other,
    Object? lastMessage = _Undefined,
    int? unreadCount,
    DateTime? lastActivityAt,
  }) {
    return ConversationView(
      id: id ?? this.id,
      other: other ?? this.other.copyWith(),
      lastMessage: lastMessage is _iuqibrgc.DirectMessageView?
          ? lastMessage
          : this.lastMessage?.copyWith(),
      unreadCount: unreadCount ?? this.unreadCount,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }
}
