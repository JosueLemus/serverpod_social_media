import 'package:equatable/equatable.dart';

enum NotificationType {
  like('Me gusta'),
  follow('Seguidores'),
  comment('Menciones'),
  liveReminder('Lives'),
  membership('Membresías'),
  moderation('Moderación');

  const NotificationType(this.label);

  /// Lo que muestra el chip de filtro. Sin esto la UI cae en `name`, que
  /// imprime identificadores de Dart como "liveReminder" al usuario.
  final String label;
}

/// En qué franja cae una notificación. Derivado de la fecha, no guardado: un
/// valor persistido envejece y "Hoy" pasa a significar anteayer.
enum ActivityBucket {
  today('Hoy'),
  thisWeek('Esta semana'),
  earlier('Anteriores');

  const ActivityBucket(this.label);

  final String label;

  static ActivityBucket of(DateTime moment, {DateTime? now}) {
    final elapsed = (now ?? DateTime.now()).difference(moment);
    // Una marca en el futuro (desfase de reloj entre teléfono y servidor) cae
    // en "Hoy", nunca en "Anteriores".
    if (elapsed.isNegative || elapsed.inHours < 24) return today;
    if (elapsed.inDays < 7) return thisWeek;
    return earlier;
  }
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.actor,
    required this.title,
    required this.createdAt,
    this.detail,
    this.quote,
    this.read = false,
  });

  final String id;
  final NotificationType type;

  /// Quién lo hizo. Separado del [title] porque la fila dibuja su avatar y
  /// enlaza a su perfil: concatenarlo dentro de la frase lo vuelve intocable.
  final String actor;

  final String title;
  final String? detail;

  /// El texto del comentario, cuando lo hay. Se pinta en su propia tarjeta
  /// citada: dentro del título no se distingue de la descripción del evento.
  final String? quote;

  final DateTime createdAt;
  final bool read;

  ActivityBucket bucket({DateTime? now}) =>
      ActivityBucket.of(createdAt, now: now);

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    type: type,
    actor: actor,
    title: title,
    detail: detail,
    quote: quote,
    createdAt: createdAt,
    read: read ?? this.read,
  );

  @override
  List<Object?> get props => [
    id,
    type,
    actor,
    title,
    detail,
    quote,
    createdAt,
    read,
  ];
}

/// El evento destacado que encabeza la pantalla.
///
/// Es un tipo aparte y no una notificación con un flag: lleva datos que
/// ninguna fila tiene (cuánto falta, quiénes participan) y una sola acción
/// propia. Un flag habría obligado a que cada fila cargue campos que no usa.
class FeaturedActivity extends Equatable {
  const FeaturedActivity({
    required this.title,
    required this.detail,
    required this.startsIn,
    required this.participants,
    this.reminderSet = false,
  });

  final String title;
  final String detail;

  /// Cuánto falta para que empiece.
  final Duration startsIn;

  final List<String> participants;
  final bool reminderSet;

  FeaturedActivity copyWith({bool? reminderSet}) => FeaturedActivity(
    title: title,
    detail: detail,
    startsIn: startsIn,
    participants: participants,
    reminderSet: reminderSet ?? this.reminderSet,
  );

  @override
  List<Object?> get props => [
    title,
    detail,
    startsIn,
    participants,
    reminderSet,
  ];
}
