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
    this.hostUsername = '',
    this.viewers = 0,
    this.isPremium = false,
    this.endedByModeration = false,
    this.description = '',
    this.scheduledAt,
    this.durationMinutes,
    this.cohostIds = const [],
    this.allowQuestions = true,
    this.recordReplay = true,
    this.startedAt,
    this.endedAt,
    this.hostAvatarUrl,
  });
  final String id;
  final String title;
  final String hostId;
  final String hostName;

  /// El handle del host, sin `@`. Vacío cuando la fuente no lo sabe (el
  /// mock): la View cae al nombre en vez de inventar un usuario.
  final String hostUsername;
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

  /// Cuándo salió al aire. De acá sale el reloj del Studio.
  final DateTime? startedAt;

  /// Cuándo terminó. Con [startedAt], la duración que ve quien se quedó
  /// mirando hasta el final.
  final DateTime? endedAt;

  /// La foto del host. Null: se dibuja la inicial.
  final String? hostAvatarUrl;

  LiveSession copyWith({
    LiveStatus? status,
    int? viewers,
    bool? endedByModeration,
  }) => LiveSession(
    id: id,
    title: title,
    hostId: hostId,
    hostName: hostName,
    hostUsername: hostUsername,
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
    startedAt: startedAt,
    endedAt: endedAt,
    hostAvatarUrl: hostAvatarUrl,
  );
  @override
  List<Object?> get props => [
    id,
    title,
    hostId,
    hostName,
    hostUsername,
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
    startedAt,
    endedAt,
    hostAvatarUrl,
  ];
}
