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
import '../../../modules/live/models/live_show_access.dart' as _ihhtmjkk;

/// Lo que el cliente envía para programar un show. Los invitados van por
/// nombre de usuario, como los escribe el creador.
abstract class LiveShowDraft
    implements _is.SerializableModel, _is.ProtocolSerialization {
  LiveShowDraft._({
    required this.title,
    required this.description,
    required this.startsAt,
    required this.durationMinutes,
    _ihhtmjkk.LiveShowAccess? access,
    bool? allowQuestions,
    bool? recordReplay,
    required this.guestUsernames,
  }) : access = access ?? _ihhtmjkk.LiveShowAccess.public,
       allowQuestions = allowQuestions ?? true,
       recordReplay = recordReplay ?? true;

  factory LiveShowDraft({
    required String title,
    required String description,
    required DateTime startsAt,
    required int durationMinutes,
    _ihhtmjkk.LiveShowAccess? access,
    bool? allowQuestions,
    bool? recordReplay,
    required List<String> guestUsernames,
  }) = _LiveShowDraftImpl;

  factory LiveShowDraft.fromJson(Map<String, dynamic> jsonSerialization) {
    return LiveShowDraft(
      title: jsonSerialization['title'] as String,
      description: jsonSerialization['description'] as String,
      startsAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['startsAt'],
      ),
      durationMinutes: jsonSerialization['durationMinutes'] as int,
      access: jsonSerialization['access'] == null
          ? null
          : _ihhtmjkk.LiveShowAccess.fromJson(
              (jsonSerialization['access'] as String),
            ),
      allowQuestions: jsonSerialization['allowQuestions'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['allowQuestions']),
      recordReplay: jsonSerialization['recordReplay'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['recordReplay']),
      guestUsernames: _i8p6m2v0.Protocol().deserialize<List<String>>(
        jsonSerialization['guestUsernames'],
      ),
    );
  }

  String title;

  String description;

  DateTime startsAt;

  int durationMinutes;

  _ihhtmjkk.LiveShowAccess access;

  bool allowQuestions;

  bool recordReplay;

  List<String> guestUsernames;

  /// Returns a shallow copy of this [LiveShowDraft]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  LiveShowDraft copyWith({
    String? title,
    String? description,
    DateTime? startsAt,
    int? durationMinutes,
    _ihhtmjkk.LiveShowAccess? access,
    bool? allowQuestions,
    bool? recordReplay,
    List<String>? guestUsernames,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LiveShowDraft',
      'title': title,
      'description': description,
      'startsAt': startsAt.toJson(),
      'durationMinutes': durationMinutes,
      'access': access.toJson(),
      'allowQuestions': allowQuestions,
      'recordReplay': recordReplay,
      'guestUsernames': guestUsernames.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LiveShowDraft',
      'title': title,
      'description': description,
      'startsAt': startsAt.toJson(),
      'durationMinutes': durationMinutes,
      'access': access.toJson(),
      'allowQuestions': allowQuestions,
      'recordReplay': recordReplay,
      'guestUsernames': guestUsernames.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _LiveShowDraftImpl extends LiveShowDraft {
  _LiveShowDraftImpl({
    required String title,
    required String description,
    required DateTime startsAt,
    required int durationMinutes,
    _ihhtmjkk.LiveShowAccess? access,
    bool? allowQuestions,
    bool? recordReplay,
    required List<String> guestUsernames,
  }) : super._(
         title: title,
         description: description,
         startsAt: startsAt,
         durationMinutes: durationMinutes,
         access: access,
         allowQuestions: allowQuestions,
         recordReplay: recordReplay,
         guestUsernames: guestUsernames,
       );

  /// Returns a shallow copy of this [LiveShowDraft]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  LiveShowDraft copyWith({
    String? title,
    String? description,
    DateTime? startsAt,
    int? durationMinutes,
    _ihhtmjkk.LiveShowAccess? access,
    bool? allowQuestions,
    bool? recordReplay,
    List<String>? guestUsernames,
  }) {
    return LiveShowDraft(
      title: title ?? this.title,
      description: description ?? this.description,
      startsAt: startsAt ?? this.startsAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      access: access ?? this.access,
      allowQuestions: allowQuestions ?? this.allowQuestions,
      recordReplay: recordReplay ?? this.recordReplay,
      guestUsernames:
          guestUsernames ?? this.guestUsernames.map((e0) => e0).toList(),
    );
  }
}
