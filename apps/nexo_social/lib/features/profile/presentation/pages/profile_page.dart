import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/nexo_logo.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../feed/domain/entities/post.dart';
import '../../../live/domain/entities/live_session.dart';
import '../../../live/presentation/utils/live_status_ui.dart';
import '../../domain/entities/public_profile.dart';
import '../bloc/profile_cubit.dart';
import '../bloc/profile_status_cubit.dart';
import '../bloc/public_profile_cubit.dart';

part 'account_profile_view.dart';

/// El perfil de una cuenta. La portada y las pestañas comparten un solo
/// scroll view, que es lo que mantiene la tab bar fijada sin pelearse con las
/// listas internas.
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
    final isVisitor = user == null || user.role == UserRole.visitor;
    final other = username;
    // El perfil de otra persona es público: un visitante que abre
    // `/u/:username` ve a esa persona, no la invitación a crear una cuenta.
    if (other != null) {
      return _PublicProfileView(
        username: other,
        isOwn: !isVisitor && other == user.username,
        canAct: !isVisitor,
      );
    }
    if (isVisitor) return const _GuestProfileView();
    // El perfil propio de una cuenta que no crea contenido: su cuenta y su
    // rol. Antes todas caían en la vista de creadora, escrita con el
    // contenido de Elena: el operador abría "su" perfil y leía @elena_ux.
    if (!user.isCreator) return _AccountProfileView(user: user);
    return _PublicProfileView(
      username: user.username,
      isOwn: true,
      canAct: true,
    );
  }
}

/// El perfil público de [username], leído del servidor.
///
/// [isOwn] decide qué se ofrece: en el propio no hay "Seguir" ni
/// "Suscribirse", y el menú es el de la cuenta. [canAct] es falso para un
/// visitante, que puede mirar pero no seguir ni suscribirse.
class _PublicProfileView extends StatelessWidget {
  const _PublicProfileView({
    required this.username,
    required this.isOwn,
    required this.canAct,
  });

  final String username;
  final bool isOwn;
  final bool canAct;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => sl<PublicProfileCubit>(param1: username)..load(),
      ),
      BlocProvider(create: (_) => ProfileCubit(sl(), username)),
      BlocProvider(create: (_) => ProfileStatusCubit(sl(), username)..load()),
    ],
    // La pantalla se muestra en dos lugares: como pestaña Perfil dentro del
    // shell, y empujada a pantalla completa cuando se abre el perfil de otra
    // persona. Lleva Scaffold propio para que el caso empujado tenga
    // superficie y botón de volver; dentro del shell la capa extra es inocua
    // porque la portada sangra igual.
    child: Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<PublicProfileCubit, PublicProfileState>(
        builder: (context, state) => switch (state) {
          PublicProfileLoading() => const _ProfileStatusFrame(
            child: Center(child: CircularProgressIndicator()),
          ),
          PublicProfileNotFound() => _ProfileStatusFrame(
            child: AppEmptyView(
              icon: Icons.person_off_outlined,
              title: 'Esta cuenta no existe',
              message:
                  'Puede que haya cambiado de nombre de usuario o que ya no '
                  'esté en Nexo.',
              actionLabel: 'Explorar creadores',
              onAction: () => context.go(AppRoutes.explore),
            ),
          ),
          PublicProfileFailure(:final offline) => _ProfileStatusFrame(
            child: AppErrorView(
              isOffline: offline,
              onRetry: () =>
                  unawaited(context.read<PublicProfileCubit>().load()),
            ),
          ),
          PublicProfileLoaded() => _LoadedProfile(
            state: state,
            isOwn: isOwn,
            canAct: canAct,
          ),
        },
      ),
    ),
  );
}

/// Carga, error o "no existe", con la forma de volver que tiene el perfil
/// cargado.
class _ProfileStatusFrame extends StatelessWidget {
  const _ProfileStatusFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Navigator.of(context).canPop()
              ? const BackButton()
              : const SizedBox(height: kMinInteractiveDimension),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ],
    ),
  );
}

class _LoadedProfile extends StatelessWidget {
  const _LoadedProfile({
    required this.state,
    required this.isOwn,
    required this.canAct,
  });

  final PublicProfileLoaded state;
  final bool isOwn;
  final bool canAct;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    // Vivos y Premium son de creadores. Una cuenta que no crea contenido no
    // tiene qué poner ahí, y una pestaña vacía por diseño se lee como un
    // error de carga.
    final tabs = profile.isCreator;
    final posts = _PostsTab(state: state, isOwn: isOwn);
    return DefaultTabController(
      length: 3,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _ProfileHeader(profile: profile, isOwn: isOwn, canAct: canAct),
          if (tabs)
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabsHeaderDelegate(),
            ),
        ],
        body: tabs
            ? TabBarView(
                children: [
                  posts,
                  _LivesTab(lives: state.lives),
                  _PremiumTab(profile: profile, canUnlock: canAct && !isOwn),
                ],
              )
            : posts,
      ),
    );
  }
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
              Text(
                'Estás explorando como invitado. Tu acceso no se guardará al '
                'cerrar la app.',
                style: Theme.of(context).textTheme.bodySmall,
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
  const _ProfileHeader({
    required this.profile,
    required this.isOwn,
    required this.canAct,
  });

  final PublicProfile profile;
  final bool isOwn;
  final bool canAct;

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
              _CoverBackground(isCreator: profile.isCreator),
              SafeArea(
                bottom: false,
                child: _CoverToolbar(username: profile.username, isOwn: isOwn),
              ),
            ],
          ),
        ),
        const _SanctionBanner(),
        _ProfileSummary(profile: profile, isOwn: isOwn, canAct: canAct),
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
  const _CoverToolbar({required this.username, required this.isOwn});

  final String username;
  final bool isOwn;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // La flecha aparece sólo si hay algo que popear, que es exactamente el
        // caso empujado. Como raíz de la pestaña Perfil no hay a dónde volver.
        if (Navigator.of(context).canPop())
          const BackButton(color: Colors.white)
        else
          const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
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
        ),
        // Deshabilitado y no escondido: el diseño lo tiene, y un botón activo
        // que no responde se lee como una app rota (SDD 0007, F11).
        IconButton(
          tooltip: 'Compartir perfil: muy pronto',
          disabledColor: Colors.white.withValues(alpha: .45),
          onPressed: null,
          icon: const Icon(Icons.ios_share_rounded, size: 20),
        ),
        // Las opciones son de la cuenta en sesión: en un perfil ajeno ofrecían
        // Creator Studio y "Cerrar sesión", como si fuera el propio.
        if (isOwn)
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
  const _CoverBackground({required this.isCreator});

  final bool isCreator;

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
      if (isCreator)
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
                  'CREADOR',
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
  // Leídos antes de abrir la hoja: después del `await` este context puede
  // estar muerto, y resolver el cubit desde `sl` lo saltaba a escondidas.
  final authCubit = context.read<AuthCubit>();
  final auth = authCubit.state;
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
            if (user?.isCreator ?? false)
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
  await authCubit.signOut();
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.profile,
    required this.isOwn,
    required this.canAct,
  });

  final PublicProfile profile;
  final bool isOwn;
  final bool canAct;

  @override
  Widget build(BuildContext context) {
    final bio = profile.bio;
    return Stack(
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
                  Flexible(
                    child: Text(
                      profile.name,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  if (profile.isVerified) ...[
                    const SizedBox(width: AppSpacing.xxs),
                    const Icon(
                      Icons.verified_rounded,
                      key: Key('profile-verified'),
                      color: AppColors.primary,
                      size: 19,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '@${profile.username}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textOnBrandSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (bio != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  bio,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
              if (_ProfileMetrics.hasAny(profile)) ...[
                const SizedBox(height: AppSpacing.md),
                _ProfileMetrics(profile: profile),
              ],
              if (canAct && !isOwn) ...[
                const SizedBox(height: AppSpacing.md),
                _ProfileActions(profile: profile),
              ],
              if (profile.isCreator && canAct && !isOwn) ...[
                const SizedBox(height: AppSpacing.md),
                _VipCard(creatorName: profile.name),
              ],
            ],
          ),
        ),
        Positioned(
          top: -44,
          left: AppSpacing.md,
          child: _Avatar(profile: profile),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile});

  final PublicProfile profile;

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
        child: UserAvatar(name: profile.name, size: 86),
      ),
      if (profile.isVerified)
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
            child: const Icon(
              Icons.check_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
    ],
  );
}

/// Seguidores · Siguiendo · Likes, en línea y sin tarjeta.
///
/// Sólo los que se conocen (SDD 0007, F8). El servidor todavía no cuenta
/// seguidores; un número inventado en una cuenta real es peor que ninguno.
class _ProfileMetrics extends StatelessWidget {
  const _ProfileMetrics({required this.profile});

  final PublicProfile profile;

  static bool hasAny(PublicProfile profile) =>
      profile.followers != null ||
      profile.following != null ||
      profile.likes != null;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.lg,
    runSpacing: AppSpacing.xs,
    children: [
      if (profile.followers case final followers?)
        _Metric(value: compactCount(followers), label: 'Seguidores'),
      if (profile.following case final following?)
        _Metric(value: compactCount(following), label: 'Siguiendo'),
      if (profile.likes case final likes?)
        _Metric(value: compactCount(likes), label: 'Likes'),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
      ),
      const SizedBox(width: 5),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({required this.profile});

  final PublicProfile profile;

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
      if (profile.isCreator) ...[
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
      ],
      const SizedBox(width: AppSpacing.xxs),
      // Sin mensajes directos todavía. Deshabilitado, no escondido (F11).
      const IconButton.outlined(
        tooltip: 'Mensajes directos: muy pronto',
        onPressed: null,
        icon: Icon(Icons.mail_outline_rounded, size: 19),
      ),
    ],
  );
}

class _VipCard extends StatelessWidget {
  const _VipCard({required this.creatorName});

  final String creatorName;

  List<String> get _perks => [
    'Acceso a directos semanales privados & Q&A',
    'Contenido exclusivo para miembros',
    'Canal de chat privado en vivo con ${creatorName.split(' ').first}',
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
            Text(
              'Desde \$4.99/mes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

/// Las publicaciones de la cuenta, de `posts.byAuthor`. Antes era una grilla
/// fija con los títulos de Elena, igual para cualquier perfil.
class _PostsTab extends StatelessWidget {
  const _PostsTab({required this.state, required this.isOwn});

  final PublicProfileLoaded state;
  final bool isOwn;

  @override
  Widget build(BuildContext context) => ListView(
    key: const PageStorageKey('profile-posts'),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      96,
    ),
    children: [
      if (state.posts.isEmpty)
        _EmptyTab(
          icon: Icons.grid_view_rounded,
          message: isOwn
              ? 'Todavía no publicaste nada.'
              : '${state.profile.name} todavía no publicó nada.',
          actionLabel: isOwn ? 'Crear publicación' : null,
          onAction: isOwn
              ? () => unawaited(context.push(AppRoutes.create))
              : null,
        )
      else
        _PostGrid(posts: state.posts),
      if (state.hasMore)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Center(
            child: state.isLoadingMore
                ? const CircularProgressIndicator()
                : OutlinedButton(
                    key: const Key('profile-load-more'),
                    onPressed: () => unawaited(
                      context.read<PublicProfileCubit>().loadMore(),
                    ),
                    child: const Text('Ver más publicaciones'),
                  ),
          ),
        ),
    ],
  );
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
    child: Column(
      children: [
        Icon(icon, size: 36, color: AppColors.textSecondary),
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (actionLabel case final label?) ...[
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: onAction, child: Text(label)),
        ],
      ],
    ),
  );
}

/// Rejilla de dos columnas, como el diseño. `shrinkWrap` porque vive dentro de
/// otra lista: sin él no tiene altura acotada y revienta en layout.
class _PostGrid extends StatelessWidget {
  const _PostGrid({required this.posts});

  final List<Post> posts;

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
    itemCount: posts.length,
    itemBuilder: (context, index) => _GridTile(post: posts[index]),
  );
}

class _GridTile extends StatelessWidget {
  const _GridTile({required this.post});

  final Post post;

  /// Una miniatura, no la foto entera: Flutter decodifica a resolución nativa
  /// y se queda con ese bitmap, y una grilla de fotos de cámara son decenas
  /// de megas para dibujar cuadros de 180 px.
  static const _thumbnailWidth = 360;

  @override
  Widget build(BuildContext context) {
    final url = post.mediaUrl;
    return Card(
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
                if (post.media == PostMedia.image && url != null)
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    cacheWidth: _thumbnailWidth,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  )
                else if (post.media == PostMedia.video)
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      color: AppColors.primaryDeep,
                      size: 36,
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
                  post.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      size: 11,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      compactCount(post.likes),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 11,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      compactCount(post.comments),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        RelativeTime.format(post.createdAt),
                        maxLines: 1,
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
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
}

/// Los vivos de la cuenta. Antes era una tarjeta fija ("Diseñemos en vivo")
/// con un "Recordar" que sólo abría Explorar.
class _LivesTab extends StatelessWidget {
  const _LivesTab({required this.lives});

  final List<LiveSession> lives;

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
      if (lives.isEmpty)
        const _EmptyTab(
          icon: Icons.videocam_outlined,
          message: 'Sin vivos por ahora.',
        )
      else
        for (final live in lives)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _LiveTile(live: live),
          ),
    ],
  );
}

class _LiveTile extends StatelessWidget {
  const _LiveTile({required this.live});

  final LiveSession live;

  @override
  Widget build(BuildContext context) {
    final scheduledAt = live.scheduledAt;
    return Card(
      child: InkWell(
        // La sala vive en el branch de Explorar: se cambia de pestaña, no se
        // empuja una ruta de otro branch encima de esta.
        onTap: live.status.isClosed
            ? null
            : () => context.go(AppRoutes.liveRoom(live.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusBadge(
                label: live.status.label,
                color: live.status.color,
                pulse: live.status.isOnAir,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(live.title, style: Theme.of(context).textTheme.titleMedium),
              if (scheduledAt != null &&
                  live.status == LiveStatus.scheduled) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  MaterialLocalizations.of(
                    context,
                  ).formatMediumDate(scheduledAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumTab extends StatelessWidget {
  const _PremiumTab({required this.profile, required this.canUnlock});

  final PublicProfile profile;
  final bool canUnlock;

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
                    'Lo exclusivo de ${profile.name}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Lo que publica sólo para miembros aparece acá cuando te '
                    'suscribís.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (canUnlock) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () =>
                            unawaited(context.push(AppRoutes.premium)),
                        child: const Text('Desbloquear'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
