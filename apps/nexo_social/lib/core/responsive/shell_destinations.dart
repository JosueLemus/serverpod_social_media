import '../../app/router/app_routes.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../widgets/nexo_icon.dart';

/// Quién ve un destino. Esconder no es seguridad —el guard y el repositorio
/// rechazan igual—, pero un rail que ofrece la consola a quien no puede
/// usarla es una puerta pintada en la pared.
enum ShellAccess { everyone, moderator, operator }

/// Una entrada de la navegación del shell, compartida por la barra inferior y
/// el rail.
///
/// Las dos superficies leen la misma lista, así que un destino no puede
/// existir en teléfono y quedar inalcanzable en escritorio — que es
/// exactamente como `/studio` y `/moderation` terminaron siendo rutas sin
/// forma de llegar a ellas.
class ShellDestination {
  const ShellDestination({
    required this.branch,
    required this.path,
    required this.label,
    required this.glyph,
    this.desktopOnly = false,
    this.access = ShellAccess.everyone,
  });

  /// Índice del branch en [StatefulShellRoute]. Explícito y no posicional:
  /// filtrar la lista por form factor correría todos los índices posteriores
  /// al que se ocultó.
  final int branch;

  final String path;
  final String label;

  /// El ícono propio. En reposo se dibuja su contorno y seleccionado, su
  /// versión rellena: el cambio de forma es la marca de selección, como en
  /// una tab bar de iOS.
  final NexoGlyph glyph;

  /// Superficies de creador. Necesitan ancho y teclado, así que en teléfono se
  /// llegan desde el perfil y no desde la barra.
  final bool desktopOnly;

  final ShellAccess access;

  bool isVisibleTo(AppUser? user) => switch (access) {
    ShellAccess.everyone => true,
    ShellAccess.moderator => user?.canModerate ?? false,
    ShellAccess.operator => user?.isOperator ?? false,
  };
}

abstract final class ShellDestinations {
  static const all = <ShellDestination>[
    // Inicio también es descubrir: el buscador, los próximos vivos, los
    // replays y las tendencias viven ahí desde que Explorar dejó de ser una
    // pestaña. Con el compositor en el medio, la barra del teléfono queda
    // Inicio · Mensajes · + · Actividad · Perfil: dos destinos a cada lado.
    ShellDestination(
      branch: 0,
      path: AppRoutes.feed,
      label: 'Inicio',
      glyph: NexoGlyph.home,
    ),
    ShellDestination(
      branch: 1,
      path: AppRoutes.messages,
      label: 'Mensajes',
      glyph: NexoGlyph.comment,
    ),
    ShellDestination(
      branch: 2,
      path: AppRoutes.activity,
      label: 'Actividad',
      glyph: NexoGlyph.activity,
    ),
    ShellDestination(
      branch: 3,
      path: AppRoutes.profile,
      label: 'Perfil',
      glyph: NexoGlyph.profile,
    ),
    ShellDestination(
      branch: 4,
      path: AppRoutes.studio,
      label: 'Studio',
      glyph: NexoGlyph.studio,
      desktopOnly: true,
    ),
    ShellDestination(
      branch: 5,
      path: AppRoutes.moderation,
      label: 'Moderación',
      glyph: NexoGlyph.moderation,
      desktopOnly: true,
      access: ShellAccess.moderator,
    ),
    ShellDestination(
      branch: 6,
      path: AppRoutes.admin,
      label: 'Consola',
      glyph: NexoGlyph.console,
      desktopOnly: true,
      access: ShellAccess.operator,
    ),
  ];

  /// Lo que muestra el rail extendido a esta cuenta.
  static List<ShellDestination> expandedFor(AppUser? user) =>
      all.where((destination) => destination.isVisibleTo(user)).toList();

  /// Lo que muestra la barra inferior del teléfono.
  static List<ShellDestination> get compact =>
      all.where((destination) => !destination.desktopOnly).toList();
}
