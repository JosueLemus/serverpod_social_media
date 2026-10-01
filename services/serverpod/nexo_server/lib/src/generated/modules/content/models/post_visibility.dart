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

/// Quién puede ver un post. Mientras no existan los módulos `social` y
/// `billing`, `followers` y `members` solo los ve su autor: sin un grafo de
/// seguidores ni suscripciones, negar es lo único seguro.
enum PostVisibility implements _is.SerializableModel {
  public,
  followers,
  members;

  static PostVisibility fromJson(String name) {
    switch (name) {
      case 'public':
        return PostVisibility.public;
      case 'followers':
        return PostVisibility.followers;
      case 'members':
        return PostVisibility.members;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "PostVisibility"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
