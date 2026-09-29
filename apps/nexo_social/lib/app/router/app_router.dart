import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/app_shell.dart';
import '../../core/widgets/placeholder_page.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/auth/presentation/pages/auth_pages.dart';
import '../../features/auth/presentation/pages/suspended_page.dart';
import '../../features/admin/presentation/pages/account_detail_page.dart';
import '../../features/admin/presentation/pages/admin_console_page.dart';
import '../../features/feed/presentation/pages/feed_page.dart';
import '../../features/explore/presentation/pages/explore_page.dart';
import '../../features/live/presentation/pages/creator_studio_page.dart';
import '../../features/live/presentation/pages/live_room_page.dart';
import '../../features/moderation/presentation/pages/moderation_page.dart';
import '../../features/notifications/presentation/pages/activity_page.dart';
import '../../features/posts/presentation/pages/create_post_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/subscriptions/presentation/pages/subscription_page.dart';
import 'app_routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Builds the router around a session.
///
/// A function rather than a top-level `final` so tests can build a router over
/// a seeded [AuthCubit] and assert the guards. A global would bind to whatever
/// the previous test left in the service locator.
GoRouter createRouter(AuthCubit auth, {String? initialLocation}) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: initialLocation ?? AppRoutes.splash,
  refreshListenable: _CubitRefresh(auth.stream),
  redirect: (context, state) => _guard(
    auth.state,
    state.matchedLocation,
    from: state.uri.queryParameters[_fromParameter],
  ),
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.signIn,
      builder: (context, state) => const SignInPage(),
    ),
    GoRoute(
      path: AppRoutes.signUp,
      builder: (context, state) => const SignUpPage(),
    ),
    GoRoute(
      path: AppRoutes.passwordReset,
      builder: (context, state) => const PasswordResetPage(),
    ),
    GoRoute(
      path: AppRoutes.suspended,
      builder: (context, state) => const SuspendedPage(),
    ),

    // Full-screen routes that sit *over* the shell. They use the root
    // navigator so the bottom bar and rail are covered: composing a post or
    // reading a paywall is a task, and leaving the tab bar visible invites the
    // user to abandon it half-finished.
    GoRoute(
      path: AppRoutes.create,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const CreatePostPage(),
    ),
    GoRoute(
      path: AppRoutes.premium,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SubscriptionPage(),
    ),
    GoRoute(
      path: AppRoutes.userProfilePath,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) =>
          ProfilePage(username: state.pathParameters['username']),
    ),
    GoRoute(
      path: AppRoutes.settings,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const PlaceholderPage(
        title: 'Ajustes',
        description: 'Personaliza tu experiencia en Nexo.',
        icon: Icons.settings_outlined,
      ),
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.feed,
              builder: (context, state) => const FeedPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.explore,
              builder: (context, state) => const ExplorePage(),
              routes: [
                // La sala vive dentro del branch de Explorar: se entra a un
                // vivo desde el descubrimiento, y ponerla en otro branch sería
                // el empuje entre branches que deja la página en un Navigator
                // que no está en pantalla.
                GoRoute(
                  path: AppRoutes.liveRoomSegment,
                  builder: (context, state) => LiveRoomPage(
                    liveId: state.pathParameters['liveId'] ?? 'preview',
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.activity,
              builder: (context, state) => const ActivityPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              // No username: this branch is "me". The tab used to point at a
              // hardcoded `/profile/nexo`, so it opened a stranger's profile
              // for every account.
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.studio,
              builder: (context, state) => const CreatorStudioPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.moderation,
              builder: (context, state) => const ModerationPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.admin,
              builder: (context, state) => const AdminConsolePage(),
              routes: [
                GoRoute(
                  path: AppRoutes.adminAccountSegment,
                  builder: (context, state) => AccountDetailPage(
                    accountId: state.pathParameters['accountId'] ?? '',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

/// The single place that decides who may see what.
///
/// Pure and top-level so `router_guard_test.dart` can drive it with a state
/// and a location and assert the answer, without pumping a widget tree.
@visibleForTesting
String? guardRedirect(AuthState auth, String location, {String? from}) =>
    _guard(auth, location, from: from);

/// A dónde iba la persona antes de que el splash la retuviera.
const _fromParameter = 'from';

String? _guard(AuthState auth, String location, {String? from}) {
  // The session has not been read from storage yet. Anything but the splash
  // would flash a signed-out screen and then replace it a frame later.
  //
  // El splash recuerda a dónde se iba. Sin eso, escribir una URL —o
  // recargar la pestaña— terminaba siempre en el feed: la sesión todavía no
  // estaba leída, el splash retenía la navegación y al resolverse mandaba al
  // inicio. Entrar a `/admin` a mano "no cambiaba nada" para nadie, ni
  // siquiera para el operador.
  if (auth is AuthLoading) {
    if (location == AppRoutes.splash) return null;
    return Uri(
      path: AppRoutes.splash,
      queryParameters: {_fromParameter: location},
    ).toString();
  }

  // Una sesión revocada por sanción tiene un solo lugar a donde ir, y ese
  // lugar no existe para nadie más. Antes que el splash: resolverlo primero
  // mandaría al login, y del login de vuelta acá — dos saltos.
  if (auth is AuthSuspended) {
    return location == AppRoutes.suspended ? null : AppRoutes.suspended;
  }

  final isPublic = AppRoutes.publicOnly.contains(location);

  // The splash is never a destination, in either direction — it is the
  // loading state that just finished. Treating it as just another public
  // route let a signed-out user sit on it forever: `publicOnly` contains it,
  // so the guard answered "you may stay" and the app never left the logo.
  final resolvedSplash = auth is AuthAuthenticated
      ? AppRoutes.feed
      : AppRoutes.signIn;
  if (location == AppRoutes.splash) {
    // Con sesión, se retoma el destino pedido. Esa ruta pasa por el guard
    // igual que cualquier otra, así que un usuario que pidió `/admin` sigue
    // terminando en el feed: recordar el destino no salta ningún permiso.
    final resumes =
        auth is AuthAuthenticated &&
        from != null &&
        from.startsWith('/') &&
        from != AppRoutes.splash &&
        !AppRoutes.publicOnly.contains(from);
    return resumes ? from : resolvedSplash;
  }

  if (location == AppRoutes.suspended) return resolvedSplash;

  if (auth is! AuthAuthenticated) {
    return isPublic ? null : AppRoutes.signIn;
  }

  // A visitor is signed in only in the sense that a guest session exists. They
  // browse; they do not publish, earn or moderate.
  final isVisitor = auth.user.role == UserRole.visitor;

  // A real account has no reason to sit on sign-in. A visitor does: that page
  // is how they upgrade, so sending them away would make the wall unreachable
  // and bounce them between /sign-in and / forever.
  if (isPublic) return isVisitor ? null : AppRoutes.feed;

  if (isVisitor && _isUnder(AppRoutes.authenticatedOnly, location)) {
    return AppRoutes.signIn;
  }

  // Por rol. Al feed y no al login: la cuenta es real, sólo no tiene el
  // permiso, y mandarla a iniciar sesión otra vez no le da ninguno.
  final user = auth.user;
  if (!user.canModerate && _isUnder(AppRoutes.moderatorOnly, location)) {
    return AppRoutes.feed;
  }
  if (!user.isOperator && _isUnder(AppRoutes.operatorOnly, location)) {
    return AppRoutes.feed;
  }

  return null;
}

/// Segment-aware so `/premium` matches `/premium/plan` but `/` never matches
/// everything — a bare `startsWith` against the feed route would gate the
/// entire app, since every path starts with a slash.
bool _isUnder(Set<String> routes, String location) =>
    routes.any((gated) => location == gated || location.startsWith('$gated/'));

/// Bridges a bloc stream to the [Listenable] `refreshListenable` wants, so the
/// redirect re-runs the moment the session changes instead of on the next
/// navigation.
class _CubitRefresh extends ChangeNotifier {
  _CubitRefresh(Stream<AuthState> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
