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
import '../../../modules/live/models/live_show_access.dart' as _ihhtmjkk;
import '../../../modules/live/models/live_show_status.dart' as _iba8cpgl;

/// Un show tal como lo ve cualquiera. No lleva nada propio de quien pide (el
/// rol va aparte): este mismo objeto se publica a todos los espectadores.
abstract class LiveShowView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  LiveShowView._({
    required this.id,
    required this.hostId,
    this.hostUsername,
    this.hostName,
    this.hostAvatarUrl,
    required this.title,
    required this.description,
    required this.startsAt,
    required this.durationMinutes,
    required this.access,
    required this.allowQuestions,
    required this.recordReplay,
    required this.status,
    this.startedAt,
    this.endedAt,
    required this.endedByModeration,
    required this.viewerCount,
    required this.guestIds,
  });

  factory LiveShowView({
    required int id,
    required _isc.UuidValue hostId,
    String? hostUsername,
    String? hostName,
    String? hostAvatarUrl,
    required String title,
    required String description,
    required DateTime startsAt,
    required int durationMinutes,
    required _ihhtmjkk.LiveShowAccess access,
    required bool allowQuestions,
    required bool recordReplay,
    required _iba8cpgl.LiveShowStatus status,
    DateTime? startedAt,
    DateTime? endedAt,
    required bool endedByModeration,
    required int viewerCount,
    required List<_isc.UuidValue> guestIds,
  }) = _LiveShowViewImpl;

  factory LiveShowView.fromJson(Map<String, dynamic> jsonSerialization) {
    return LiveShowView(
      id: jsonSerialization['id'] as int,
      hostId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['hostId']),
      hostUsername: jsonSerialization['hostUsername'] as String?,
      hostName: jsonSerialization['hostName'] as String?,
      hostAvatarUrl: jsonSerialization['hostAvatarUrl'] as String?,
      title: jsonSerialization['title'] as String,
      description: jsonSerialization['description'] as String,
      startsAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['startsAt'],
      ),
      durationMinutes: jsonSerialization['durationMinutes'] as int,
      access: _ihhtmjkk.LiveShowAccess.fromJson(
        (jsonSerialization['access'] as String),
      ),
      allowQuestions: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['allowQuestions'],
      ),
      recordReplay: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['recordReplay'],
      ),
      status: _iba8cpgl.LiveShowStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      startedAt: jsonSerialization['startedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['startedAt']),
      endedAt: jsonSerialization['endedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['endedAt']),
      endedByModeration: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['endedByModeration'],
      ),
      viewerCount: jsonSerialization['viewerCount'] as int,
      guestIds: _il0t1g31.Protocol().deserialize<List<_isc.UuidValue>>(
        jsonSerialization['guestIds'],
      ),
    );
  }

  int id;

  _isc.UuidValue hostId;

  String? hostUsername;

  String? hostName;

  String? hostAvatarUrl;

  String title;

  String description;

  DateTime startsAt;

  int durationMinutes;

  _ihhtmjkk.LiveShowAccess access;

  bool allowQuestions;

  bool recordReplay;

  _iba8cpgl.LiveShowStatus status;

  DateTime? startedAt;

  DateTime? endedAt;

  bool endedByModeration;

  /// Al aire: conexiones mirando ahora, sin contar al host. Terminado: el
  /// pico. Programado: 0.
  int viewerCount;

  List<_isc.UuidValue> guestIds;

  /// Returns a shallow copy of this [LiveShowView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LiveShowView copyWith({
    int? id,
    _isc.UuidValue? hostId,
    String? hostUsername,
    String? hostName,
    String? hostAvatarUrl,
    String? title,
    String? description,
    DateTime? startsAt,
    int? durationMinutes,
    _ihhtmjkk.LiveShowAccess? access,
    bool? allowQuestions,
    bool? recordReplay,
    _iba8cpgl.LiveShowStatus? status,
    DateTime? startedAt,
    DateTime? endedAt,
    bool? endedByModeration,
    int? viewerCount,
    List<_isc.UuidValue>? guestIds,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LiveShowView',
      'id': id,
      'hostId': hostId.toJson(),
      if (hostUsername != null) 'hostUsername': hostUsername,
      if (hostName != null) 'hostName': hostName,
      if (hostAvatarUrl != null) 'hostAvatarUrl': hostAvatarUrl,
      'title': title,
      'description': description,
      'startsAt': startsAt.toJson(),
      'durationMinutes': durationMinutes,
      'access': access.toJson(),
      'allowQuestions': allowQuestions,
      'recordReplay': recordReplay,
      'status': status.toJson(),
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (endedAt != null) 'endedAt': endedAt?.toJson(),
      'endedByModeration': endedByModeration,
      'viewerCount': viewerCount,
      'guestIds': guestIds.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LiveShowView',
      'id': id,
      'hostId': hostId.toJson(),
      if (hostUsername != null) 'hostUsername': hostUsername,
      if (hostName != null) 'hostName': hostName,
      if (hostAvatarUrl != null) 'hostAvatarUrl': hostAvatarUrl,
      'title': title,
      'description': description,
      'startsAt': startsAt.toJson(),
      'durationMinutes': durationMinutes,
      'access': access.toJson(),
      'allowQuestions': allowQuestions,
      'recordReplay': recordReplay,
      'status': status.toJson(),
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (endedAt != null) 'endedAt': endedAt?.toJson(),
      'endedByModeration': endedByModeration,
      'viewerCount': viewerCount,
      'guestIds': guestIds.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LiveShowViewImpl extends LiveShowView {
  _LiveShowViewImpl({
    required int id,
    required _isc.UuidValue hostId,
    String? hostUsername,
    String? hostName,
    String? hostAvatarUrl,
    required String title,
    required String description,
    required DateTime startsAt,
    required int durationMinutes,
    required _ihhtmjkk.LiveShowAccess access,
    required bool allowQuestions,
    required bool recordReplay,
    required _iba8cpgl.LiveShowStatus status,
    DateTime? startedAt,
    DateTime? endedAt,
    required bool endedByModeration,
    required int viewerCount,
    required List<_isc.UuidValue> guestIds,
  }) : super._(
         id: id,
         hostId: hostId,
         hostUsername: hostUsername,
         hostName: hostName,
         hostAvatarUrl: hostAvatarUrl,
         title: title,
         description: description,
         startsAt: startsAt,
         durationMinutes: durationMinutes,
         access: access,
         allowQuestions: allowQuestions,
         recordReplay: recordReplay,
         status: status,
         startedAt: startedAt,
         endedAt: endedAt,
         endedByModeration: endedByModeration,
         viewerCount: viewerCount,
         guestIds: guestIds,
       );

  /// Returns a shallow copy of this [LiveShowView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LiveShowView copyWith({
    int? id,
    _isc.UuidValue? hostId,
    Object? hostUsername = _Undefined,
    Object? hostName = _Undefined,
    Object? hostAvatarUrl = _Undefined,
    String? title,
    String? description,
    DateTime? startsAt,
    int? durationMinutes,
    _ihhtmjkk.LiveShowAccess? access,
    bool? allowQuestions,
    bool? recordReplay,
    _iba8cpgl.LiveShowStatus? status,
    Object? startedAt = _Undefined,
    Object? endedAt = _Undefined,
    bool? endedByModeration,
    int? viewerCount,
    List<_isc.UuidValue>? guestIds,
  }) {
    return LiveShowView(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      hostUsername: hostUsername is String? ? hostUsername : this.hostUsername,
      hostName: hostName is String? ? hostName : this.hostName,
      hostAvatarUrl: hostAvatarUrl is String?
          ? hostAvatarUrl
          : this.hostAvatarUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      startsAt: startsAt ?? this.startsAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      access: access ?? this.access,
      allowQuestions: allowQuestions ?? this.allowQuestions,
      recordReplay: recordReplay ?? this.recordReplay,
      status: status ?? this.status,
      startedAt: startedAt is DateTime? ? startedAt : this.startedAt,
      endedAt: endedAt is DateTime? ? endedAt : this.endedAt,
      endedByModeration: endedByModeration ?? this.endedByModeration,
      viewerCount: viewerCount ?? this.viewerCount,
      guestIds: guestIds ?? this.guestIds.map((e0) => e0).toList(),
    );
  }
}
