import '../entities/app_notification.dart';

/// La bandeja de Actividad. En Serverpod la arma el servidor: quién siguió,
/// quién likeó, quién salió al aire. El cliente sólo la lee y marca.
abstract interface class NotificationRepository {
  /// De la más nueva a la más vieja. [cursor] es el `nextCursor` de la página
  /// anterior, opaco para quien llama.
  Future<NotificationFeedPage> list({String? cursor});

  Future<int> unreadCount();

  /// Marca [ids] como leídas y devuelve cuántas quedan sin leer.
  Future<int> markRead(List<String> ids);

  /// Marca **todas**, no sólo las cargadas. Devuelve 0.
  Future<int> markAllRead();

  /// Cada aviso nuevo, en el momento. Sin sesión, el stream falla.
  Stream<AppNotification> watch();

  /// Cuántas quedan sin leer después de cada marca hecha desde este
  /// dispositivo. Es lo que baja el badge sin volver a preguntar.
  Stream<int> unreadChanges();

  /// El evento que encabeza la pantalla, si hay uno. Null cuando no.
  Future<FeaturedActivity?> featured();
}
