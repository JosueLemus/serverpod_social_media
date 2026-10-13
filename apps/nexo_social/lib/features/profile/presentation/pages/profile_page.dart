import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/nexo_themes.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/constants/environment.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/nexo_mascot.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/sticker.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../feed/domain/entities/post.dart';
import '../../../feed/presentation/widgets/photo_viewer.dart';
import '../../../live/domain/entities/live_session.dart';
import '../../../live/presentation/utils/live_status_ui.dart';
import '../../domain/entities/follow.dart';
import '../../domain/entities/public_profile.dart';
import '../bloc/profile_status_cubit.dart';
import '../bloc/public_profile_cubit.dart';
import '../utils/profile_notice_ui.dart';
import '../widgets/follow_list_sheet.dart';
import '../../../live/presentation/utils/live_navigation.dart';
import '../../../../core/share/share_sheet.dart';
import '../utils/profile_share_text.dart';

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
    // El perfil propio es el perfil real de la cuenta, sea creadora o no: su
    // banner, su foto y sus publicaciones. Antes una cuenta que no creaba
    // contenido veía otra pantalla, sin su grilla ni su foto; los accesos de
    // esa pantalla (consola, moderación, temas, ajustes, salir) están en el
    // menú de opciones.
    return _PublicProfileView(
      // Con otra key si cambia el nombre de usuario: el cubit del perfil se
      // crea una vez con el username, y renombrarse lo dejaba buscando una
      // cuenta que ya no existe.
      key: ValueKey(user.username),
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
    super.key,
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
      BlocProvider(create: (_) => ProfileStatusCubit(sl(), username)..load()),
    ],
    // La pantalla se muestra en dos lugares: como pestaña Perfil dentro del
    // shell, y empujada a pantalla completa cuando se abre el perfil de otra
    // persona. Lleva Scaffold propio para que el caso empujado tenga
    // superficie y botón de volver; dentro del shell la capa extra es inocua
    // porque la portada sangra igual.
    child: Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<PublicProfileCubit, PublicProfileState>(
        // Un seguir rechazado vuelve atrás solo; el aviso dice por qué.
        listenWhen: (previous, current) =>
            current is PublicProfileLoaded &&
            current.notice != null &&
            (previous is! PublicProfileLoaded ||
                previous.noticeSerial != current.noticeSerial),
        listener: (context, state) =>
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text((state as PublicProfileLoaded).notice!.message),
              ),
            ),
        builder: (context, state) => switch (state) {
          PublicProfileLoading() => const _ProfileStatusFrame(
            child: Center(child: CircularProgressIndicator()),
          ),
          PublicProfileNotFound() => _ProfileStatusFrame(
            child: AppEmptyView(
              mascot: NexoMascot.search,
              title: 'Esta cuenta no existe',
              message:
                  'Puede que haya cambiado de nombre de usuario o que ya no '
                  'esté en Nexo.',
              actionLabel: 'Descubrir creadores',
              onAction: () => context.go(AppRoutes.feed),
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
              ? const _BackGlyphButton()
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

/// Las membresías pagas no tienen backend: con el servidor real no hay pase
/// VIP ni contenido premium que mostrar, así que no se ofrecen. En el modo
/// mock se ven, y el paywall dice que el pago es simulado.
bool get _membershipsAvailable =>
    Environment.authSourceMode == AuthSourceMode.mock;

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
    final premium = tabs && _membershipsAvailable;
    final posts = _PostsTab(state: state, isOwn: isOwn);
    // Al aire ahora: el avatar lleva el foil holo, la marca de "está pasando"
    // en toda la app.
    final onAir = state.lives.any((live) => live.status.isOnAir);
    return DefaultTabController(
      length: premium ? 3 : 2,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _ProfileHeader(
            profile: profile,
            isOwn: isOwn,
            canAct: canAct,
            onAir: onAir,
          ),
          if (tabs)
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabsHeaderDelegate(
                premium: premium,
                premiumUnlocked: state.isMember,
              ),
            ),
        ],
        body: tabs
            ? TabBarView(
                children: [
                  posts,
                  _LivesTab(lives: state.lives),
                  if (premium)
                    _PremiumTab(
                      profile: profile,
                      canUnlock: canAct && !isOwn,
                      isMember: state.isMember,
                    ),
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
              // El gato saluda: un perfil vacío lo acompaña la mascota, no
              // el logo solo.
              const Enter(child: MascotIllustration(NexoMascot.wave)),
              const SizedBox(height: AppSpacing.md),
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
    required this.onAir,
  });

  final PublicProfile profile;
  final bool isOwn;
  final bool canAct;
  final bool onAir;

  static const _coverHeight = 150.0;

  @override
  Widget build(BuildContext context) {
    final cover = vinylFor(profile.username);
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: _coverHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _CoverBackground(color: cover),
                if (profile.coverUrl case final coverUrl?)
                  _CoverImage(url: coverUrl),
                // La insignia de creador va pegada sobre la portada, apenas
                // torcida, como un sticker puesto a mano.
                if (profile.isCreator)
                  Positioned(
                    right: AppSpacing.md,
                    bottom: AppSpacing.sm,
                    child: StatusBadge(
                      label: 'Creador',
                      color: cover == AppColors.vinylLime
                          ? AppColors.vinylCyan
                          : AppColors.vinylLime,
                      foreground: AppColors.ink,
                      tilt: -.06,
                    ),
                  ),
                SafeArea(
                  bottom: false,
                  child: _CoverToolbar(isOwn: isOwn, profile: profile),
                ),
              ],
            ),
          ),
          _ProfileSummary(
            profile: profile,
            isOwn: isOwn,
            canAct: canAct,
            onAir: onAir,
          ),
        ],
      ),
    );
  }
}

/// El banner propio de la cuenta, encima del vinilo: mientras carga, o si
/// falla, se sigue viendo el vinilo. Tocarlo lo abre entero en el visor.
class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Ver banner',
    child: GestureDetector(
      key: const Key('profile-cover'),
      // Opaco: mientras la imagen carga el hijo es una caja vacía, y sin esto
      // el toque atravesaba el banner.
      behavior: HitTestBehavior.opaque,
      onTap: () => unawaited(showPhotoViewer(context, url: url)),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, sync) =>
            frame == null && !sync ? const SizedBox.expand() : child,
        errorBuilder: (_, _, _) => const SizedBox.expand(),
      ),
    ),
  );
}

/// Una sanción que no se ve desde afuera no se puede demostrar. Va pegada a
/// la identidad, antes que la bio y las métricas.
///
/// Antes iba entre la portada y el resumen, y el avatar, que se monta sobre
/// esa costura, tapaba el principio del aviso.
class _SanctionBanner extends StatelessWidget {
  const _SanctionBanner();

  @override
  Widget build(BuildContext context) {
    final status = context.watch<ProfileStatusCubit>().state.status;
    if (status == AccountStatus.active) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Container(
        key: const Key('profile-sanctioned'),
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.medium,
          border: Border.all(color: AppColors.error, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: NexoIcon(
                NexoGlyph.moderation,
                size: 17,
                color: AppColors.sticker,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                status == AccountStatus.banned
                    ? 'Esta cuenta fue dada de baja por incumplir las normas.'
                    : 'Esta cuenta está suspendida por incumplir las normas.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La flecha de volver con el glifo de Nexo. La de Material es otro trazo.
class _BackGlyphButton extends StatelessWidget {
  const _BackGlyphButton({this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    color: color,
    onPressed: () => unawaited(Navigator.of(context).maybePop()),
    icon: const NexoIcon(NexoGlyph.back),
  );
}

/// La barra sobre la portada. Va en tinta: la portada es un vinilo claro, y
/// todos los vinilos llevan tinta encima.
///
/// Sin título: el `@usuario` ya está en el resumen, justo debajo, y repetirlo
/// sobre la portada tapaba la plancha.
class _CoverToolbar extends StatelessWidget {
  const _CoverToolbar({required this.isOwn, required this.profile});

  final bool isOwn;
  final PublicProfile profile;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.xxs,
      AppSpacing.xxs,
      AppSpacing.xxs,
      0,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // La flecha aparece sólo si hay algo que popear, que es exactamente el
        // caso empujado. Como raíz de la pestaña Perfil no hay a dónde volver.
        if (Navigator.of(context).canPop())
          _BackGlyphButton(color: AppColors.ink),
        const Spacer(),
        Builder(
          builder: (buttonContext) => IconButton(
            key: const Key('share-profile'),
            tooltip: 'Compartir perfil',
            // Tinta sobre la portada, igual que volver y las opciones.
            color: AppColors.ink,
            onPressed: () => unawaited(
              openShareSheet(buttonContext, text: profileShareText(profile)),
            ),
            icon: const NexoIcon(NexoGlyph.share, size: 22),
          ),
        ),
        // Las opciones son de la cuenta en sesión: en un perfil ajeno ofrecían
        // Creator Studio y "Cerrar sesión", como si fuera el propio.
        if (isOwn)
          IconButton(
            tooltip: 'Opciones del perfil',
            color: AppColors.ink,
            onPressed: () => unawaited(_showProfileActions(context)),
            icon: const NexoIcon(NexoGlyph.more),
          ),
      ],
    ),
  );
}

/// La portada: un vinilo plano del color de la cuenta, con la trama de
/// stickers chicos de la marca impresa encima.
///
/// Plano a propósito. El degradado de marca de antes era el único degradado
/// de la app que no era el foil holo, y el holo dice "al aire".
class _CoverBackground extends StatelessWidget {
  const _CoverBackground({required this.color});

  final Color color;

  /// Una tesela de la trama: posición (fracción de la tesela), glifo, tamaño
  /// y giro. Las teselas impares se espejan en vertical para que la
  /// repetición no se lea como una grilla.
  static const _tile = [
    (x: .08, y: .22, glyph: NexoGlyph.star, size: 18.0, turn: -.35),
    (x: .42, y: .62, glyph: NexoGlyph.heart, size: 22.0, turn: .28),
    (x: .74, y: .18, glyph: NexoGlyph.hashtag, size: 16.0, turn: .12),
    (x: .22, y: .82, glyph: NexoGlyph.emoji, size: 17.0, turn: -.18),
    (x: .86, y: .70, glyph: NexoGlyph.comment, size: 15.0, turn: -.4),
  ];
  static const _tileWidth = 190.0;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: color,
    child: IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tint = AppColors.ink.withValues(alpha: .14);
          final tiles = (constraints.maxWidth / _tileWidth).ceil();
          final height = constraints.maxHeight;
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              for (var t = 0; t < tiles; t++)
                for (final mark in _tile)
                  Positioned(
                    left: (t + mark.x) * _tileWidth,
                    top: (t.isOdd ? 1 - mark.y : mark.y) * (height - mark.size),
                    child: Transform.rotate(
                      angle: t.isOdd ? -mark.turn : mark.turn,
                      child: NexoIcon(
                        mark.glyph,
                        filled: true,
                        size: mark.size,
                        color: tint,
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    ),
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
                leading: const NexoIcon(NexoGlyph.studio, size: 22),
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
                leading: const NexoIcon(NexoGlyph.moderation, size: 22),
                title: const Text('Moderación'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(AppRoutes.moderation);
                },
              ),
            if (user?.isOperator ?? false)
              ListTile(
                key: const Key('profile-admin'),
                leading: const NexoIcon(NexoGlyph.console, size: 22),
                title: const Text('Consola de operador'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.go(AppRoutes.admin);
                },
              ),
            ListTile(
              key: const Key('profile-themes'),
              leading: const NexoIcon(NexoGlyph.sparkles, size: 22),
              title: const Text('Temas'),
              subtitle: Text(NexoThemes.active.name),
              onTap: () {
                Navigator.pop(sheetContext);
                unawaited(context.push(AppRoutes.themes));
              },
            ),
            ListTile(
              leading: const NexoIcon(NexoGlyph.settings, size: 22),
              title: const Text('Ajustes'),
              onTap: () {
                Navigator.pop(sheetContext);
                unawaited(context.push(AppRoutes.settings));
              },
            ),
            const Divider(),
            ListTile(
              leading: NexoIcon(
                NexoGlyph.logout,
                size: 22,
                color: AppColors.error,
              ),
              title: Text(
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
    required this.onAir,
  });

  final PublicProfile profile;
  final bool isOwn;
  final bool canAct;
  final bool onAir;

  /// El avatar es el sticker grande de la plancha.
  static const _avatarSize = 96.0;

  /// Al aire, `UserAvatar` suma el foil y su aire alrededor del sticker
  /// (2.5 + 1.5 por lado).
  static const _holoExtra = 8.0;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final bio = profile.bio;
    final extent = _avatarSize + (onAir ? _holoExtra : 0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            _avatarSize / 2 + _holoExtra / 2 + AppSpacing.sm,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.headlineMedium,
                    ),
                  ),
                  if (profile.isVerified) ...[
                    const SizedBox(width: 6),
                    NexoIcon(
                      NexoGlyph.verified,
                      key: Key('profile-verified'),
                      color: AppColors.primary,
                      size: 20,
                      semanticLabel: 'Cuenta verificada',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '@${profile.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // El rol de staff, sólo en el perfil propio: es de la
                  // sesión, no algo que se le muestre a quien visita.
                  if (isOwn) const _StaffRoleBadge(),
                ],
              ),
              const _SanctionBanner(),
              if (bio != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(bio, style: text.bodyMedium?.copyWith(height: 1.45)),
              ],
              if (profile.website case final website?) ...[
                const SizedBox(height: AppSpacing.xs),
                _WebsiteLink(url: website),
              ],
              if (_ProfileMetrics.hasAny(profile)) ...[
                const SizedBox(height: AppSpacing.md),
                _ProfileMetrics(profile: profile),
              ],
              if (canAct && !isOwn) ...[
                const SizedBox(height: AppSpacing.md),
                _ProfileActions(profile: profile),
              ],
              // Sin cuenta (un enlace compartido, o un invitado): en lugar de
              // botones que no puede usar, la forma de empezar.
              if (!canAct && !isOwn) ...[
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  key: const Key('profile-join'),
                  onPressed: () => context.go(AppRoutes.signIn),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, AppSizes.buttonHeightDense),
                  ),
                  child: Text(
                    'Únete a Nexo para seguir a ${profile.name.split(' ').first}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (isOwn) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  key: const Key('profile-edit'),
                  onPressed: () => unawaited(_edit(context)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, AppSizes.buttonHeightDense),
                  ),
                  child: const Text('Editar perfil'),
                ),
              ],
              if (profile.isCreator &&
                  canAct &&
                  !isOwn &&
                  _membershipsAvailable) ...[
                const SizedBox(height: AppSpacing.lg),
                _VipCard(
                  creatorName: profile.name,
                  creatorUsername: profile.username,
                ),
              ],
            ],
          ),
        ),
        // A caballo entre la portada y el resumen, dentro de la misma caja:
        // por eso el header no es un SliverAppBar.
        Positioned(
          top: -extent / 2,
          left: AppSpacing.md,
          child: _ProfileAvatar(
            profile: profile,
            size: _avatarSize,
            onAir: onAir,
          ),
        ),
      ],
    );
  }
}

/// "Operador" o "Moderador" en el perfil propio de una cuenta de staff. Una
/// cuenta común no lleva nada: "usuario" no le dice nada a nadie.
class _StaffRoleBadge extends StatelessWidget {
  const _StaffRoleBadge();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final role = auth is AuthAuthenticated ? auth.user.role : null;
    final label = switch (role) {
      UserRole.operator => 'Operador',
      UserRole.moderator => 'Moderador',
      _ => null,
    };
    if (label == null) return const SizedBox.shrink();
    return StatusBadge(
      key: const Key('profile-staff-role'),
      label: label.toUpperCase(),
      color: AppColors.vinylLime,
      foreground: AppColors.ink,
    );
  }
}

/// La foto del perfil. Con foto, tocarla la abre a pantalla completa; sin
/// foto, es la inicial y no hay nada que ampliar.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.profile,
    required this.size,
    required this.onAir,
  });

  final PublicProfile profile;
  final double size;
  final bool onAir;

  @override
  Widget build(BuildContext context) {
    final avatar = UserAvatar(
      name: profile.name,
      imageUrl: profile.avatarUrl,
      size: size,
      onAir: onAir,
    );
    final url = profile.avatarUrl;
    if (url == null) return avatar;
    return Semantics(
      button: true,
      label: 'Ver foto de perfil',
      child: GestureDetector(
        key: const Key('profile-avatar'),
        onTap: () => unawaited(showPhotoViewer(context, url: url)),
        child: avatar,
      ),
    );
  }
}

/// El enlace propio: se muestra sin el esquema y se abre afuera de la app.
class _WebsiteLink extends StatelessWidget {
  const _WebsiteLink({required this.url});

  final String url;

  String get _label {
    final shown = url.replaceFirst(RegExp(r'^https?://'), '');
    return shown.endsWith('/') ? shown.substring(0, shown.length - 1) : shown;
  }

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    final opened =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No pudimos abrir el enlace.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => InkWell(
    key: const Key('profile-website'),
    onTap: () => unawaited(_open(context)),
    borderRadius: AppRadii.small,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NexoIcon(NexoGlyph.link, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Abre "Editar perfil" y, si se guardó, relee el perfil: la bio y la foto
/// no viajan en la sesión, así que no alcanza con que cambie la cuenta.
Future<void> _edit(BuildContext context) async {
  final cubit = context.read<PublicProfileCubit>();
  final saved = await context.push<bool>(AppRoutes.editProfile);
  if (saved ?? false) await cubit.load();
}

/// Seguidores · Siguiendo · Likes, en línea y sin tarjeta.
///
/// Sólo los que se conocen (SDD 0007, F8). El servidor todavía no cuenta
/// seguidores; un número inventado en una cuenta real es peor que ninguno.
class _ProfileMetrics extends StatelessWidget {
  const _ProfileMetrics({required this.profile});

  final PublicProfile profile;

  static bool hasAny(PublicProfile profile) =>
      profile.posts != null ||
      profile.followers != null ||
      profile.following != null ||
      profile.likes != null;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.lg,
    runSpacing: AppSpacing.xs,
    children: [
      if (profile.posts case final posts?)
        _Metric(
          key: const Key('profile-posts'),
          value: compactCount(posts),
          label: posts == 1 ? 'Publicación' : 'Publicaciones',
        ),
      if (profile.followers case final followers?)
        _Metric(
          key: const Key('profile-followers'),
          value: compactCount(followers),
          label: 'Seguidores',
          onTap: () => unawaited(
            showFollowListSheet(
              context,
              userId: profile.id,
              kind: FollowListKind.followers,
            ),
          ),
        ),
      if (profile.following case final following?)
        _Metric(
          key: const Key('profile-following'),
          value: compactCount(following),
          label: 'Siguiendo',
          onTap: () => unawaited(
            showFollowListSheet(
              context,
              userId: profile.id,
              kind: FollowListKind.following,
            ),
          ),
        ),
      if (profile.likes case final likes?)
        _Metric(value: compactCount(likes), label: 'Likes'),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    super.key,
    required this.value,
    required this.label,
    this.onTap,
  });

  final String value;
  final String label;

  /// Seguidores y seguidos abren la lista; los likes no tienen a dónde ir.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // El número en la letra display, con cifras tabulares: al seguir, el
    // contador cambia en el lugar sin que la fila baile.
    final metric = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: text.titleLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: text.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
    final tap = onTap;
    if (tap == null) return metric;
    return InkWell(onTap: tap, borderRadius: AppRadii.small, child: metric);
  }
}

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({required this.profile});

  final PublicProfile profile;

  static const _dense = Size(0, AppSizes.buttonHeightDense);
  static const _densePadding = EdgeInsets.symmetric(horizontal: AppSpacing.sm);

  @override
  Widget build(BuildContext context) {
    void toggle() =>
        unawaited(context.read<PublicProfileCubit>().toggleFollow());
    return Row(
      children: [
        // Seguir es el sticker blanco; ya seguida, queda el contorno: la
        // acción hecha pasa a segundo plano.
        Expanded(
          child: profile.viewerFollows
              ? OutlinedButton(
                  key: const Key('profile-follow'),
                  onPressed: toggle,
                  style: OutlinedButton.styleFrom(
                    minimumSize: _dense,
                    padding: _densePadding,
                  ),
                  child: const _ButtonLabel('Siguiendo'),
                )
              : FilledButton(
                  key: const Key('profile-follow'),
                  onPressed: toggle,
                  style: FilledButton.styleFrom(
                    minimumSize: _dense,
                    padding: _densePadding,
                  ),
                  child: const _ButtonLabel('Seguir'),
                ),
        ),
        if (profile.isCreator) ...[
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: OutlinedButton(
              onPressed: () => unawaited(
                context.push(AppRoutes.premiumFor(profile.username)),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: _dense,
                padding: _densePadding,
              ),
              child: const _ButtonLabel('Suscribirse'),
            ),
          ),
        ],
        const SizedBox(width: AppSpacing.xs),
        // Mensajes directos (SDD 0010): abre el chat con esta cuenta, y lo
        // crea si todavía no existía. Con `go` y no `push`: el chat vive en la
        // pestaña Mensajes, y empujarlo desde acá lo dejaría en el Navigator
        // equivocado. Así queda la bandeja debajo y el back vuelve a ella.
        IconButton.outlined(
          key: const Key('profile-message'),
          tooltip: 'Enviar mensaje',
          onPressed: () => context.go(AppRoutes.conversationWith(profile.id)),
          icon: const NexoIcon(NexoGlyph.send, size: 20),
        ),
      ],
    );
  }
}

/// La etiqueta de un botón que comparte la fila con otros. A 320 de ancho
/// dos botones y el de mensajes dejan ~116 px a cada uno: la etiqueta se
/// achica apenas en vez de partirse en dos renglones o recortarse.
class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1));
}

class _VipCard extends StatelessWidget {
  const _VipCard({required this.creatorName, required this.creatorUsername});

  final String creatorName;

  /// El dueño del pase: el muro que abre "Unirme" es el suyo.
  final String creatorUsername;

  List<String> get _perks => [
    'Acceso a directos semanales privados & Q&A',
    'Contenido exclusivo para miembros',
    'Canal de chat privado en vivo con ${creatorName.split(' ').first}',
  ];

  /// Cuánto asoma la insignia por encima del borde de la tarjeta.
  static const _badgeOverhang = 10.0;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: _badgeOverhang),
        // El pase es un objeto: el sticker del logo, con el contenido en
        // tinta.
        child: StickerCard(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: _VipBody(perks: _perks, creatorUsername: creatorUsername),
        ),
      ),
      // Pegada sobre el borde, apenas torcida.
      Positioned(
        top: 0,
        right: AppSpacing.md,
        child: StatusBadge(
          label: 'VIP',
          color: AppColors.vinylLime,
          foreground: AppColors.ink,
          tilt: .05,
        ),
      ),
    ],
  );
}

/// El contenido del pase. Un widget aparte para leer el tema **dentro** de
/// la [StickerCard], que lo invierte a tinta: leído desde afuera, el texto
/// saldría claro sobre blanco.
class _VipBody extends StatelessWidget {
  const _VipBody({required this.perks, required this.creatorUsername});

  final List<String> perks;
  final String creatorUsername;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pase Creador VIP', style: text.titleLarge),
        const SizedBox(height: 2),
        Text(
          'Desde \$4.99/mes',
          style: text.bodySmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final perk in perks)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: NexoIcon(
                    NexoGlyph.star,
                    size: 15,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(perk, style: text.bodyMedium)),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        // Dentro de la tarjeta el CTA del tema es relleno de tinta; la corona
        // va en lima, el vinilo de las membresías.
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('profile-join-vip'),
            onPressed: () =>
                unawaited(context.push(AppRoutes.premiumFor(creatorUsername))),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, AppSizes.buttonHeightDense),
            ),
            icon: NexoIcon(
              NexoGlyph.crown,
              filled: true,
              size: 18,
              color: AppColors.vinylLime,
            ),
            label: const Text('Unirme por \$4.99'),
          ),
        ),
      ],
    );
  }
}

class _TabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TabsHeaderDelegate({required this.premium, required this.premiumUnlocked});

  /// Sin membresías reales, la pestaña Premium no existe (ver
  /// [_membershipsAvailable]).
  final bool premium;

  /// Con la membresía activa la pestaña pierde el candado.
  final bool premiumUnlocked;

  @override
  double get minExtent => kTextTabBarHeight;

  @override
  double get maxExtent => kTextTabBarHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Material(
    color: AppColors.background,
    // Desplazable y alineada al inicio: con tres pestañas de ancho fijo, a
    // 320 "Publicaciones" se recortaba a "Publicacione". Así cada etiqueta
    // mide lo que mide.
    child: TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      tabs: [
        const Tab(text: 'Publicaciones'),
        const Tab(text: 'En vivos'),
        // El candado dice que la pestaña existe y está cerrada. Esconderla
        // haría que el pase VIP prometa algo sin lugar donde verse.
        if (premium)
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Premium'),
                const SizedBox(width: 6),
                NexoIcon(
                  premiumUnlocked ? NexoGlyph.crown : NexoGlyph.lock,
                  size: 14,
                ),
              ],
            ),
          ),
      ],
    ),
  );

  @override
  bool shouldRebuild(covariant _TabsHeaderDelegate oldDelegate) =>
      oldDelegate.premium != premium ||
      oldDelegate.premiumUnlocked != premiumUnlocked;
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
          mascot: NexoMascot.empty,
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

/// Una pestaña vacía: el gato y qué falta.
class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.mascot,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final NexoMascot mascot;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
    child: Column(
      children: [
        MascotIllustration(mascot, size: 128),
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
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
      // Lo justo para que el sticker de media quede casi cuadrado con el
      // texto debajo.
      childAspectRatio: .72,
    ),
    itemCount: posts.length,
    itemBuilder: (context, index) => _GridTile(post: posts[index]),
  );
}

class _GridTile extends StatelessWidget {
  const _GridTile({required this.post});

  final Post post;

  static const _captionLineHeight = 1.25;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final caption = text.bodySmall?.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
      height: _captionLineHeight,
    );
    final count = text.labelSmall?.copyWith(
      color: AppColors.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // Dos renglones siempre, aunque el texto ocupe uno: si no, el sticker de
    // arriba crece y la fila de la grilla queda con dos alturas.
    final captionHeight =
        MediaQuery.textScalerOf(context).scale(caption?.fontSize ?? 12.5) *
            _captionLineHeight *
            2 +
        1;
    // Tocar la celda abre la publicación entera: antes no hacía nada, y una
    // grilla de fotos que no se abre se lee como una app rota.
    return InkWell(
      key: Key('profile-post-${post.id}'),
      onTap: () => unawaited(context.push(AppRoutes.post(post.id))),
      borderRadius: AppRadii.medium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // La media es un sticker troquelado, sobre el liner.
          Expanded(
            child: StickerFrame(
              radius: 14,
              fill: AppColors.linerHigh,
              child: _TileMedia(post: post),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: captionHeight,
            child: Text(
              post.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: caption,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              NexoIcon(
                NexoGlyph.heart,
                filled: true,
                size: 13,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 3),
              Text(compactCount(post.likes), style: count),
              const SizedBox(width: AppSpacing.xs),
              NexoIcon(
                NexoGlyph.comment,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 3),
              Text(compactCount(post.comments), style: count),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  RelativeTime.format(post.createdAt),
                  maxLines: 1,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lo que va dentro del sticker de una publicación.
///
/// Sin degradados: la foto si la hay; si no, el `linerHigh` del sticker con
/// el glifo de lo que falta. Una publicación de sólo texto se imprime como un
/// vinilo plano con su primera etiqueta, para que la plancha no sea una fila
/// de cuadros grises.
class _TileMedia extends StatelessWidget {
  const _TileMedia({required this.post});

  final Post post;

  /// Una miniatura, no la foto entera: Flutter decodifica a resolución nativa
  /// y se queda con ese bitmap, y una grilla de fotos de cámara son decenas
  /// de megas para dibujar cuadros de 180 px.
  static const _thumbnailWidth = 360;

  @override
  Widget build(BuildContext context) {
    final url = post.mediaUrl;
    final missing = Center(
      child: NexoIcon(NexoGlyph.media, size: 30, color: AppColors.textTertiary),
    );
    switch (post.media) {
      case PostMedia.image when url != null:
        return Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: _thumbnailWidth,
          errorBuilder: (_, _, _) => missing,
        );
      case PostMedia.image:
        return missing;
      case PostMedia.video:
        return Center(
          child: NexoIcon(
            NexoGlyph.play,
            filled: true,
            size: 34,
            color: AppColors.textSecondary,
          ),
        );
      case null:
        final tag = post.tags.firstOrNull;
        if (tag == null) {
          return Center(
            child: NexoIcon(
              NexoGlyph.comment,
              size: 30,
              color: AppColors.textTertiary,
            ),
          );
        }
        return ColoredBox(
          color: vinylFor(tag),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(
                '#$tag',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.ink),
              ),
            ),
          ),
        );
    }
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
        const _EmptyTab(mascot: NexoMascot.mic, message: 'Sin vivos por ahora.')
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

  /// Cuánto asoma la insignia por encima del borde del sticker.
  static const _badgeOverhang = 10.0;

  /// El borde dice el estado, con el vocabulario de toda la app: holo al
  /// aire, punteado programado, troquel el replay y el dorso lo cerrado.
  StickerEdge get _edge => switch (live.status) {
    LiveStatus.live || LiveStatus.ending => StickerEdge.holo,
    LiveStatus.scheduled || LiveStatus.draft => StickerEdge.dashed,
    LiveStatus.recorded || LiveStatus.published => StickerEdge.kissCut,
    LiveStatus.cancelled ||
    LiveStatus.failed ||
    LiveStatus.removed => StickerEdge.none,
  };

  NexoGlyph get _glyph => switch (live.status) {
    LiveStatus.scheduled || LiveStatus.draft => NexoGlyph.calendar,
    LiveStatus.recorded || LiveStatus.published => NexoGlyph.play,
    _ => NexoGlyph.live,
  };

  /// El color de en vivo sólo para lo que está al aire; el resto, vinilo con
  /// tinta o el gris de lo que ya no está.
  (Color, Color) get _badge => switch (live.status) {
    LiveStatus.live ||
    LiveStatus.ending => (AppColors.secondary, AppColors.onSecondary),
    LiveStatus.scheduled => (AppColors.vinylCyan, AppColors.ink),
    LiveStatus.recorded ||
    LiveStatus.published => (AppColors.tertiary, AppColors.ink),
    _ => (AppColors.linerHigh, AppColors.textSecondary),
  };

  @override
  Widget build(BuildContext context) {
    final scheduledAt = live.scheduledAt;
    final status = live.status;
    final text = Theme.of(context).textTheme;
    final (badgeColor, badgeForeground) = _badge;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: _badgeOverhang),
          child: StickerFrame(
            edge: _edge,
            fill: status.isClosed ? AppColors.linerHigh : AppColors.surface,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                // La sala vive en el branch de Explorar: se cambia de pestaña, no se
                // empuja una ruta de otro branch encima de esta.
                onTap: live.status.isClosed
                    ? null
                    : () => openLive(context, live),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: status.isOnAir
                              ? AppColors.secondary
                              : status.isClosed
                              ? AppColors.surface
                              : AppColors.linerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: NexoIcon(
                          _glyph,
                          filled: status.isOnAir,
                          size: 20,
                          color: status.isOnAir
                              ? AppColors.sticker
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              live.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleMedium?.copyWith(
                                color: status.isClosed
                                    ? AppColors.textSecondary
                                    : null,
                              ),
                            ),
                            if (scheduledAt != null &&
                                status == LiveStatus.scheduled) ...[
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                MaterialLocalizations.of(
                                  context,
                                ).formatMediumDate(scheduledAt),
                                style: text.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // El estado pegado sobre la esquina, apenas torcido.
        Positioned(
          top: 0,
          left: AppSpacing.md,
          child: StatusBadge(
            label: status.label,
            color: badgeColor,
            foreground: badgeForeground,
            pulse: status.isOnAir,
            tilt: -.05,
          ),
        ),
      ],
    );
  }
}

class _PremiumTab extends StatelessWidget {
  const _PremiumTab({
    required this.profile,
    required this.canUnlock,
    required this.isMember,
  });

  final PublicProfile profile;
  final bool canUnlock;

  /// Con la membresía activa la pestaña se abre: seguir mostrando el candado
  /// a quien ya pagó se lee como que el pago no anduvo.
  final bool isMember;

  @override
  Widget build(BuildContext context) =>
      isMember ? _memberView(context) : _lockedView(context);

  Widget _memberView(BuildContext context) => ListView(
    key: const PageStorageKey('profile-premium'),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      96,
    ),
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          children: [
            const MascotIllustration(NexoMascot.crown, size: 128),
            const SizedBox(height: AppSpacing.sm),
            StatusBadge(
              key: const Key('profile-premium-unlocked'),
              label: 'Desbloqueado',
              color: AppColors.tertiary,
              foreground: AppColors.ink,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Eres miembro de ${profile.name}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                'Lo que publique sólo para miembros aparece acá apenas lo '
                'comparta.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => unawaited(
                context.push(AppRoutes.premiumFor(profile.username)),
              ),
              icon: const NexoIcon(NexoGlyph.crown, size: 18),
              label: const Text('Ver mi membresía'),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _lockedView(BuildContext context) => ListView(
    key: const PageStorageKey('profile-premium'),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      96,
    ),
    children: [
      // Cerrado, no escondido: el gato del candado dice que hay algo y que
      // se abre con la membresía.
      Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          children: [
            const MascotIllustration(NexoMascot.lock, size: 128),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Lo exclusivo de ${profile.name}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                'Lo que publica sólo para miembros aparece acá cuando te '
                'suscribís.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (canUnlock) ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => unawaited(
                  context.push(AppRoutes.premiumFor(profile.username)),
                ),
                icon: const NexoIcon(NexoGlyph.lock, filled: true, size: 18),
                label: const Text('Desbloquear'),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}
