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

/// Cambios al perfil propio. `null` deja el campo como está.
abstract class ProfileEdit
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ProfileEdit._({
    this.username,
    this.displayName,
    this.bio,
    this.website,
  });

  factory ProfileEdit({
    String? username,
    String? displayName,
    String? bio,
    String? website,
  }) = _ProfileEditImpl;

  factory ProfileEdit.fromJson(Map<String, dynamic> jsonSerialization) {
    return ProfileEdit(
      username: jsonSerialization['username'] as String?,
      displayName: jsonSerialization['displayName'] as String?,
      bio: jsonSerialization['bio'] as String?,
      website: jsonSerialization['website'] as String?,
    );
  }

  String? username;

  String? displayName;

  String? bio;

  /// Vacío lo quita.
  String? website;

  /// Returns a shallow copy of this [ProfileEdit]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ProfileEdit copyWith({
    String? username,
    String? displayName,
    String? bio,
    String? website,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProfileEdit',
      if (username != null) 'username': username,
      if (displayName != null) 'displayName': displayName,
      if (bio != null) 'bio': bio,
      if (website != null) 'website': website,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ProfileEdit',
      if (username != null) 'username': username,
      if (displayName != null) 'displayName': displayName,
      if (bio != null) 'bio': bio,
      if (website != null) 'website': website,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProfileEditImpl extends ProfileEdit {
  _ProfileEditImpl({
    String? username,
    String? displayName,
    String? bio,
    String? website,
  }) : super._(
         username: username,
         displayName: displayName,
         bio: bio,
         website: website,
       );

  /// Returns a shallow copy of this [ProfileEdit]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ProfileEdit copyWith({
    Object? username = _Undefined,
    Object? displayName = _Undefined,
    Object? bio = _Undefined,
    Object? website = _Undefined,
  }) {
    return ProfileEdit(
      username: username is String? ? username : this.username,
      displayName: displayName is String? ? displayName : this.displayName,
      bio: bio is String? ? bio : this.bio,
      website: website is String? ? website : this.website,
    );
  }
}
