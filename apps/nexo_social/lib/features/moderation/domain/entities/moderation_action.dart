import 'package:equatable/equatable.dart';

enum ModerationType { hideComment, muteUser, banUser, report }

class ModerationAction extends Equatable {
  const ModerationAction({
    required this.id,
    required this.type,
    required this.target,
    required this.reason,
    required this.actor,
    required this.createdAt,
  });
  final String id;
  final ModerationType type;
  final String target;
  final String reason;
  final String actor;
  final DateTime createdAt;
  @override
  List<Object?> get props => [id, type, target, reason, actor, createdAt];
}
