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

/// Una sanción dentro de una sala (SDD 0011, S10). Tres escalones con
/// alcances distintos: la conversación, la sala y la relación con el host.
enum LiveSanctionKind implements _is.SerializableModel {
  /// No puede escribir en el chat hasta `until` (o hasta que termine el vivo).
  chatMute,

  /// Fuera de este vivo: no vuelve a entrar.
  kick,

  /// Fuera de todos los vivos de este host, hasta que el host lo levante.
  ban;

  static LiveSanctionKind fromJson(String name) {
    switch (name) {
      case 'chatMute':
        return LiveSanctionKind.chatMute;
      case 'kick':
        return LiveSanctionKind.kick;
      case 'ban':
        return LiveSanctionKind.ban;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "LiveSanctionKind"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
