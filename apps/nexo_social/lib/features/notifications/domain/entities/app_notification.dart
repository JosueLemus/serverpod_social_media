import 'package:equatable/equatable.dart';

enum NotificationType {
  like,
  follow,
  comment,
  liveReminder,
  membership,
  moderation,
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.detail,
    this.read = false,
  });
  final String id;
  final NotificationType type;
  final String title;
  final String detail;
  final bool read;
  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    type: type,
    title: title,
    detail: detail,
    read: read ?? this.read,
  );
  @override
  List<Object?> get props => [id, type, title, detail, read];
}
