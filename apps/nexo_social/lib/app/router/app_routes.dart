/// Toda ruta de la app, en un solo lugar.
///
/// Los call sites usan estas constantes en vez de literales. Un literal mal
/// escrito no falla al compilar: `context.go('/activty')` construye bien y
/// aterriza en la pantalla de ruta no encontrada en runtime, y un rename deja
/// el literal viejo en el archivo que nadie grepeó.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const passwordReset = '/password-reset';

  /// Inicio: el feed y, desde que Explorar dejó de ser una pestaña, también el
  /// descubrimiento (buscador, próximos vivos, replays y tendencias). Menos
  /// pestañas fue decisión del equipo: descubrir es algo que se hace desde el
  /// feed, no una sección aparte a la que hay que acordarse de ir.
  static const feed = '/';

  /// La pestaña Explorar ya no existe. La ruta queda sólo para que un enlace
  /// viejo (`/explore`, `/explore/live/<id>`) redirija a donde vive ahora ese
  /// contenido en vez de dar una pantalla en blanco.
  static const legacyExplore = '/explore';

  static const activity = '/activity';

  /// El perfil propio. Es una pestaña, así que no lleva usuario.
  static const profile = '/profile';

  /// El perfil de otra persona. Ruta raíz empujada sobre el shell, no
  /// sub-ruta de la pestaña: empujar entre branches deja la página en el
  /// Navigator del branch de perfil mientras en pantalla está el del feed, así
  /// que no pasa nada visible y el back popea algo que el usuario nunca vio.
  static const userProfile = '/u';

  static const studio = '/studio';

  /// El Studio sobre un show puntual del host. Sin él, abre el que está al
  /// aire o el próximo programado.
  static const studioShowParam = 'show';
  static String studioFor(String showId) => '$studio?$studioShowParam=$showId';
  static const moderation = '/moderation';

  /// La consola del operador. Separada de [moderation] a propósito: el
  /// moderador actúa sobre una comunidad, el operador sobre la plataforma, y
  /// colapsarlos deja a la auditoría sin poder responder quién tenía derecho
  /// a qué.
  static const admin = '/admin';

  /// Donde queda una sesión revocada por una sanción.
  static const suspended = '/suspended';

  static const create = '/create';

  /// Agendar un show. Ruta raíz empujada sobre el shell, como el compositor:
  /// se llega desde el menú de crear, que es una acción y no una pestaña.
  static const scheduleShow = '/schedule-show';
  static const premium = '/premium';
  static const settings = '/settings';

  /// Elegir el tema de la app. Se entra desde el perfil y se empuja sobre el
  /// shell, como Ajustes.
  static const themes = '/themes';

  /// Editar el perfil propio. Una tarea: se empuja sobre el shell, como el
  /// compositor, para que la barra no invite a dejarla a medias.
  static const editProfile = '/edit-profile';

  /// Mensajes directos (SDD 0010). La bandeja es una pestaña del shell, con su
  /// branch y su pila. Cada chat es una sub-ruta de esa pestaña que se dibuja
  /// sobre el shell, sin la barra: con el teclado abierto, la barra sólo le
  /// quita alto a la conversación.
  static const messages = '/messages';
  static const conversationSegment = ':conversationId';
  static const conversationWithSegment = 'with/:userId';
  static String conversation(String id) => '$messages/$id';

  /// El chat con [userId]: lo abre (o lo crea) al entrar. Es lo que usa el
  /// botón "Enviar mensaje" del perfil.
  static String conversationWith(String userId) => '$messages/with/$userId';

  /// Segmentos de sub-ruta. Relativos, porque go_router resuelve el `path` de
  /// un hijo contra su padre — una barra al principio lo volvería una ruta de
  /// nivel superior en silencio y rompería el branch en el que debía vivir.
  static const liveRoomSegment = 'live/:liveId';
  static const userProfilePath = '$userProfile/:username';

  /// La sala vive **dentro** del branch de Inicio, no en uno propio: se entra
  /// a un vivo desde el feed (historias, vivo destacado, próximos, búsqueda),
  /// y una sala en otro branch sería justamente el empuje entre branches que
  /// la nota de arriba prohíbe.
  static String liveRoom(String id) => '/live/$id';

  /// La ficha de una cuenta, dentro del branch de la consola.
  static const adminAccountSegment = 'account/:accountId';
  static String adminAccount(String id) => '$admin/account/$id';

  static String profileOf(String username) => '$userProfile/$username';

  /// Una publicación. Ruta raíz empujada sobre el shell, como [userProfile]:
  /// se abre desde el feed, la grilla de un perfil, una notificación o un
  /// enlace compartido, y en cualquiera de esos casos vive arriba del branch
  /// de donde se salió, no adentro de uno.
  static const postPrefix = '/p';
  static const postPath = '$postPrefix/:postId';
  static String post(String id) => '$postPrefix/$id';

  /// Rutas que un visitante (sesión de invitado) no puede abrir. Navegar es
  /// público; todo lo que escribe, cobra o modera necesita una cuenta real.
  static const authenticatedOnly = <String>{
    create,
    scheduleShow,
    studio,
    moderation,
    admin,
    premium,
    editProfile,
    messages,
  };

  /// Rutas que exigen el scope `moderator` o `admin`.
  ///
  /// Esconderlas no es seguridad —el repositorio rechaza igual— pero dejar
  /// entrar a quien no puede operar muestra una consola que responde que no a
  /// todo.
  static const moderatorOnly = <String>{moderation};

  /// Rutas que exigen el scope `admin`.
  static const operatorOnly = <String>{admin};

  /// Rutas del flujo sin sesión. Caer en una de ellas con sesión viva
  /// significa que la sesión se acaba de restaurar, así que el redirect manda
  /// al usuario adentro.
  static const publicOnly = <String>{splash, signIn, signUp, passwordReset};

  /// Las páginas que se comparten por enlace: un perfil (`/u/<usuario>`) y
  /// una publicación (`/p/<id>`). Las abre cualquiera, con o sin sesión: es
  /// lo que recibe alguien por WhatsApp, y mandarlo a iniciar sesión antes de
  /// ver lo que le pasaron lo pierde en la puerta.
  static bool isSharedPage(String location) {
    final path = Uri.parse(location).path;
    return path.startsWith('$userProfile/') || path.startsWith('$postPrefix/');
  }
}
