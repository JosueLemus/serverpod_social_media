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

  /// Cuánto asoma la insignia del rol por encima de la tarjeta.
  static const _badgeOverhang = 10.0;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              children: [
                Row(
                  children: [
                    // El anillo lima es el del staff, igual que en la barra.
                    UserAvatar(
                      name: user.name,
                      imageUrl: user.avatarUrl,
                      size: 72,
                      ring: user.canModerate ? AppColors.vinylLime : null,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            key: const Key('account-profile-name'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.headlineMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${user.username} · ${user.email}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // El rol es un objeto: un sticker con la insignia pegada en
                // el borde, apenas torcida.
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: _badgeOverhang),
                      child: StickerCard(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        // El tema se lee adentro de la tarjeta, que lo
                        // invierte a tinta.
                        child: Builder(
                          builder: (context) => Text(
                            _roleDetail,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: AppSpacing.md,
                      child: StatusBadge(
                        key: const Key('account-profile-role'),
                        label: _roleLabel.toUpperCase(),
                        color: user.canModerate
                            ? AppColors.vinylLime
                            : AppColors.vinylCyan,
                        foreground: AppColors.ink,
                        tilt: -.05,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (user.isOperator) ...[
                  FilledButton.icon(
                    key: const Key('account-profile-admin'),
                    onPressed: () => context.go(AppRoutes.admin),
                    icon: const NexoIcon(NexoGlyph.console, size: 20),
                    label: const Text('Abrir consola de operador'),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                if (user.canModerate) ...[
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.moderation),
                    icon: const NexoIcon(NexoGlyph.moderation, size: 20),
                    label: const Text('Abrir moderación'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                // La cuenta: una sección agrupada, como los ajustes.
                Material(
                  color: AppColors.surface,
                  clipBehavior: Clip.antiAlias,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.medium,
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      // Editar y volverse creador. Al volver, la sesión ya se
                      // releyó (lo hace la pantalla de editar), y si ahora es
                      // creador el perfil pasa solo a la vista de creador.
                      ListTile(
                        key: const Key('account-profile-edit'),
                        leading: const NexoIcon(NexoGlyph.profile, size: 22),
                        title: const Text('Editar perfil'),
                        trailing: const NexoIcon(
                          NexoGlyph.forward,
                          size: 18,
                          color: AppColors.textTertiary,
                        ),
                        onTap: () => unawaited(
                          context.push<bool>(AppRoutes.editProfile),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const NexoIcon(NexoGlyph.settings, size: 22),
                        title: const Text('Ajustes'),
                        trailing: const NexoIcon(
                          NexoGlyph.forward,
                          size: 18,
                          color: AppColors.textTertiary,
                        ),
                        onTap: () =>
                            unawaited(context.push(AppRoutes.settings)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton.icon(
                  key: const Key('account-profile-sign-out'),
                  // Sin navegar: el cambio de sesión mueve al usuario.
                  onPressed: () =>
                      unawaited(context.read<AuthCubit>().signOut()),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    minimumSize: const Size(0, AppSizes.buttonHeightDense),
                  ),
                  icon: const NexoIcon(NexoGlyph.logout, size: 20),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
