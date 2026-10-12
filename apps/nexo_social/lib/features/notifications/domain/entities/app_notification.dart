import 'package:equatable/equatable.dart';

enum NotificationType {
  like('Me gusta'),
  follow('Seguidores'),
  comment('Comentarios'),

  /// Alguien que seguís salió al aire.
  liveReminder('Lives'),

  /// Un show que seguís empieza en minutos.
  showSoon('Próximos'),
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

/// Un aviso de la bandeja.
///
/// Lleva datos, no frases: qué pasó ([type]), quién ([actor]) y sobre qué
/// ([subject], [postId], [showId]). La oración la arma la View —un cubit o un
/// repositorio no tienen `BuildContext`, y una frase escrita en la capa de
/// datos no se puede traducir ni corregir en un solo lugar.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.createdAt,
    this.actor,
    this.actorUsername,
    this.actorAvatarUrl,
    this.subject,
    this.quote,
    this.postId,
    this.showId,
    this.read = false,
  });

  final String id;
  final NotificationType type;

  /// El nombre de quien lo hizo. Null en los avisos del sistema (un reporte
  /// resuelto): la View pone la marca en su lugar.
  final String? actor;

  /// Para abrir su perfil. Separado de [actor] porque el nombre se muestra y
  /// el username enruta.
  final String? actorUsername;
  final String? actorAvatarUrl;

  /// El título del show o el comienzo del post del que se habla.
  final String? subject;

  /// El texto de un comentario, cuando el aviso lo trae. Va en su propia
  /// tarjeta citada: dentro de la frase no se distingue del evento.
  final String? quote;

  final String? postId;
  final String? showId;
  final DateTime createdAt;
  final bool read;

  ActivityBucket bucket({DateTime? now}) =>
      ActivityBucket.of(createdAt, now: now);

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    type: type,
    createdAt: createdAt,
    actor: actor,
    actorUsername: actorUsername,
    actorAvatarUrl: actorAvatarUrl,
    subject: subject,
    quote: quote,
    postId: postId,
    showId: showId,
    read: read ?? this.read,
  );

  @override
  List<Object?> get props => [
    id,
    type,
    actor,
    actorUsername,
    actorAvatarUrl,
    subject,
    quote,
    postId,
    showId,
    createdAt,
    read,
  ];
}

/// Una página de la bandeja, de la más nueva a la más vieja. [nextCursor]
/// null es que no hay más.
class NotificationFeedPage extends Equatable {
  const NotificationFeedPage({required this.items, this.nextCursor});

  final List<AppNotification> items;
  final String? nextCursor;

  @override
  List<Object?> get props => [items, nextCursor];
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
