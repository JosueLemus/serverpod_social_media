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

/// Un mensaje del chat tal como lo ve cualquiera.
abstract class LiveChatMessageView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  LiveChatMessageView._({
    required this.id,
    required this.showId,
    required this.authorId,
    this.authorUsername,
    this.authorName,
    required this.body,
    required this.createdAt,
  });

  factory LiveChatMessageView({
    required int id,
    required int showId,
    required _is.UuidValue authorId,
    String? authorUsername,
    String? authorName,
    required String body,
    required DateTime createdAt,
  }) = _LiveChatMessageViewImpl;

  factory LiveChatMessageView.fromJson(Map<String, dynamic> jsonSerialization) {
    return LiveChatMessageView(
      id: jsonSerialization['id'] as int,
      showId: jsonSerialization['showId'] as int,
      authorId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['authorId'],
      ),
      authorUsername: jsonSerialization['authorUsername'] as String?,
      authorName: jsonSerialization['authorName'] as String?,
      body: jsonSerialization['body'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int id;

  int showId;

  _is.UuidValue authorId;

  String? authorUsername;

  String? authorName;

  String body;

  DateTime createdAt;

  /// Returns a shallow copy of this [LiveChatMessageView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  LiveChatMessageView copyWith({
    int? id,
    int? showId,
    _is.UuidValue? authorId,
    String? authorUsername,
    String? authorName,
    String? body,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LiveChatMessageView',
      'id': id,
      'showId': showId,
      'authorId': authorId.toJson(),
      if (authorUsername != null) 'authorUsername': authorUsername,
      if (authorName != null) 'authorName': authorName,
      'body': body,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LiveChatMessageView',
      'id': id,
      'showId': showId,
      'authorId': authorId.toJson(),
      if (authorUsername != null) 'authorUsername': authorUsername,
      if (authorName != null) 'authorName': authorName,
      'body': body,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LiveChatMessageViewImpl extends LiveChatMessageView {
  _LiveChatMessageViewImpl({
    required int id,
    required int showId,
    required _is.UuidValue authorId,
    String? authorUsername,
    String? authorName,
    required String body,
    required DateTime createdAt,
  }) : super._(
         id: id,
         showId: showId,
         authorId: authorId,
         authorUsername: authorUsername,
         authorName: authorName,
         body: body,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [LiveChatMessageView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  LiveChatMessageView copyWith({
    int? id,
    int? showId,
    _is.UuidValue? authorId,
    Object? authorUsername = _Undefined,
    Object? authorName = _Undefined,
    String? body,
    DateTime? createdAt,
  }) {
    return LiveChatMessageView(
      id: id ?? this.id,
      showId: showId ?? this.showId,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername is String?
          ? authorUsername
          : this.authorUsername,
      authorName: authorName is String? ? authorName : this.authorName,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
