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

  static const feed = '/';

  /// Descubrimiento: vivos, temas en tendencia y creadores.
  ///
  /// La pestaña se llama **Explorar**, no "En vivo". Lo dicen el diseño y el
  /// Notion: los vivos son un tipo de contenido dentro del descubrimiento, no
  /// una sección hermana del feed — y una pestaña dedicada a ellos deja sin
  /// entrada a perfiles y categorías.
  static const explore = '/explore';

  static const activity = '/activity';

  /// El perfil propio. Es una pestaña, así que no lleva usuario.
  static const profile = '/profile';

  /// El perfil de otra persona. Ruta raíz empujada sobre el shell, no
  /// sub-ruta de la pestaña: empujar entre branches deja la página en el
  /// Navigator del branch de perfil mientras en pantalla está el del feed, así
  /// que no pasa nada visible y el back popea algo que el usuario nunca vio.
  static const userProfile = '/u';

  static const studio = '/studio';
  static const moderation = '/moderation';

  /// La consola del operador. Separada de [moderation] a propósito: el
  /// moderador actúa sobre una comunidad, el operador sobre la plataforma, y
  /// colapsarlos deja a la auditoría sin poder responder quién tenía derecho
  /// a qué.
  static const admin = '/admin';

  /// Donde queda una sesión revocada por una sanción.
  static const suspended = '/suspended';

  static const create = '/create';
  static const premium = '/premium';
  static const settings = '/settings';

  /// Segmentos de sub-ruta. Relativos, porque go_router resuelve el `path` de
  /// un hijo contra su padre — una barra al principio lo volvería una ruta de
  /// nivel superior en silencio y rompería el branch en el que debía vivir.
  static const liveRoomSegment = 'live/:liveId';
  static const userProfilePath = '$userProfile/:username';

  /// La sala vive **dentro** del branch de Explorar, no en uno propio: se
  /// entra a un vivo desde el descubrimiento, y una sala en otro branch sería
  /// justamente el empuje entre branches que la nota de arriba prohíbe.
  static String liveRoom(String id) => '$explore/live/$id';

  /// La ficha de una cuenta, dentro del branch de la consola.
  static const adminAccountSegment = 'account/:accountId';
  static String adminAccount(String id) => '$admin/account/$id';

  static String profileOf(String username) => '$userProfile/$username';

  /// Rutas que un visitante (sesión de invitado) no puede abrir. Navegar es
  /// público; todo lo que escribe, cobra o modera necesita una cuenta real.
  static const authenticatedOnly = <String>{
    create,
    studio,
    moderation,
    admin,
    premium,
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
}
