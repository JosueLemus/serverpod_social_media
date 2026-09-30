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
    this.hostId = '',
    this.viewers = 0,
    this.isPremium = false,
    this.endedByModeration = false,
    this.description = '',
    this.scheduledAt,
    this.durationMinutes,
    this.cohostIds = const [],
    this.allowQuestions = true,
    this.recordReplay = true,
  });
  final String id;
  final String title;
  final String hostId;
  final String hostName;
  final LiveStatus status;
  final int viewers;
  final bool isPremium;

  /// Lo terminó el equipo de Nexo y no el host. La sala lo dice: un vivo que
  /// se corta sin explicación se lee como una falla técnica.
  final bool endedByModeration;

  final String description;

  final DateTime? scheduledAt;

  final int? durationMinutes;

  final List<String> cohostIds;

  final bool allowQuestions;
  final bool recordReplay;

  LiveSession copyWith({
    LiveStatus? status,
    int? viewers,
    bool? endedByModeration,
  }) => LiveSession(
    id: id,
    title: title,
    hostId: hostId,
    hostName: hostName,
    status: status ?? this.status,
    viewers: viewers ?? this.viewers,
    isPremium: isPremium,
    endedByModeration: endedByModeration ?? this.endedByModeration,
    description: description,
    scheduledAt: scheduledAt,
    durationMinutes: durationMinutes,
    cohostIds: cohostIds,
    allowQuestions: allowQuestions,
    recordReplay: recordReplay,
  );
  @override
  List<Object?> get props => [
    id,
    title,
    hostId,
    hostName,
    status,
    viewers,
    isPremium,
    endedByModeration,
    description,
    scheduledAt,
    durationMinutes,
    cohostIds,
    allowQuestions,
    recordReplay,
  ];
}
