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

/// Un mensaje del chat tal como lo ve cualquiera.
abstract class LiveChatMessageView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  LiveChatMessageView._({
    required this.id,
    required this.showId,
    required this.authorId,
    this.authorUsername,
    this.authorName,
    this.authorAvatarUrl,
    required this.body,
    required this.createdAt,
  });

  factory LiveChatMessageView({
    required int id,
    required int showId,
    required _isc.UuidValue authorId,
    String? authorUsername,
    String? authorName,
    String? authorAvatarUrl,
    required String body,
    required DateTime createdAt,
  }) = _LiveChatMessageViewImpl;

  factory LiveChatMessageView.fromJson(Map<String, dynamic> jsonSerialization) {
    return LiveChatMessageView(
      id: jsonSerialization['id'] as int,
      showId: jsonSerialization['showId'] as int,
      authorId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['authorId'],
      ),
      authorUsername: jsonSerialization['authorUsername'] as String?,
      authorName: jsonSerialization['authorName'] as String?,
      authorAvatarUrl: jsonSerialization['authorAvatarUrl'] as String?,
      body: jsonSerialization['body'] as String,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int id;

  int showId;

  _isc.UuidValue authorId;

  String? authorUsername;

  String? authorName;

  String? authorAvatarUrl;

  String body;

  DateTime createdAt;

  /// Returns a shallow copy of this [LiveChatMessageView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LiveChatMessageView copyWith({
    int? id,
    int? showId,
    _isc.UuidValue? authorId,
    String? authorUsername,
    String? authorName,
    String? authorAvatarUrl,
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
      if (authorAvatarUrl != null) 'authorAvatarUrl': authorAvatarUrl,
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
      if (authorAvatarUrl != null) 'authorAvatarUrl': authorAvatarUrl,
      'body': body,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LiveChatMessageViewImpl extends LiveChatMessageView {
  _LiveChatMessageViewImpl({
    required int id,
    required int showId,
    required _isc.UuidValue authorId,
    String? authorUsername,
    String? authorName,
    String? authorAvatarUrl,
    required String body,
    required DateTime createdAt,
  }) : super._(
         id: id,
         showId: showId,
         authorId: authorId,
         authorUsername: authorUsername,
         authorName: authorName,
         authorAvatarUrl: authorAvatarUrl,
         body: body,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [LiveChatMessageView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LiveChatMessageView copyWith({
    int? id,
    int? showId,
    _isc.UuidValue? authorId,
    Object? authorUsername = _Undefined,
    Object? authorName = _Undefined,
    Object? authorAvatarUrl = _Undefined,
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
      authorAvatarUrl: authorAvatarUrl is String?
          ? authorAvatarUrl
          : this.authorAvatarUrl,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
