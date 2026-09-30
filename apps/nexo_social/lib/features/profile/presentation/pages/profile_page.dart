import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/widgets/nexo_logo.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../bloc/profile_cubit.dart';
import '../bloc/profile_status_cubit.dart';

part 'account_profile_view.dart';

/// Perfil de creador. La portada y las pestañas comparten un solo scroll view,
/// que es lo que mantiene la tab bar fijada sin pelearse con las listas
/// internas.
///
/// [username] es null cuando es el perfil propio: la pestaña del shell no
/// tiene nombre que pasar, y hardcodear uno (era `nexo`) abre el perfil de un
/// desconocido para todo el mundo.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.username});

  final String? username;

  @override
  Widget build(BuildContext context) {
    // La sesión sale del cubit compartido. Esto era un FutureBuilder sobre
    // `sl<AuthRepository>().currentUser()`, que ponía una llamada de datos en
    // un widget, releía disco en cada rebuild y no se enteraba de un cierre de
    // sesión ocurrido en otra parte del árbol.
    final auth = context.watch<AuthCubit>().state;
    if (auth is AuthLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = auth is AuthAuthenticated ? auth.user : null;
    if (user == null || user.role == UserRole.visitor) {
      return const _GuestProfileView();
    }
    // El perfil propio de una cuenta que no crea contenido. Antes todas
    // caían en la vista de creadora, que está escrita con el contenido de
    // Elena: el operador abría "su" perfil y leía @elena_ux, y no había
    // forma de ver con qué cuenta y con qué rol se estaba.
    if (username == null && !user.isCreator) {
      return _AccountProfileView(user: user);
    }
    return _CreatorProfileView(username: username ?? user.username);
  }
}

class _CreatorProfileView extends StatelessWidget {
  const _CreatorProfileView({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => ProfileCubit(sl(), username)),
      BlocProvider(create: (_) => ProfileStatusCubit(sl(), username)..load()),
    ],
    child: DefaultTabController(
      length: 3,
      // La pantalla se muestra en dos lugares: como pestaña Perfil dentro del
      // shell, y empujada a pantalla completa cuando se abre el perfil de
      // otra persona desde el feed. Lleva Scaffold propio para que el caso
      // empujado tenga superficie y botón de volver; dentro del shell la capa
      // extra es inocua porque la portada sangra igual.
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _ProfileHeader(username: username),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabsHeaderDelegate(),
            ),
          ],
          body: const TabBarView(
            children: [_PostsTab(), _LivesTab(), _PremiumTab()],
          ),
        ),
      ),
    ),
  );
}

/// Lo que ve un invitado donde estaría su perfil: la razón para crear una
/// cuenta, no una pantalla vacía.
class _GuestProfileView extends StatelessWidget {
  const _GuestProfileView();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Enter(child: NexoLogo(size: 108)),
              const SizedBox(height: AppSpacing.lg),
              Enter(
                index: 1,
                child: Text(
                  'Tu perfil te está esperando.',
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Enter(
                index: 2,
                child: Text(
                  'Inicia sesión o crea una cuenta para publicar, seguir '
                  'creadores y construir tu comunidad.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Los dos CTA sólo aparecen: un deslizamiento los dejaría
              // desplazados de donde se dibujan mientras el usuario ya está
              // yendo a tocarlos.
              EnterStatic(
                index: 3,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go(AppRoutes.signIn),
                    child: const Text('Iniciar sesión'),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              EnterStatic(
                index: 4,
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go(AppRoutes.signUp),
                    child: const Text('Crear cuenta'),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Estás explorando como invitado. Tu acceso no se guardará al '
                'cerrar la app.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Portada + barra de acciones, en un solo sliver.
///
/// Deliberadamente **no** es un `SliverAppBar`. El avatar se monta a caballo
/// entre la portada y el resumen, y un sliver recorta lo que se sale de su
/// caja: con la portada en su propio sliver, la mitad superior del avatar
/// desaparecía. Acá portada, avatar y resumen comparten una sola caja, así que
/// el solape es interno y no hay nada que recortar.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.username});

  final String username;

  static const _coverHeight = 150.0;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _coverHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _CoverBackground(),
              SafeArea(bottom: false, child: _CoverToolbar(username: username)),
            ],
          ),
        ),
        const _SanctionBanner(),
        const _ProfileSummary(),
      ],
    ),
  );
}

/// Una sanción que no se ve desde afuera no se puede demostrar. El banner va
/// arriba del resumen, donde se lee antes que cualquier otra cosa del perfil.
class _SanctionBanner extends StatelessWidget {
  const _SanctionBanner();

  @override
  Widget build(BuildContext context) {
    final status = context.watch<ProfileStatusCubit>().state.status;
    if (status == AccountStatus.active) return const SizedBox.shrink();
    return Container(
      key: const Key('profile-sanctioned'),
      width: double.infinity,
      color: AppColors.error,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          const Icon(Icons.gpp_bad_outlined, color: Colors.white, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              status == AccountStatus.banned
                  ? 'Esta cuenta fue dada de baja por incumplir las normas.'
                  : 'Esta cuenta está suspendida por incumplir las normas.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverToolbar extends StatelessWidget {
  const _CoverToolbar({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: AppSpacing.xs),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // La flecha aparece sólo si hay algo que popear, que es exactamente el
        // caso empujado. Como raíz de la pestaña Perfil no hay a dónde volver.
        if (Navigator.of(context).canPop())
          const BackButton(color: Colors.white)
        else
          const SizedBox(width: AppSpacing.md,),
        Padding(
          padding: EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            '@$username',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Compartir perfil',
          color: Colors.white,
          onPressed: () {},
          icon: const Icon(Icons.ios_share_rounded, size: 20),
        ),
        IconButton(
          tooltip: 'Opciones del perfil',
          color: Colors.white,
          onPressed: () => unawaited(_showProfileActions(context)),
          icon: const Icon(Icons.more_vert_rounded),
        ),
        const SizedBox(width: AppSpacing.xxs),
      ],
    ),
  );
}

class _CoverBackground extends StatelessWidget {
  const _CoverBackground();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDeep],
          ),
        ),
      ),
      Positioned(
        right: AppSpacing.md,
        bottom: AppSpacing.sm,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .18),
            borderRadius: AppRadii.pill,
            border: Border.all(color: Colors.white.withValues(alpha: .3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 12, color: Colors.white),
              SizedBox(width: 5),
              Text(
                'PRO CREADOR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .7,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

Future<void> _showProfileActions(BuildContext context) async {
  final auth = context.read<AuthCubit>().state;
  final user = auth is AuthAuthenticated ? auth.user : null;
  final shouldSignOut = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Creator Studio'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.go(AppRoutes.studio);
              },
            ),
            // Por rol, igual que el rail. En el teléfono la barra ya tiene
            // cinco entradas, así que la consola se alcanza desde acá.
            if (user?.canModerate ?? false)
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('Moderación'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(AppRoutes.moderation);
                },
              ),
            if (user?.isOperator ?? false)
              ListTile(
                key: const Key('profile-admin'),
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Consola de operador'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(AppRoutes.admin);
                },
              ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Ajustes'),
              onTap: () {
                Navigator.pop(sheetContext);
                unawaited(context.push(AppRoutes.settings));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => Navigator.pop(sheetContext, true),
            ),
          ],
        ),
      ),
    ),
  );

  if (shouldSignOut != true) return;
  // Sin navegación acá a propósito. Cerrar sesión cambia el estado, el
  // refreshListenable del router lo ve y el redirect mueve al usuario. Navegar
  // además competiría con la guarda y, con el context de la hoja ya muerto,
  // `Navigator.of` sobre un Element desactivado revienta dentro de un `!` sin
  // mensaje legible.
  await sl<AuthCubit>().signOut();
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary();

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          52,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Elena Vega',
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColors.primary,
                        size: 19,
                      ),
                    ],
                  ),
                ),
                const StatusBadge(
                  label: 'Online',
                  color: AppColors.successSurface,
                  foreground: AppColors.tertiary,
                  pulse: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            const Text(
              '@elena_ux',
              style: TextStyle(
                color: AppColors.textOnBrandSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Diseñadora de Producto & Mentora de Creadores. Construyendo el '
              'futuro de la economía creativa ✨',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 5),
                Text(
                  'nexo.link/elena',
                  style: TextStyle(
                    color: AppColors.textOnBrandSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const _ProfileMetrics(),
            const SizedBox(height: AppSpacing.md),
            const _ProfileActions(),
            const SizedBox(height: AppSpacing.md),
            const _VipCard(),
          ],
        ),
      ),
      const Positioned(top: -44, left: AppSpacing.md, child: _Avatar()),
    ],
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
        ),
        child: const UserAvatar(name: 'Elena Vega', size: 86),
      ),
      Positioned(
        right: 2,
        bottom: 2,
        child: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.primaryDeep,
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              BorderSide(color: AppColors.background, width: 2),
            ),
          ),
          child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
        ),
      ),
    ],
  );
}

/// Seguidores · Siguiendo · Likes, en línea y sin tarjeta.
///
/// El diseño los pone sueltos bajo la bio: una tarjeta de color los convierte
/// en un bloque que compite con el pase VIP, que es lo que de verdad quiere
/// atención en esta pantalla.
class _ProfileMetrics extends StatelessWidget {
  const _ProfileMetrics();

  @override
  Widget build(BuildContext context) => const Wrap(
    spacing: AppSpacing.lg,
    runSpacing: AppSpacing.xs,
    children: [
      _Metric(value: '48.5K', label: 'Seguidores'),
      _Metric(value: '320', label: 'Siguiendo'),
      _Metric(value: '1.2M', label: 'Likes'),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        value,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
      ),
    ],
  );
}

class _ProfileActions extends StatelessWidget {
  const _ProfileActions();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: BlocBuilder<ProfileCubit, bool>(
          builder: (context, following) => SizedBox(
            height: AppSizes.buttonHeightDense,
            child: following
                ? OutlinedButton.icon(
                    key: const Key('profile-follow'),
                    onPressed: () => context.read<ProfileCubit>().toggle(),
                    icon: const Icon(Icons.check_rounded, size: 17),
                    label: const Text('Siguiendo'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, AppSizes.buttonHeightDense),
                      foregroundColor: AppColors.textSecondary,
                    ),
                  )
                : FilledButton.icon(
                    key: const Key('profile-follow'),
                    onPressed: () => context.read<ProfileCubit>().toggle(),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
                    label: const Text('Seguir'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, AppSizes.buttonHeightDense),
                    ),
                  ),
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.xs),
      Expanded(
        child: SizedBox(
          height: AppSizes.buttonHeightDense,
          child: FilledButton.icon(
            onPressed: () => unawaited(context.push(AppRoutes.premium)),
            icon: const Icon(Icons.star_rounded, size: 17),
            label: const Text('Suscribirse'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(0, AppSizes.buttonHeightDense),
            ),
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.xxs),
      IconButton.outlined(
        tooltip: 'Enviar mensaje',
        onPressed: () {},
        icon: const Icon(Icons.mail_outline_rounded, size: 19),
      ),
    ],
  );
}

class _VipCard extends StatelessWidget {
  const _VipCard();

  static const _perks = [
    'Acceso a directos semanales privados & Q&A',
    'Descargas de UI Kits y plantillas Figma Pro',
    'Canal de chat privado en vivo con Elena',
  ];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.primarySurface,
      borderRadius: AppRadii.medium,
      border: Border.all(color: AppColors.primarySurfaceDeep),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surface,
              child: Icon(
                Icons.workspace_premium_rounded,
                size: 18,
                color: AppColors.primaryDeep,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pase Creador VIP',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  const Text(
                    'MEMBRESÍA EXCLUSIVA',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'Desde \$4.99/mes',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textOnBrandSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final perk in _perks)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 15,
                  color: AppColors.tertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    perk,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('profile-join-vip'),
            onPressed: () => unawaited(context.push(AppRoutes.premium)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primaryDeep,
              minimumSize: const Size(0, AppSizes.buttonHeightDense),
            ),
            child: const Text('Unirme por \$4.99'),
          ),
        ),
      ],
    ),
  );
}

class _TabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => kTextTabBarHeight;

  @override
  double get maxExtent => kTextTabBarHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => const Material(
    color: AppColors.background,
    child: TabBar(
      tabs: [
        Tab(text: 'Publicaciones'),
        Tab(text: 'En vivos'),
        // El candado dice que la pestaña existe y está cerrada. Esconderla
        // haría que el pase VIP prometa algo sin lugar donde verse.
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: Text('Premium', overflow: TextOverflow.ellipsis)),
              SizedBox(width: 5),
              Icon(Icons.lock_outline_rounded, size: 13),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  bool shouldRebuild(covariant _TabsHeaderDelegate oldDelegate) => false;
}

class _PostsTab extends StatelessWidget {
  const _PostsTab();

  @override
  Widget build(BuildContext context) => ListView(
    key: const PageStorageKey('profile-posts'),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      96,
    ),
    children: const [
      _RecordedLiveCard(),
      SizedBox(height: AppSpacing.md),
      _PostGrid(),
    ],
  );
}

/// El replay destacado del creador: la pieza con más peso de la pestaña.
class _RecordedLiveCard extends StatelessWidget {
  const _RecordedLiveCard();

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDeep, AppColors.stageDark],
                  ),
                ),
              ),
              const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white70,
                  size: 48,
                ),
              ),
              const Positioned(
                top: AppSpacing.xs,
                left: AppSpacing.xs,
                child: StatusBadge(
                  label: 'En vivo grabado',
                  icon: Icons.fiber_manual_record_rounded,
                ),
              ),
              Positioned(
                bottom: AppSpacing.xs,
                right: AppSpacing.xs,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.neutral.withValues(alpha: .6),
                    borderRadius: AppRadii.pill,
                  ),
                  child: const Text(
                    '52:14',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 3),
                  Text('14.2K', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.favorite_rounded,
                    size: 14,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 3),
                  Text('3.8K', style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      'Hace 2 días',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Masterclass: Arquitectura de Sistemas de Diseño',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Revisamos tokens semánticos, sincronización con código y cómo '
                'cobrar \$5k USD por proyecto.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Rejilla de dos columnas, como el diseño. `shrinkWrap` porque vive dentro de
/// otra lista: sin él no tiene altura acotada y revienta en layout.
class _PostGrid extends StatelessWidget {
  const _PostGrid();

  static const _items = [
    ('3 errores típicos al diseñar interfaces', '8.4K', '1,240', '4d', false),
    ('Librería de Componentes v2.4 libre', '19.1K', '2,890', '1sem', false),
    ('Resumen charla UX: ¿Cómo monetizar?', '31.5K', '4,510', '2sem', false),
    ('Plantilla Contratos Freelance 2026', '—', '—', '', true),
  ];

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: EdgeInsets.zero,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: .78,
    ),
    itemCount: _items.length,
    itemBuilder: (context, index) {
      final (title, views, likes, age, locked) = _items[index];
      return _GridTile(
        title: title,
        views: views,
        likes: likes,
        age: age,
        locked: locked,
      );
    },
  );
}

class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.title,
    required this.views,
    required this.likes,
    required this.age,
    required this.locked,
  });

  final String title;
  final String views;
  final String likes;
  final String age;
  final bool locked;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primarySurface,
                      AppColors.primarySurfaceDeep,
                    ],
                  ),
                ),
              ),
              if (locked)
                // Bloqueado pero visible: esconderlo no vende nada, y
                // mostrarlo entero regalaría lo que el pase cobra.
                ColoredBox(
                  color: AppColors.neutral.withValues(alpha: .55),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, color: Colors.white, size: 22),
                        SizedBox(height: 5),
                        Text(
                          'VIP EXCLUSIVO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .6,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Positioned(
                  top: AppSpacing.xs,
                  left: AppSpacing.xs,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neutral.withValues(alpha: .5),
                      borderRadius: AppRadii.pill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility_outlined,
                          size: 11,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          views,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              if (locked)
                Text(
                  'Desbloquear',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textOnBrandSurface,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      size: 11,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      likes,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      age,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LivesTab extends StatelessWidget {
  const _LivesTab();

  @override
  Widget build(BuildContext context) => ListView(
    key: const PageStorageKey('profile-lives'),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      96,
    ),
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusBadge(
                label: 'Próximo en vivo',
                color: AppColors.successSurface,
                foreground: AppColors.tertiary,
                icon: Icons.schedule_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Diseñemos en vivo: un sistema que no se rompe',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Jueves · 19:00 GMT-3',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => context.go(AppRoutes.explore),
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        size: 17,
                      ),
                      label: const Text('Recordar'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, AppSizes.buttonHeightDense),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _PremiumTab extends StatelessWidget {
  const _PremiumTab();

  @override
  Widget build(BuildContext context) => ListView(
    key: const PageStorageKey('profile-premium'),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      96,
    ),
    children: [
      Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: AppColors.primarySurface,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: AppColors.textOnBrandSurface,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'EXCLUSIVO SUSCRIPTORES',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .7,
                      color: AppColors.textOnBrandSurface,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pack de Tokens CSS & Variables Flutter 3.22',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Incluye archivo JSON estructurado con compatibilidad para '
                    'Figma Tokens Studio y exportables directos en Dart.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.folder_outlined,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '24.5 MB · 4 archivos',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 36,
                        child: FilledButton(
                          onPressed: () =>
                              unawaited(context.push(AppRoutes.premium)),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Desbloquear'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
