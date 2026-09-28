part of 'profile_page.dart';

/// El perfil de una cuenta sin contenido propio: quién es, qué rol tiene y,
/// si modera, la puerta a su trabajo.
class _AccountProfileView extends StatelessWidget {
  const _AccountProfileView({required this.user});

  final AppUser user;

  String get _roleLabel => switch (user.role) {
    UserRole.operator => 'Operador',
    UserRole.moderator => 'Moderador',
    UserRole.user || UserRole.visitor => 'Usuario',
  };

  String get _roleDetail => switch (user.role) {
    UserRole.operator =>
      'Actúas sobre toda la plataforma: suspender y banear cuentas, '
          'verificar creadores, cortar vivos y auditar. Cada acción queda '
          'registrada con tu nombre.',
    UserRole.moderator =>
      'Revisas la cola de reportes: ocultar comentarios, silenciar y '
          'expulsar de un vivo. No puedes sancionar cuentas ni verificar '
          'creadores.',
    UserRole.user || UserRole.visitor =>
      'Consumes, comentas y reportas. No tienes acceso a moderación ni a la '
          'consola.',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Row(
                children: [
                  UserAvatar(
                    name: user.name,
                    size: 64,
                    ring: user.canModerate ? AppColors.primaryDeep : null,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          key: const Key('account-profile-name'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '@${user.username} · ${user.email}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusBadge(
                        key: const Key('account-profile-role'),
                        label: _roleLabel.toUpperCase(),
                        color: user.canModerate
                            ? AppColors.primaryDeep
                            : AppColors.textSecondary,
                        icon: user.canModerate ? Icons.shield_rounded : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _roleDetail,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (user.isOperator)
                FilledButton.icon(
                  key: const Key('account-profile-admin'),
                  onPressed: () => context.go(AppRoutes.admin),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Abrir consola de operador'),
                ),
              if (user.canModerate) ...[
                const SizedBox(height: AppSpacing.xs),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.moderation),
                  icon: const Icon(Icons.shield_outlined),
                  label: const Text('Abrir moderación'),
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              OutlinedButton.icon(
                onPressed: () => unawaited(context.push(AppRoutes.settings)),
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Ajustes'),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton.icon(
                key: const Key('account-profile-sign-out'),
                // Sin navegar: el cambio de sesión mueve al usuario.
                onPressed: () => unawaited(context.read<AuthCubit>().signOut()),
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                label: const Text(
                  'Cerrar sesión',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
