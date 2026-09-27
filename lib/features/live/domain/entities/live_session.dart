import 'package:equatable/equatable.dart';

enum LiveStatus {
  draft,
  scheduled,
  live,
  ending,
  recorded,
  published,
  cancelled,
  failed,
  removed,
}

enum LiveRole { audience, host, cohost, moderator }

class LiveSession extends Equatable {
  const LiveSession({
    required this.id,
    required this.title,
    required this.hostName,
    required this.status,
    this.viewers = 0,
    this.isPremium = false,
  });
  final String id;
  final String title;
  final String hostName;
  final LiveStatus status;
  final int viewers;
  final bool isPremium;
  LiveSession copyWith({LiveStatus? status, int? viewers}) => LiveSession(
    id: id,
    title: title,
    hostName: hostName,
    status: status ?? this.status,
    viewers: viewers ?? this.viewers,
    isPremium: isPremium,
  );
  @override
  List<Object?> get props => [id, title, hostName, status, viewers, isPremium];
}
