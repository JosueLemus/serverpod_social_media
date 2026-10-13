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
import '../../../modules/live/models/live_hand_view.dart' as _i3282dw3;
import '../../../modules/live/models/live_speaker_view.dart' as _i8ngxzl3;

/// El escenario de una sala: el host primero y después los demás por orden de
/// llegada, y la cola de pedidos de palabra, del más viejo al más nuevo.
abstract class LiveStageView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  LiveStageView._({
    required this.speakers,
    required this.hands,
  });

  factory LiveStageView({
    required List<_i8ngxzl3.LiveSpeakerView> speakers,
    required List<_i3282dw3.LiveHandView> hands,
  }) = _LiveStageViewImpl;

  factory LiveStageView.fromJson(Map<String, dynamic> jsonSerialization) {
    return LiveStageView(
      speakers: _i8p6m2v0.Protocol()
          .deserialize<List<_i8ngxzl3.LiveSpeakerView>>(
            jsonSerialization['speakers'],
          ),
      hands: _i8p6m2v0.Protocol().deserialize<List<_i3282dw3.LiveHandView>>(
        jsonSerialization['hands'],
      ),
    );
  }

  List<_i8ngxzl3.LiveSpeakerView> speakers;

  List<_i3282dw3.LiveHandView> hands;

  /// Returns a shallow copy of this [LiveStageView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  LiveStageView copyWith({
    List<_i8ngxzl3.LiveSpeakerView>? speakers,
    List<_i3282dw3.LiveHandView>? hands,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LiveStageView',
      'speakers': speakers.toJson(valueToJson: (v) => v.toJson()),
      'hands': hands.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LiveStageView',
      'speakers': speakers.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'hands': hands.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _LiveStageViewImpl extends LiveStageView {
  _LiveStageViewImpl({
    required List<_i8ngxzl3.LiveSpeakerView> speakers,
    required List<_i3282dw3.LiveHandView> hands,
  }) : super._(
         speakers: speakers,
         hands: hands,
       );

  /// Returns a shallow copy of this [LiveStageView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  LiveStageView copyWith({
    List<_i8ngxzl3.LiveSpeakerView>? speakers,
    List<_i3282dw3.LiveHandView>? hands,
  }) {
    return LiveStageView(
      speakers: speakers ?? this.speakers.map((e0) => e0.copyWith()).toList(),
      hands: hands ?? this.hands.map((e0) => e0.copyWith()).toList(),
    );
  }
}
