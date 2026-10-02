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
import '../../../modules/identity/models/profile_view.dart' as _iucarp80;

/// La cuenta de quien tiene la sesión: su perfil más lo que sólo ve ella.
/// Los roles los decide el servidor a partir de los scopes; el cliente los
/// lee de acá y nunca los elige.
abstract class AccountView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  AccountView._({
    required this.profile,
    this.email,
    required this.isModerator,
    required this.isAdmin,
  });

  factory AccountView({
    required _iucarp80.ProfileView profile,
    String? email,
    required bool isModerator,
    required bool isAdmin,
  }) = _AccountViewImpl;

  factory AccountView.fromJson(Map<String, dynamic> jsonSerialization) {
    return AccountView(
      profile: _i8p6m2v0.Protocol().deserialize<_iucarp80.ProfileView>(
        jsonSerialization['profile'],
      ),
      email: jsonSerialization['email'] as String?,
      isModerator: _is.BoolJsonExtension.fromJson(
        jsonSerialization['isModerator'],
      ),
      isAdmin: _is.BoolJsonExtension.fromJson(jsonSerialization['isAdmin']),
    );
  }

  _iucarp80.ProfileView profile;

  String? email;

  bool isModerator;

  bool isAdmin;

  /// Returns a shallow copy of this [AccountView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AccountView copyWith({
    _iucarp80.ProfileView? profile,
    String? email,
    bool? isModerator,
    bool? isAdmin,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AccountView',
      'profile': profile.toJson(),
      if (email != null) 'email': email,
      'isModerator': isModerator,
      'isAdmin': isAdmin,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AccountView',
      'profile': profile.toJsonForProtocol(),
      if (email != null) 'email': email,
      'isModerator': isModerator,
      'isAdmin': isAdmin,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AccountViewImpl extends AccountView {
  _AccountViewImpl({
    required _iucarp80.ProfileView profile,
    String? email,
    required bool isModerator,
    required bool isAdmin,
  }) : super._(
         profile: profile,
         email: email,
         isModerator: isModerator,
         isAdmin: isAdmin,
       );

  /// Returns a shallow copy of this [AccountView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AccountView copyWith({
    _iucarp80.ProfileView? profile,
    Object? email = _Undefined,
    bool? isModerator,
    bool? isAdmin,
  }) {
    return AccountView(
      profile: profile ?? this.profile.copyWith(),
      email: email is String? ? email : this.email,
      isModerator: isModerator ?? this.isModerator,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
