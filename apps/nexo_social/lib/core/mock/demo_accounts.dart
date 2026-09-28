/// Las cuentas sembradas del modo mock, en un solo lugar.
///
/// Las leen dos lados que no pueden importarse entre sí: la semilla de
/// `MockPlatform` (datos) y el selector de cuentas demo (presentación). Una
/// lista duplicada se desincroniza en la primera cuenta nueva y el selector
/// ofrece un correo que el mock no reconoce.
class DemoAccount {
  const DemoAccount({
    required this.id,
    required this.email,
    required this.username,
    required this.name,
    required this.description,
  });

  final String id;
  final String email;
  final String username;
  final String name;

  /// Qué papel juega en el guion de la demo.
  final String description;
}

abstract final class DemoAccounts {
  static const elena = DemoAccount(
    id: 'creator-1',
    email: 'elena@nexo.demo',
    username: 'elena_ux',
    name: 'Elena Vega',
    description: 'Creadora verificada · inicia el vivo',
  );
  static const carlos = DemoAccount(
    id: 'creator-carlos',
    email: 'carlos@nexo.demo',
    username: 'carlos_mendez',
    name: 'Carlos Méndez',
    description: 'Creador · tiene un vivo al aire',
  );
  static const operator = DemoAccount(
    id: 'op-1',
    email: 'operador@nexo.demo',
    username: 'nexo_ops',
    name: 'Operaciones Nexo',
    description: 'Operador · consola de administración',
  );
  static const moderator = DemoAccount(
    id: 'mod-1',
    email: 'moderador@nexo.demo',
    username: 'mod_lucia',
    name: 'Lucía Moderadora',
    description: 'Moderadora · cola de reportes',
  );
  static const viewer = DemoAccount(
    id: 'user-tomas',
    email: 'tomas@nexo.demo',
    username: 'tomas',
    name: 'Tomás Ríos',
    description: 'Espectador · reporta',
  );
  static const troll = DemoAccount(
    id: 'user-troll',
    email: 'troll@nexo.demo',
    username: 'troll_99',
    name: 'Troll 99',
    description: 'Espectador abusivo · recibe la sanción',
  );
  static const spammer = DemoAccount(
    id: 'user-promo',
    email: 'promo@nexo.demo',
    username: 'promo_bot',
    name: 'Promo Bot',
    description: 'Cuenta de spam',
  );

  /// En el orden en que aparecen en el selector.
  static const all = [elena, operator, moderator, viewer, troll, carlos];
}
