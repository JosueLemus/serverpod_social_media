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
import '../../../modules/identity/models/account_status.dart' as _ijvat8p8;
import '../../../modules/identity/models/verification_status.dart' as _il3i3d2n;

/// El perfil público de una cuenta, tal como lo ve cualquiera.
abstract class ProfileView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ProfileView._({
    required this.userId,
    required this.username,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    required this.isCreator,
    required this.verification,
    required this.status,
    required this.createdAt,
  });

  factory ProfileView({
    required _isc.UuidValue userId,
    required String username,
    required String displayName,
    String? bio,
    String? avatarUrl,
    required bool isCreator,
    required _il3i3d2n.VerificationStatus verification,
    required _ijvat8p8.AccountStatus status,
    required DateTime createdAt,
  }) = _ProfileViewImpl;

  factory ProfileView.fromJson(Map<String, dynamic> jsonSerialization) {
    return ProfileView(
      userId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      username: jsonSerialization['username'] as String,
      displayName: jsonSerialization['displayName'] as String,
      bio: jsonSerialization['bio'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      isCreator: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['isCreator'],
      ),
      verification: _il3i3d2n.VerificationStatus.fromJson(
        (jsonSerialization['verification'] as String),
      ),
      status: _ijvat8p8.AccountStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  _isc.UuidValue userId;

  String username;

  String displayName;

  String? bio;

  String? avatarUrl;

  bool isCreator;

  _il3i3d2n.VerificationStatus verification;

  /// Público a propósito: una sanción que no se ve desde afuera no se puede
  /// demostrar.
  _ijvat8p8.AccountStatus status;

  DateTime createdAt;

  /// Returns a shallow copy of this [ProfileView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ProfileView copyWith({
    _isc.UuidValue? userId,
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
    bool? isCreator,
    _il3i3d2n.VerificationStatus? verification,
    _ijvat8p8.AccountStatus? status,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProfileView',
      'userId': userId.toJson(),
      'username': username,
      'displayName': displayName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'isCreator': isCreator,
      'verification': verification.toJson(),
      'status': status.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ProfileView',
      'userId': userId.toJson(),
      'username': username,
      'displayName': displayName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'isCreator': isCreator,
      'verification': verification.toJson(),
      'status': status.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProfileViewImpl extends ProfileView {
  _ProfileViewImpl({
    required _isc.UuidValue userId,
    required String username,
    required String displayName,
    String? bio,
    String? avatarUrl,
    required bool isCreator,
    required _il3i3d2n.VerificationStatus verification,
    required _ijvat8p8.AccountStatus status,
    required DateTime createdAt,
  }) : super._(
         userId: userId,
         username: username,
         displayName: displayName,
         bio: bio,
         avatarUrl: avatarUrl,
         isCreator: isCreator,
         verification: verification,
         status: status,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ProfileView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ProfileView copyWith({
    _isc.UuidValue? userId,
    String? username,
    String? displayName,
    Object? bio = _Undefined,
    Object? avatarUrl = _Undefined,
    bool? isCreator,
    _il3i3d2n.VerificationStatus? verification,
    _ijvat8p8.AccountStatus? status,
    DateTime? createdAt,
  }) {
    return ProfileView(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio is String? ? bio : this.bio,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      isCreator: isCreator ?? this.isCreator,
      verification: verification ?? this.verification,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
