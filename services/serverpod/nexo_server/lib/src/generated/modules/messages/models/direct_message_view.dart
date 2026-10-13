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

/// Un mensaje tal como lo ven los dos miembros. Quién es "yo" lo decide la
/// app comparando [authorId] con la sesión: el mismo evento va a los dos.
abstract class DirectMessageView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  DirectMessageView._({
    required this.id,
    required this.conversationId,
    required this.authorId,
    required this.body,
    required this.createdAt,
  });

  factory DirectMessageView({
    required int id,
    required int conversationId,
    required _is.UuidValue authorId,
    required String body,
    required DateTime createdAt,
  }) = _DirectMessageViewImpl;

  factory DirectMessageView.fromJson(Map<String, dynamic> jsonSerialization) {
    return DirectMessageView(
      id: jsonSerialization['id'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      authorId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['authorId'],
      ),
      body: jsonSerialization['body'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int id;

  int conversationId;

  _is.UuidValue authorId;

  String body;

  DateTime createdAt;

  /// Returns a shallow copy of this [DirectMessageView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DirectMessageView copyWith({
    int? id,
    int? conversationId,
    _is.UuidValue? authorId,
    String? body,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DirectMessageView',
      'id': id,
      'conversationId': conversationId,
      'authorId': authorId.toJson(),
      'body': body,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DirectMessageView',
      'id': id,
      'conversationId': conversationId,
      'authorId': authorId.toJson(),
      'body': body,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _DirectMessageViewImpl extends DirectMessageView {
  _DirectMessageViewImpl({
    required int id,
    required int conversationId,
    required _is.UuidValue authorId,
    required String body,
    required DateTime createdAt,
  }) : super._(
         id: id,
         conversationId: conversationId,
         authorId: authorId,
         body: body,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DirectMessageView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DirectMessageView copyWith({
    int? id,
    int? conversationId,
    _is.UuidValue? authorId,
    String? body,
    DateTime? createdAt,
  }) {
    return DirectMessageView(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      authorId: authorId ?? this.authorId,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
