import 'package:equatable/equatable.dart';

enum ModerationType {
  hideComment('Comentario oculto'),
  muteUser('Usuario silenciado'),
  banUser('Usuario expulsado'),
  report('Reporte recibido');

  const ModerationType(this.label);

  final String label;
}

/// Cuánto dura un silenciamiento.
///
/// Un conjunto cerrado y no una duración libre: el moderador decide en
/// segundos, en medio de un directo, y un campo de duración ahí es una
/// decisión que nadie toma bien. Las tres opciones son las del diseño.
enum MuteDuration {
  fifteenMinutes('15 min', Duration(minutes: 15)),
  oneHour('1 hora', Duration(hours: 1)),
  oneDay('24 horas', Duration(hours: 24));

  const MuteDuration(this.label, this.duration);

  final String label;
  final Duration duration;
}

/// One entry of the audit trail. Append-only by design: an action that can be
/// edited or deleted is not evidence, and the demo's whole point is that
/// moderation is recorded rather than merely applied.
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

  /// Who performed it. Required, never defaulted: an audit row without an
  /// actor cannot answer the only question it exists to answer.
  final String actor;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, type, target, reason, actor, createdAt];
}

/// Severity drives the order of the queue: what can harm someone is reviewed
/// before what is merely noise.
enum ReportSeverity {
  low('Baja'),
  medium('Media'),
  high('Alta');

  const ReportSeverity(this.label);

  final String label;
}

class ModerationReport extends Equatable {
  const ModerationReport({
    required this.id,
    required this.content,
    required this.author,
    required this.reason,
    required this.severity,
    required this.createdAt,
  });

  final String id;
  final String content;
  final String author;
  final String reason;
  final ReportSeverity severity;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, content, author, reason, severity, createdAt];
}
