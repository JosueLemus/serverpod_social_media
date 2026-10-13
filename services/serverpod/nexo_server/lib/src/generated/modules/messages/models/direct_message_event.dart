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
import '../../../modules/messages/models/direct_message_event_kind.dart'
    as _ijugnibb;
import '../../../modules/messages/models/direct_message_view.dart' as _iuqibrgc;

/// Lo que llega por `messages.watch()`. [unreadConversations] es el total de
/// quien lo recibe, así el badge cambia sin otra consulta (SDD 0010, M8).
abstract class DirectMessageEvent
    implements _is.SerializableModel, _is.ProtocolSerialization {
  DirectMessageEvent._({
    required this.kind,
    required this.conversationId,
    this.message,
    this.readerId,
    this.lastReadMessageId,
    required this.unreadConversations,
  });

  factory DirectMessageEvent({
    required _ijugnibb.DirectMessageEventKind kind,
    required int conversationId,
    _iuqibrgc.DirectMessageView? message,
    _is.UuidValue? readerId,
    int? lastReadMessageId,
    required int unreadConversations,
  }) = _DirectMessageEventImpl;

  factory DirectMessageEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return DirectMessageEvent(
      kind: _ijugnibb.DirectMessageEventKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      conversationId: jsonSerialization['conversationId'] as int,
      message: jsonSerialization['message'] == null
          ? null
          : _i8p6m2v0.Protocol().deserialize<_iuqibrgc.DirectMessageView>(
              jsonSerialization['message'],
            ),
      readerId: jsonSerialization['readerId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['readerId']),
      lastReadMessageId: jsonSerialization['lastReadMessageId'] as int?,
      unreadConversations: jsonSerialization['unreadConversations'] as int,
    );
  }

  _ijugnibb.DirectMessageEventKind kind;

  int conversationId;

  /// Con `message`: el mensaje nuevo.
  _iuqibrgc.DirectMessageView? message;

  /// Con `read`: quién leyó y hasta qué mensaje.
  _is.UuidValue? readerId;

  int? lastReadMessageId;

  int unreadConversations;

  /// Returns a shallow copy of this [DirectMessageEvent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DirectMessageEvent copyWith({
    _ijugnibb.DirectMessageEventKind? kind,
    int? conversationId,
    _iuqibrgc.DirectMessageView? message,
    _is.UuidValue? readerId,
    int? lastReadMessageId,
    int? unreadConversations,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DirectMessageEvent',
      'kind': kind.toJson(),
      'conversationId': conversationId,
      if (message != null) 'message': message?.toJson(),
      if (readerId != null) 'readerId': readerId?.toJson(),
      if (lastReadMessageId != null) 'lastReadMessageId': lastReadMessageId,
      'unreadConversations': unreadConversations,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DirectMessageEvent',
      'kind': kind.toJson(),
      'conversationId': conversationId,
      if (message != null) 'message': message?.toJsonForProtocol(),
      if (readerId != null) 'readerId': readerId?.toJson(),
      if (lastReadMessageId != null) 'lastReadMessageId': lastReadMessageId,
      'unreadConversations': unreadConversations,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DirectMessageEventImpl extends DirectMessageEvent {
  _DirectMessageEventImpl({
    required _ijugnibb.DirectMessageEventKind kind,
    required int conversationId,
    _iuqibrgc.DirectMessageView? message,
    _is.UuidValue? readerId,
    int? lastReadMessageId,
    required int unreadConversations,
  }) : super._(
         kind: kind,
         conversationId: conversationId,
         message: message,
         readerId: readerId,
         lastReadMessageId: lastReadMessageId,
         unreadConversations: unreadConversations,
       );

  /// Returns a shallow copy of this [DirectMessageEvent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DirectMessageEvent copyWith({
    _ijugnibb.DirectMessageEventKind? kind,
    int? conversationId,
    Object? message = _Undefined,
    Object? readerId = _Undefined,
    Object? lastReadMessageId = _Undefined,
    int? unreadConversations,
  }) {
    return DirectMessageEvent(
      kind: kind ?? this.kind,
      conversationId: conversationId ?? this.conversationId,
      message: message is _iuqibrgc.DirectMessageView?
          ? message
          : this.message?.copyWith(),
      readerId: readerId is _is.UuidValue? ? readerId : this.readerId,
      lastReadMessageId: lastReadMessageId is int?
          ? lastReadMessageId
          : this.lastReadMessageId,
      unreadConversations: unreadConversations ?? this.unreadConversations,
    );
  }
}
