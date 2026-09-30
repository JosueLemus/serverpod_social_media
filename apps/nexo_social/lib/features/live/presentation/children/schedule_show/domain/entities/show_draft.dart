import 'package:equatable/equatable.dart';

enum ShowAccess { public, members }

class ShowGuest extends Equatable {
  const ShowGuest({
    required this.id,
    required this.username,
    required this.name,
  });

  factory ShowGuest.fromJson(Map<String, dynamic> json) => ShowGuest(
    id: json['id'] as String,
    username: json['username'] as String,
    name: json['name'] as String,
  );

  final String id;
  final String username;
  final String name;

  Map<String, Object?> toJson() => {
    'id': id,
    'username': username,
    'name': name,
  };

  @override
  List<Object?> get props => [id, username, name];
}

enum ShowDraftIssue { titleMissing, titleTooLong, startInPast, tooManyGuests }

class ShowDraft extends Equatable {
  const ShowDraft({
    required this.startsAt,
    this.title = '',
    this.description = '',
    this.durationMinutes = recommendedMinutes,
    this.guests = const [],
    this.access = ShowAccess.public,
    this.allowQuestions = true,
    this.recordReplay = true,
  });

  factory ShowDraft.fromJson(Map<String, dynamic> json) => ShowDraft(
    title: json['title'] as String,
    description: json['description'] as String,
    startsAt: DateTime.parse(json['startsAt'] as String),
    durationMinutes: json['durationMinutes'] as int,
    guests: [
      for (final guest in json['guests'] as List<dynamic>)
        ShowGuest.fromJson(guest as Map<String, dynamic>),
    ],
    access: ShowAccess.values.byName(json['access'] as String),
    allowQuestions: json['allowQuestions'] as bool,
    recordReplay: json['recordReplay'] as bool,
  );

  factory ShowDraft.startingFrom(DateTime now) => ShowDraft(
    startsAt: DateTime(now.year, now.month, now.day + 1, 19),
  );

  static const maxTitleLength = 100;
  // TODO(backend): leer el tope de co-hosts de la config del servidor; hoy
  // duplica MockPlatform.maxCohosts.
  static const maxGuests = 3;
  static const recommendedMinutes = 60;

  final String title;

  final String description;
  final DateTime startsAt;
  final int durationMinutes;
  final List<ShowGuest> guests;
  final ShowAccess access;
  final bool allowQuestions;
  final bool recordReplay;

  int get titleLength => title.runes.length;

  bool get canAddGuest => guests.length < maxGuests;

  Set<ShowDraftIssue> issuesAt(DateTime now) => {
    if (title.trim().isEmpty) ShowDraftIssue.titleMissing,
    if (titleLength > maxTitleLength) ShowDraftIssue.titleTooLong,
    if (!startsAt.isAfter(now)) ShowDraftIssue.startInPast,
    if (guests.length > maxGuests) ShowDraftIssue.tooManyGuests,
  };

  ShowDraft copyWith({
    String? title,
    String? description,
    DateTime? startsAt,
    int? durationMinutes,
    List<ShowGuest>? guests,
    ShowAccess? access,
    bool? allowQuestions,
    bool? recordReplay,
  }) => ShowDraft(
    title: title ?? this.title,
    description: description ?? this.description,
    startsAt: startsAt ?? this.startsAt,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    guests: guests ?? this.guests,
    access: access ?? this.access,
    allowQuestions: allowQuestions ?? this.allowQuestions,
    recordReplay: recordReplay ?? this.recordReplay,
  );

  Map<String, Object?> toJson() => {
    'title': title,
    'description': description,
    'startsAt': startsAt.toIso8601String(),
    'durationMinutes': durationMinutes,
    'guests': [for (final guest in guests) guest.toJson()],
    'access': access.name,
    'allowQuestions': allowQuestions,
    'recordReplay': recordReplay,
  };

  @override
  List<Object?> get props => [
    title,
    description,
    startsAt,
    durationMinutes,
    guests,
    access,
    allowQuestions,
    recordReplay,
  ];
}
