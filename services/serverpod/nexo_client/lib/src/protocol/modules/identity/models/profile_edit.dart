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

/// Cambios al perfil propio. `null` deja el campo como está.
abstract class ProfileEdit
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ProfileEdit._({
    this.username,
    this.displayName,
    this.bio,
  });

  factory ProfileEdit({
    String? username,
    String? displayName,
    String? bio,
  }) = _ProfileEditImpl;

  factory ProfileEdit.fromJson(Map<String, dynamic> jsonSerialization) {
    return ProfileEdit(
      username: jsonSerialization['username'] as String?,
      displayName: jsonSerialization['displayName'] as String?,
      bio: jsonSerialization['bio'] as String?,
    );
  }

  String? username;

  String? displayName;

  String? bio;

  /// Returns a shallow copy of this [ProfileEdit]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ProfileEdit copyWith({
    String? username,
    String? displayName,
    String? bio,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProfileEdit',
      if (username != null) 'username': username,
      if (displayName != null) 'displayName': displayName,
      if (bio != null) 'bio': bio,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ProfileEdit',
      if (username != null) 'username': username,
      if (displayName != null) 'displayName': displayName,
      if (bio != null) 'bio': bio,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProfileEditImpl extends ProfileEdit {
  _ProfileEditImpl({
    String? username,
    String? displayName,
    String? bio,
  }) : super._(
         username: username,
         displayName: displayName,
         bio: bio,
       );

  /// Returns a shallow copy of this [ProfileEdit]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ProfileEdit copyWith({
    Object? username = _Undefined,
    Object? displayName = _Undefined,
    Object? bio = _Undefined,
  }) {
    return ProfileEdit(
      username: username is String? ? username : this.username,
      displayName: displayName is String? ? displayName : this.displayName,
      bio: bio is String? ? bio : this.bio,
    );
  }
}
