import 'package:equatable/equatable.dart';

/// Lo que se cambia del perfil propio. Null deja el campo como está.
class ProfileChanges extends Equatable {
  const ProfileChanges({this.username, this.displayName, this.bio});

  final String? username;
  final String? displayName;

  /// Vacío borra la bio.
  final String? bio;

  bool get isEmpty => username == null && displayName == null && bio == null;

  @override
  List<Object?> get props => [username, displayName, bio];
}

/// Por qué un campo del formulario no se puede enviar.
enum ProfileFieldIssue {
  usernameLength,
  usernameCharacters,
  usernameReserved,
  nameMissing,
  nameTooLong,
  bioTooLong,
}

/// Las reglas del servidor (`UsernameRules`), repetidas acá sólo para avisar
/// antes de enviar. Quien decide es el servidor: si cambian allá y no acá,
/// el formulario deja pasar algo y el servidor lo rechaza con su motivo.
abstract final class ProfileRules {
  static const usernameMin = 3;
  static const usernameMax = 24;
  static const nameMax = 50;
  static const bioMax = 160;

  static final _username = RegExp(r'^[a-z0-9_]+$');

  static const _reserved = {
    'admin',
    'administrador',
    'moderador',
    'moderator',
    'nexo',
    'operador',
    'soporte',
    'support',
    'sistema',
    'system',
  };

  static String normalizeUsername(String value) => value.trim().toLowerCase();

  static ProfileFieldIssue? usernameIssue(String value) {
    final username = normalizeUsername(value);
    if (username.length < usernameMin || username.length > usernameMax) {
      return ProfileFieldIssue.usernameLength;
    }
    if (!_username.hasMatch(username)) {
      return ProfileFieldIssue.usernameCharacters;
    }
    if (_reserved.contains(username)) return ProfileFieldIssue.usernameReserved;
    return null;
  }

  static ProfileFieldIssue? nameIssue(String value) {
    final name = value.trim();
    if (name.isEmpty) return ProfileFieldIssue.nameMissing;
    if (name.length > nameMax) return ProfileFieldIssue.nameTooLong;
    return null;
  }

  static ProfileFieldIssue? bioIssue(String value) =>
      value.trim().length > bioMax ? ProfileFieldIssue.bioTooLong : null;
}
