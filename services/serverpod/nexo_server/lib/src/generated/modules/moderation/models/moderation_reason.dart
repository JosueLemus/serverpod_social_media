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

/// Motivos tipificados, los mismos que la app. Texto libre no se puede
/// agrupar en la auditoría.
enum ModerationReason implements _is.SerializableModel {
  spam,
  harassment,
  hateSpeech,
  sexualContent,
  violence,
  impersonation,
  other;

  static ModerationReason fromJson(String name) {
    switch (name) {
      case 'spam':
        return ModerationReason.spam;
      case 'harassment':
        return ModerationReason.harassment;
      case 'hateSpeech':
        return ModerationReason.hateSpeech;
      case 'sexualContent':
        return ModerationReason.sexualContent;
      case 'violence':
        return ModerationReason.violence;
      case 'impersonation':
        return ModerationReason.impersonation;
      case 'other':
        return ModerationReason.other;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "ModerationReason"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
