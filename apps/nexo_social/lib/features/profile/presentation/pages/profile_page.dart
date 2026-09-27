import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/nexo_logo.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../bloc/profile_cubit.dart';

/// Mobile-first creator profile. The header and tabs share one scroll view,
/// preventing the former nested ListView/TabBarView transition issue.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.username});
  final String username;

  @override
  Widget build(BuildContext context) => FutureBuilder<AppUser?>(
    future: sl<AuthRepository>().currentUser(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final user = snapshot.data;
      if (user == null || user.role == UserRole.visitor) {
        return const _GuestProfilePage();
      }
      return _CreatorProfilePage(username: username);
    },
  );
}

class _CreatorProfilePage extends StatelessWidget {
  const _CreatorProfilePage({required this.username});
  final String username;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ProfileCubit(sl(), username),
    child: DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            const _ProfileCover(),
            const SliverToBoxAdapter(child: _ProfileSummary()),
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

class _GuestProfilePage extends StatelessWidget {
  const _GuestProfilePage();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const NexoLogo(size: 108),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Tu perfil te está esperando.',
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Inicia sesión o crea una cuenta para publicar, seguir creadores y construir tu comunidad.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go('/sign-in'),
                    child: const Text('Iniciar sesión'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/sign-up'),
                    child: const Text('Crear cuenta'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Estás explorando como invitado. Tu acceso no se guardará al cerrar la app.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ProfileCover extends StatelessWidget {
  const _ProfileCover();

  @override
  Widget build(BuildContext context) => SliverAppBar(
    pinned: true,
    automaticallyImplyLeading: false,
    expandedHeight: 184,
    toolbarHeight: 56,
    backgroundColor: AppColors.surface,
    title: const Text('Perfil'),
    actions: [
      IconButton(
        tooltip: 'Opciones del perfil',
        onPressed: () => _showProfileActions(context),
        icon: const Icon(Icons.more_horiz),
      ),
      const SizedBox(width: AppSpacing.xs),
    ],
    flexibleSpace: FlexibleSpaceBar(
      background: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
            ),
          ),
          Positioned(
            top: 66,
            left: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: AppRadii.small,
                border: Border.all(color: Colors.white.withValues(alpha: .26)),
              ),
              child: const Text(
                'CREADORA PRO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showProfileActions(BuildContext context) async {
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
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Ajustes'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.go('/settings');
              },
            ),
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

  if (shouldSignOut != true || !context.mounted) return;
  await sl<AuthCubit>().signOut();
  if (context.mounted) context.go('/sign-in');
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
          58,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Elena Vega',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColors.primary,
                        size: 19,
                      ),
                    ],
                  ),
                ),
                const _OnlineBadge(),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            const Text(
              '@elena.crea',
              style: TextStyle(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Diseñadora de producto y Flutter. Comparto procesos, talleres y recursos para crear con intención.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  size: 17,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  'elenavega.studio',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: BlocBuilder<ProfileCubit, bool>(
                    builder: (context, following) => FilledButton.icon(
                      onPressed: () => context.read<ProfileCubit>().toggle(),
                      icon: Icon(
                        following ? Icons.check : Icons.person_add_alt_1,
                      ),
                      label: Text(following ? 'Siguiendo' : 'Seguir'),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                OutlinedButton(
                  onPressed: () => context.go('/premium'),
                  child: const Text('Pase Pro'),
                ),
                IconButton(
                  tooltip: 'Compartir',
                  onPressed: () {},
                  icon: const Icon(Icons.ios_share_outlined),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const _ProfileMetrics(),
          ],
        ),
      ),
      const Positioned(top: -48, left: AppSpacing.md, child: _Avatar()),
    ],
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar();
  @override
  Widget build(BuildContext context) => Container(
    width: 96,
    height: 96,
    padding: const EdgeInsets.all(4),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      shape: BoxShape.circle,
    ),
    child: const CircleAvatar(
      backgroundColor: AppColors.primarySurface,
      child: Icon(
        Icons.auto_awesome_rounded,
        color: AppColors.primary,
        size: 38,
      ),
    ),
  );
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 5),
    decoration: const BoxDecoration(
      color: Color(0xFFEAF8EF),
      borderRadius: AppRadii.small,
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, color: AppColors.success, size: 8),
        SizedBox(width: 5),
        Text(
          'Activa',
          style: TextStyle(
            color: AppColors.success,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _ProfileMetrics extends StatelessWidget {
  const _ProfileMetrics();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    decoration: const BoxDecoration(
      color: AppColors.primarySurface,
      borderRadius: AppRadii.medium,
    ),
    child: const Row(
      children: [
        _Metric(value: '18.4K', label: 'Seguidores'),
        _Metric(value: '420', label: 'Siguiendo'),
        _Metric(value: '1.2K', label: 'Miembros Pro'),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
    color: AppColors.surface,
    child: TabBar(
      tabs: [
        Tab(text: 'Publicaciones'),
        Tab(text: 'En vivos'),
        Tab(text: 'Premium'),
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
      _PostPreview(),
      SizedBox(height: AppSpacing.md),
      _PostPreview(isSecond: true),
    ],
  );
}

class _PostPreview extends StatelessWidget {
  const _PostPreview({this.isSecond = false});
  final bool isSecond;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                child: Icon(Icons.auto_awesome_rounded, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Elena Vega',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Text(
                '2 h',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isSecond
                ? 'Un pequeño recordatorio: los sistemas también pueden sentirse humanos.'
                : 'Así estoy estructurando una librería de componentes que escala con un equipo pequeño.',
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            height: 120,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: AppRadii.small,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome,
              color: AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Row(
            children: [
              Icon(Icons.favorite_border, size: 19),
              SizedBox(width: 5),
              Text('248'),
              SizedBox(width: AppSpacing.md),
              Icon(Icons.chat_bubble_outline, size: 18),
              SizedBox(width: 5),
              Text('18'),
            ],
          ),
        ],
      ),
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
              const _LiveLabel(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Diseñemos en vivo: un sistema que no se rompe',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Mañana · 19:00',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => context.go('/live'),
                child: const Text('Ver en vivos'),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _LiveLabel extends StatelessWidget {
  const _LiveLabel();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      color: Color(0xFFEAF8EF),
      borderRadius: AppRadii.small,
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      child: Text(
        'PRÓXIMO EN VIVO',
        style: TextStyle(
          color: AppColors.success,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
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
      Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: AppRadii.medium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              color: AppColors.primary,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Contenido para miembros Pro',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Plantillas, sesiones privadas y notas de proceso de Elena.',
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => context.go('/premium'),
              child: const Text('Conocer Pase Pro'),
            ),
          ],
        ),
      ),
    ],
  );
}
