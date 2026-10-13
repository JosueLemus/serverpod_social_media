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
import '../../../modules/live/models/live_chat_message_view.dart' as _izb1i8g5;
import '../../../modules/live/models/live_event_kind.dart' as _iu58xzg9;
import '../../../modules/live/models/live_sanction_kind.dart' as _iocsdvds;
import '../../../modules/live/models/live_show_role.dart' as _isrlpwvf;
import '../../../modules/live/models/live_show_view.dart' as _idtyojf8;
import '../../../modules/live/models/live_stage_view.dart' as _i0fmqcgw;

/// Lo que viaja por `live.watch`. Plano, con [kind] y campos opcionales: el
/// canal se tipa con una sola clase, y un cliente viejo ignora un [kind] que
/// no conoce. [role] viene en `snapshot`, que arma la sesión de cada
/// espectador, y en `roleChanged` junto con [targetId]; los demás eventos se
/// publican iguales para todos.
abstract class LiveEvent
    implements _is.SerializableModel, _is.ProtocolSerialization {
  LiveEvent._({
    required this.kind,
    this.liveShow,
    this.role,
    this.viewerCount,
    this.message,
    this.history,
    this.hiddenMessageId,
    this.stage,
    this.targetId,
    this.sanctionKind,
    this.until,
    this.pinned,
    this.highlighted,
  });

  factory LiveEvent({
    required _iu58xzg9.LiveEventKind kind,
    _idtyojf8.LiveShowView? liveShow,
    _isrlpwvf.LiveShowRole? role,
    int? viewerCount,
    _izb1i8g5.LiveChatMessageView? message,
    List<_izb1i8g5.LiveChatMessageView>? history,
    int? hiddenMessageId,
    _i0fmqcgw.LiveStageView? stage,
    _is.UuidValue? targetId,
    _iocsdvds.LiveSanctionKind? sanctionKind,
    DateTime? until,
    _izb1i8g5.LiveChatMessageView? pinned,
    _izb1i8g5.LiveChatMessageView? highlighted,
  }) = _LiveEventImpl;

  factory LiveEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return LiveEvent(
      kind: _iu58xzg9.LiveEventKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      liveShow: jsonSerialization['liveShow'] == null
          ? null
          : _i8p6m2v0.Protocol().deserialize<_idtyojf8.LiveShowView>(
              jsonSerialization['liveShow'],
            ),
      role: jsonSerialization['role'] == null
          ? null
          : _isrlpwvf.LiveShowRole.fromJson(
              (jsonSerialization['role'] as String),
            ),
      viewerCount: jsonSerialization['viewerCount'] as int?,
      message: jsonSerialization['message'] == null
          ? null
          : _i8p6m2v0.Protocol().deserialize<_izb1i8g5.LiveChatMessageView>(
              jsonSerialization['message'],
            ),
      history: jsonSerialization['history'] == null
          ? null
          : _i8p6m2v0.Protocol()
                .deserialize<List<_izb1i8g5.LiveChatMessageView>>(
                  jsonSerialization['history'],
                ),
      hiddenMessageId: jsonSerialization['hiddenMessageId'] as int?,
      stage: jsonSerialization['stage'] == null
          ? null
          : _i8p6m2v0.Protocol().deserialize<_i0fmqcgw.LiveStageView>(
              jsonSerialization['stage'],
            ),
      targetId: jsonSerialization['targetId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['targetId']),
      sanctionKind: jsonSerialization['sanctionKind'] == null
          ? null
          : _iocsdvds.LiveSanctionKind.fromJson(
              (jsonSerialization['sanctionKind'] as String),
            ),
      until: jsonSerialization['until'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['until']),
      pinned: jsonSerialization['pinned'] == null
          ? null
          : _i8p6m2v0.Protocol().deserialize<_izb1i8g5.LiveChatMessageView>(
              jsonSerialization['pinned'],
            ),
      highlighted: jsonSerialization['highlighted'] == null
          ? null
          : _i8p6m2v0.Protocol().deserialize<_izb1i8g5.LiveChatMessageView>(
              jsonSerialization['highlighted'],
            ),
    );
  }

  _iu58xzg9.LiveEventKind kind;

  _idtyojf8.LiveShowView? liveShow;

  _isrlpwvf.LiveShowRole? role;

  int? viewerCount;

  _izb1i8g5.LiveChatMessageView? message;

  List<_izb1i8g5.LiveChatMessageView>? history;

  int? hiddenMessageId;

  /// En `snapshot` y `stage`.
  _i0fmqcgw.LiveStageView? stage;

  /// En `roleChanged`: de quién es el rol nuevo, que viaja en `role`.
  _is.UuidValue? targetId;

  /// En `sanction`, y en `snapshot` si quien mira está silenciado.
  _iocsdvds.LiveSanctionKind? sanctionKind;

  /// Hasta cuándo dura un silencio. Null con `chatMute`: el resto del vivo.
  DateTime? until;

  /// En `snapshot` y `pinned`.
  _izb1i8g5.LiveChatMessageView? pinned;

  /// En `snapshot` y `highlighted`.
  _izb1i8g5.LiveChatMessageView? highlighted;

  /// Returns a shallow copy of this [LiveEvent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  LiveEvent copyWith({
    _iu58xzg9.LiveEventKind? kind,
    _idtyojf8.LiveShowView? liveShow,
    _isrlpwvf.LiveShowRole? role,
    int? viewerCount,
    _izb1i8g5.LiveChatMessageView? message,
    List<_izb1i8g5.LiveChatMessageView>? history,
    int? hiddenMessageId,
    _i0fmqcgw.LiveStageView? stage,
    _is.UuidValue? targetId,
    _iocsdvds.LiveSanctionKind? sanctionKind,
    DateTime? until,
    _izb1i8g5.LiveChatMessageView? pinned,
    _izb1i8g5.LiveChatMessageView? highlighted,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LiveEvent',
      'kind': kind.toJson(),
      if (liveShow != null) 'liveShow': liveShow?.toJson(),
      if (role != null) 'role': role?.toJson(),
      if (viewerCount != null) 'viewerCount': viewerCount,
      if (message != null) 'message': message?.toJson(),
      if (history != null)
        'history': history?.toJson(valueToJson: (v) => v.toJson()),
      if (hiddenMessageId != null) 'hiddenMessageId': hiddenMessageId,
      if (stage != null) 'stage': stage?.toJson(),
      if (targetId != null) 'targetId': targetId?.toJson(),
      if (sanctionKind != null) 'sanctionKind': sanctionKind?.toJson(),
      if (until != null) 'until': until?.toJson(),
      if (pinned != null) 'pinned': pinned?.toJson(),
      if (highlighted != null) 'highlighted': highlighted?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LiveEvent',
      'kind': kind.toJson(),
      if (liveShow != null) 'liveShow': liveShow?.toJsonForProtocol(),
      if (role != null) 'role': role?.toJson(),
      if (viewerCount != null) 'viewerCount': viewerCount,
      if (message != null) 'message': message?.toJsonForProtocol(),
      if (history != null)
        'history': history?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (hiddenMessageId != null) 'hiddenMessageId': hiddenMessageId,
      if (stage != null) 'stage': stage?.toJsonForProtocol(),
      if (targetId != null) 'targetId': targetId?.toJson(),
      if (sanctionKind != null) 'sanctionKind': sanctionKind?.toJson(),
      if (until != null) 'until': until?.toJson(),
      if (pinned != null) 'pinned': pinned?.toJsonForProtocol(),
      if (highlighted != null) 'highlighted': highlighted?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LiveEventImpl extends LiveEvent {
  _LiveEventImpl({
    required _iu58xzg9.LiveEventKind kind,
    _idtyojf8.LiveShowView? liveShow,
    _isrlpwvf.LiveShowRole? role,
    int? viewerCount,
    _izb1i8g5.LiveChatMessageView? message,
    List<_izb1i8g5.LiveChatMessageView>? history,
    int? hiddenMessageId,
    _i0fmqcgw.LiveStageView? stage,
    _is.UuidValue? targetId,
    _iocsdvds.LiveSanctionKind? sanctionKind,
    DateTime? until,
    _izb1i8g5.LiveChatMessageView? pinned,
    _izb1i8g5.LiveChatMessageView? highlighted,
  }) : super._(
         kind: kind,
         liveShow: liveShow,
         role: role,
         viewerCount: viewerCount,
         message: message,
         history: history,
         hiddenMessageId: hiddenMessageId,
         stage: stage,
         targetId: targetId,
         sanctionKind: sanctionKind,
         until: until,
         pinned: pinned,
         highlighted: highlighted,
       );

  /// Returns a shallow copy of this [LiveEvent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  LiveEvent copyWith({
    _iu58xzg9.LiveEventKind? kind,
    Object? liveShow = _Undefined,
    Object? role = _Undefined,
    Object? viewerCount = _Undefined,
    Object? message = _Undefined,
    Object? history = _Undefined,
    Object? hiddenMessageId = _Undefined,
    Object? stage = _Undefined,
    Object? targetId = _Undefined,
    Object? sanctionKind = _Undefined,
    Object? until = _Undefined,
    Object? pinned = _Undefined,
    Object? highlighted = _Undefined,
  }) {
    return LiveEvent(
      kind: kind ?? this.kind,
      liveShow: liveShow is _idtyojf8.LiveShowView?
          ? liveShow
          : this.liveShow?.copyWith(),
      role: role is _isrlpwvf.LiveShowRole? ? role : this.role,
      viewerCount: viewerCount is int? ? viewerCount : this.viewerCount,
      message: message is _izb1i8g5.LiveChatMessageView?
          ? message
          : this.message?.copyWith(),
      history: history is List<_izb1i8g5.LiveChatMessageView>?
          ? history
          : this.history?.map((e0) => e0.copyWith()).toList(),
      hiddenMessageId: hiddenMessageId is int?
          ? hiddenMessageId
          : this.hiddenMessageId,
      stage: stage is _i0fmqcgw.LiveStageView? ? stage : this.stage?.copyWith(),
      targetId: targetId is _is.UuidValue? ? targetId : this.targetId,
      sanctionKind: sanctionKind is _iocsdvds.LiveSanctionKind?
          ? sanctionKind
          : this.sanctionKind,
      until: until is DateTime? ? until : this.until,
      pinned: pinned is _izb1i8g5.LiveChatMessageView?
          ? pinned
          : this.pinned?.copyWith(),
      highlighted: highlighted is _izb1i8g5.LiveChatMessageView?
          ? highlighted
          : this.highlighted?.copyWith(),
    );
  }
}
