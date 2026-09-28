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

/// Cursor keyset: el último elemento visto, ordenado por (createdAt, id).
abstract class PageCursor
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PageCursor._({
    required this.id,
    required this.createdAt,
  });

  factory PageCursor({
    required int id,
    required DateTime createdAt,
  }) = _PageCursorImpl;

  factory PageCursor.fromJson(Map<String, dynamic> jsonSerialization) {
    return PageCursor(
      id: jsonSerialization['id'] as int,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  DateTime createdAt;

  int id;

  /// Returns a shallow copy of this [PageCursor]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PageCursor copyWith({
    int? id,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PageCursor',
      'id': id,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PageCursor',
      'id': id,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _PageCursorImpl extends PageCursor {
  _PageCursorImpl({
    required int id,
    required DateTime createdAt,
  }) : super._(
         id: id,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [PageCursor]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PageCursor copyWith({
    int? id,
    DateTime? createdAt,
  }) {
    return PageCursor(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
