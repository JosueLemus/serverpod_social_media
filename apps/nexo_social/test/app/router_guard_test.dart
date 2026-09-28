import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/router/app_router.dart';
import 'package:nexo_social/app/router/app_routes.dart';
import 'package:nexo_social/features/auth/domain/entities/app_user.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';

/// The access rules, exercised as a pure function.
///
/// `guardRedirect` is exposed for exactly this: a guard spread across a
/// redirect, a listener and an initState is three rules that contradict each
/// other, and asserting it through a pumped widget tree would test the
/// Navigator instead of the rule.
void main() {
  const loading = AuthLoading();
  const signedOut = AuthUnauthenticated();

  const creator = AuthAuthenticated(
    AppUser(
      id: 'creator-1',
      username: 'elena_ux',
      name: 'Elena Vega',
      role: UserRole.user,
      isCreator: true,
      verification: VerificationStatus.verified,
    ),
  );
  const moderator = AuthAuthenticated(
    AppUser(
      id: 'mod-1',
      username: 'mod_lucia',
      name: 'Lucía Moderadora',
      role: UserRole.moderator,
    ),
  );
  const operator = AuthAuthenticated(
    AppUser(
      id: 'op-1',
      username: 'nexo_ops',
      name: 'Operaciones Nexo',
      role: UserRole.operator,
    ),
  );
  const suspended = AuthSuspended(status: AccountStatus.suspended);
  const visitor = AuthAuthenticated(
    AppUser(
      id: 'guest',
      username: 'invitado',
      name: 'Invitado',
      role: UserRole.visitor,
    ),
  );

  group('while the session is still being read', () {
    test('every location is held at the splash', () {
      for (final location in [
        AppRoutes.feed,
        AppRoutes.explore,
        AppRoutes.signIn,
      ]) {
        expect(
          Uri.parse(guardRedirect(loading, location)!).path,
          AppRoutes.splash,
        );
      }
    });

    // Regresión: escribir `/admin` en la barra —o recargar la pestaña—
    // terminaba siempre en el feed, porque el splash no recordaba a dónde se
    // iba. Para el operador, entrar a la consola por URL "no hacía nada".
    test('the splash remembers where the user was going', () {
      final held = Uri.parse(guardRedirect(loading, AppRoutes.admin)!);
      expect(held.queryParameters['from'], AppRoutes.admin);

      expect(
        guardRedirect(operator, AppRoutes.splash, from: AppRoutes.admin),
        AppRoutes.admin,
      );
    });

    test('resuming the destination does not skip the guard', () {
      final resumed = guardRedirect(
        creator,
        AppRoutes.splash,
        from: AppRoutes.admin,
      );
      expect(resumed, AppRoutes.admin);
      expect(guardRedirect(creator, resumed!), AppRoutes.feed);
    });

    test('only in-app paths are resumed', () {
      expect(
        guardRedirect(operator, AppRoutes.splash, from: 'https://evil.test'),
        AppRoutes.feed,
      );
      expect(
        guardRedirect(signedOut, AppRoutes.splash, from: AppRoutes.admin),
        AppRoutes.signIn,
      );
    });

    test('the splash itself is allowed, or the redirect would loop', () {
      expect(guardRedirect(loading, AppRoutes.splash), isNull);
    });
  });

  group('the splash is never a destination', () {
    // Regression: the splash was listed in `publicOnly`, so a signed-out user
    // sitting on it got "you may stay" and the app never left the logo.
    test('a signed-out user is sent to sign-in, not left there', () {
      expect(guardRedirect(signedOut, AppRoutes.splash), AppRoutes.signIn);
    });

    test('a signed-in user is sent into the app', () {
      expect(guardRedirect(creator, AppRoutes.splash), AppRoutes.feed);
      expect(guardRedirect(visitor, AppRoutes.splash), AppRoutes.feed);
    });
  });

  group('signed out', () {
    test('any app route bounces to sign-in', () {
      for (final location in [
        AppRoutes.feed,
        AppRoutes.explore,
        AppRoutes.activity,
        AppRoutes.profile,
        AppRoutes.create,
        AppRoutes.studio,
      ]) {
        expect(
          guardRedirect(signedOut, location),
          AppRoutes.signIn,
          reason: '$location should require a session',
        );
      }
    });

    test('the public flow is reachable', () {
      expect(guardRedirect(signedOut, AppRoutes.signIn), isNull);
      expect(guardRedirect(signedOut, AppRoutes.signUp), isNull);
    });
  });

  group('visitor (guest session)', () {
    test('browsing is public', () {
      expect(guardRedirect(visitor, AppRoutes.feed), isNull);
      expect(guardRedirect(visitor, AppRoutes.explore), isNull);
      expect(guardRedirect(visitor, AppRoutes.activity), isNull);
      expect(guardRedirect(visitor, AppRoutes.profile), isNull);
    });

    test('writing, earning and moderating are not', () {
      for (final location in AppRoutes.authenticatedOnly) {
        expect(
          guardRedirect(visitor, location),
          AppRoutes.signIn,
          reason: '$location should be gated for a visitor',
        );
      }
    });

    test('a sub-route of a gated route is gated too', () {
      expect(
        guardRedirect(visitor, '${AppRoutes.premium}/anual'),
        AppRoutes.signIn,
      );
    });

    // Regression: a bare `startsWith` match would gate every path, because
    // every path starts with the feed's '/'.
    test('gating by segment does not swallow the whole app', () {
      expect(guardRedirect(visitor, AppRoutes.feed), isNull);
      expect(guardRedirect(visitor, '/u/elena_ux'), isNull);
    });

    // Regression: sending a visitor away from sign-in bounces them between
    // /sign-in and / forever, and the upgrade path becomes unreachable.
    test('may stay on sign-in, because that is how they upgrade', () {
      expect(guardRedirect(visitor, AppRoutes.signIn), isNull);
      expect(guardRedirect(visitor, AppRoutes.signUp), isNull);
    });
  });

  group('authenticated creator', () {
    test('has no reason to sit on the public flow', () {
      expect(guardRedirect(creator, AppRoutes.signIn), AppRoutes.feed);
      expect(guardRedirect(creator, AppRoutes.signUp), AppRoutes.feed);
    });

    test('reaches every route that needs no scope', () {
      for (final location in [
        AppRoutes.feed,
        AppRoutes.create,
        AppRoutes.studio,
        AppRoutes.premium,
        AppRoutes.settings,
      ]) {
        expect(
          guardRedirect(creator, location),
          isNull,
          reason: '$location should be open to a creator',
        );
      }
    });

    // Regresión: `/moderation` sólo se le cerraba al invitado, así que
    // cualquier cuenta logueada entraba a la cola de reportes.
    test('does not reach moderation nor the operator console', () {
      expect(guardRedirect(creator, AppRoutes.moderation), AppRoutes.feed);
      expect(guardRedirect(creator, AppRoutes.admin), AppRoutes.feed);
      expect(
        guardRedirect(creator, AppRoutes.adminAccount('user-troll')),
        AppRoutes.feed,
        reason: 'una sub-ruta de la consola también está cerrada',
      );
    });
  });

  group('moderator', () {
    test('reaches the moderation queue', () {
      expect(guardRedirect(moderator, AppRoutes.moderation), isNull);
    });

    test('does not reach the operator console', () {
      expect(guardRedirect(moderator, AppRoutes.admin), AppRoutes.feed);
    });
  });

  group('operator', () {
    test('reaches the console, its sub-routes and moderation', () {
      expect(guardRedirect(operator, AppRoutes.admin), isNull);
      expect(
        guardRedirect(operator, AppRoutes.adminAccount('user-troll')),
        isNull,
      );
      expect(guardRedirect(operator, AppRoutes.moderation), isNull);
    });
  });

  group('suspended session', () {
    test('every location is held at the suspended screen', () {
      for (final location in [
        AppRoutes.feed,
        AppRoutes.signIn,
        AppRoutes.admin,
        AppRoutes.splash,
      ]) {
        expect(guardRedirect(suspended, location), AppRoutes.suspended);
      }
      expect(guardRedirect(suspended, AppRoutes.suspended), isNull);
    });

    test('nobody else can sit on the suspended screen', () {
      expect(guardRedirect(creator, AppRoutes.suspended), AppRoutes.feed);
      expect(guardRedirect(signedOut, AppRoutes.suspended), AppRoutes.signIn);
    });
  });

  group('the guard always terminates', () {
    // A redirect that answers with a location whose own answer is another
    // location loops until go_router throws. Following each answer once and
    // requiring the second hop to be null proves there is no two-step cycle.
    test('no location redirects to another location that redirects', () {
      const locations = [
        AppRoutes.splash,
        AppRoutes.signIn,
        AppRoutes.signUp,
        AppRoutes.feed,
        AppRoutes.explore,
        AppRoutes.activity,
        AppRoutes.profile,
        AppRoutes.create,
        AppRoutes.studio,
        AppRoutes.moderation,
        AppRoutes.admin,
        AppRoutes.suspended,
        AppRoutes.premium,
        AppRoutes.settings,
      ];

      for (final auth in [
        loading,
        signedOut,
        visitor,
        creator,
        moderator,
        operator,
        suspended,
      ]) {
        for (final location in locations) {
          final first = guardRedirect(auth, location);
          if (first == null) continue;
          // go_router matches on the path; the query travels separately.
          final hop = Uri.parse(first);
          expect(
            guardRedirect(auth, hop.path, from: hop.queryParameters['from']),
            isNull,
            reason:
                '$auth at $location redirects to $first, which redirects again',
          );
        }
      }
    });
  });
}
