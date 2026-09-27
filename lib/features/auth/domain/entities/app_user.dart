import 'package:equatable/equatable.dart';

enum UserRole { visitor, user, creator, moderator }

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
  });
  final String id;
  final String username;
  final String name;
  final UserRole role;
  @override
  List<Object?> get props => [id, username, name, role];
}
