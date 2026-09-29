import 'package:equatable/equatable.dart';

enum ModerationType {
  hideComment('Comentario oculto'),
  muteUser('Usuario silenciado'),
  banUser('Usuario expulsado'),
  report('Reporte recibido'),
  dismissReport('Reporte descartado');

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

/// Motivos tipificados y no texto libre. La auditoría tiene que poder
/// agruparse por motivo, y "acoso", "Acoso" y "acoso!!" son tres motivos para
/// una consulta.
enum ModerationReason {
  spam('Spam'),
  harassment('Acoso'),
  hateSpeech('Discurso de odio'),
  sexualContent('Contenido sexual'),
  violence('Violencia'),
  impersonation('Suplantación'),
  other('Otro');

  const ModerationReason(this.label);

  final String label;

  /// La severidad la decide quien recibe el reporte, no quien lo manda: un
  /// cliente que elige su propia severidad pone todo en "alta".
  ReportSeverity get severity => switch (this) {
    harassment ||
    hateSpeech ||
    violence ||
    sexualContent => ReportSeverity.high,
    impersonation || spam => ReportSeverity.medium,
    other => ReportSeverity.low,
  };
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
  final ModerationReason reason;

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
    this.authorId = '',
    this.commentId,
    this.liveId,
  });

  final String id;
  final String content;

  /// El handle, con `@`. [authorId] es la clave: el handle se puede cambiar.
  final String author;
  final String authorId;
  final ModerationReason reason;
  final ReportSeverity severity;
  final DateTime createdAt;

  /// El comentario reportado, si el reporte es sobre uno.
  final String? commentId;
  final String? liveId;

  @override
  List<Object?> get props => [
    id,
    content,
    author,
    authorId,
    reason,
    severity,
    createdAt,
    commentId,
    liveId,
  ];
}

/// Lo que el moderador decidió.
///
/// Un valor y no un callback por acción: quien la tomó —la hoja del directo o
/// la consola— no sabe qué hacer con ella, y devolverla deja ese reparto en
/// manos de quien la abrió. Vive en el dominio porque es también lo que recibe
/// `ModerationRepository.resolve`.
class ModerationDecision extends Equatable {
  const ModerationDecision({required this.type, this.muteFor});

  final ModerationType type;

  /// Sólo para [ModerationType.muteUser].
  final MuteDuration? muteFor;

  @override
  List<Object?> get props => [type, muteFor];
}
