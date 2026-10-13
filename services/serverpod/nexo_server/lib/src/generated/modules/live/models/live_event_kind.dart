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

/// Qué trae un [LiveEvent].
enum LiveEventKind implements _is.SerializableModel {
  /// Lo primero que recibe quien se conecta: show, rol, espectadores e historia.
  snapshot,

  /// El show cambió de estado.
  status,

  /// Cambió la cantidad de espectadores.
  viewers,

  /// Mensaje nuevo en el chat.
  chat,

  /// Un mensaje se ocultó.
  chatHidden,

  /// El escenario cambió: alguien subió, bajó, pidió la palabra o silenció.
  stage,

  /// Cambió el rol de una persona (`targetId`). Cada app mira si es ella.
  roleChanged,

  /// Una sanción a `targetId`: `sanctionKind` y, en un silencio, `until`.
  sanction,

  /// Un mensaje se borró (`hiddenMessageId`).
  chatDeleted,

  /// Un mensaje oculto volvió (`message`).
  chatRestored,

  /// Cambió el mensaje fijado (`pinned`; null lo despega).
  pinned,

  /// Cambió la pregunta destacada (`highlighted`; null la quita).
  highlighted;

  static LiveEventKind fromJson(String name) {
    switch (name) {
      case 'snapshot':
        return LiveEventKind.snapshot;
      case 'status':
        return LiveEventKind.status;
      case 'viewers':
        return LiveEventKind.viewers;
      case 'chat':
        return LiveEventKind.chat;
      case 'chatHidden':
        return LiveEventKind.chatHidden;
      case 'stage':
        return LiveEventKind.stage;
      case 'roleChanged':
        return LiveEventKind.roleChanged;
      case 'sanction':
        return LiveEventKind.sanction;
      case 'chatDeleted':
        return LiveEventKind.chatDeleted;
      case 'chatRestored':
        return LiveEventKind.chatRestored;
      case 'pinned':
        return LiveEventKind.pinned;
      case 'highlighted':
        return LiveEventKind.highlighted;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "LiveEventKind"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
