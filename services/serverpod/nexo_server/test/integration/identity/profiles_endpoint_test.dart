import 'package:nexo_server/src/generated/protocol.dart';
import 'package:nexo_server/src/shared/auth/auth_context.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';
import '../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Profiles endpoint', (sessionBuilder, endpoints) {
    final fixtures = Fixtures(sessionBuilder);

    /// Una cuenta como la deja el registro por correo: con email y sin nombre
    /// de usuario.
    Future<UuidValue> registered(String email) async {
      final user = await AuthUser.db.insertRow(
        fixtures.session,
        AuthUser(scopeNames: {}),
      );
      await UserProfile.db.insertRow(
        fixtures.session,
        // El proveedor de correo lo guarda en minúsculas.
        UserProfile(authUserId: user.id!, email: email.toLowerCase()),
      );
      return user.id!;
    }

    group('when a freshly registered account asks for itself', () {
      test('then it gets a username derived from its email', () async {
        final id = await registered('María.José@example.com');

        final me = await endpoints.profiles.me(fixtures.signedIn(id));

        expect(me.profile.username, 'maria_jose');
        expect(me.profile.displayName, 'maria_jose');
        expect(me.profile.isCreator, isFalse);
        expect(me.profile.verification, VerificationStatus.none);
        expect(me.profile.status, AccountStatus.active);
        expect(me.email, 'maría.josé@example.com');
      });

      test('then a taken username gets a free suffix', () async {
        final first = await registered('elena@example.com');
        final second = await registered('elena@otro.com');

        await endpoints.profiles.me(fixtures.signedIn(first));
        final me = await endpoints.profiles.me(fixtures.signedIn(second));

        expect(me.profile.username, 'elena_1');
      });

      test('then the username is copied to the Serverpod profile', () async {
        final id = await registered('tomas@example.com');
        await endpoints.profiles.me(fixtures.signedIn(id));

        final user = await UserProfile.db.findFirstRow(
          fixtures.session,
          where: (t) => t.authUserId.equals(id),
        );
        expect(user!.userName, 'tomas');
      });

      test('then asking twice creates one profile', () async {
        final id = await registered('ana@example.com');
        final session = fixtures.signedIn(id);

        await endpoints.profiles.me(session);
        await endpoints.profiles.me(session);

        expect(
          await AccountProfile.db.count(
            fixtures.session,
            where: (t) => t.authUserId.equals(id),
          ),
          1,
        );
      });
    });

    test('roles come from the scopes, never from the client', () async {
      final id = await registered('ops@example.com');

      final me = await endpoints.profiles.me(
        fixtures.signedIn(id, {NexoScopes.admin}),
      );

      expect(me.isAdmin, isTrue);
      expect(me.isModerator, isFalse);
    });

    test('a guest cannot ask for its account', () async {
      await expectLater(
        endpoints.profiles.me(fixtures.guest),
        throwsNexo(NexoErrorCode.unauthenticated),
      );
    });

    group('when editing the profile', () {
      late TestSessionBuilder elena;

      setUp(() async {
        elena = fixtures.signedIn(await registered('elena@example.com'));
        await endpoints.profiles.me(elena);
      });

      test('then username, name and bio change', () async {
        final me = await endpoints.profiles.update(
          elena,
          ProfileEdit(
            username: 'Elena_UX',
            displayName: 'Elena Vega',
            bio: 'Diseño mobile',
          ),
        );

        expect(me.profile.username, 'elena_ux');
        expect(me.profile.displayName, 'Elena Vega');
        expect(me.profile.bio, 'Diseño mobile');
      });

      test('then a username in use is a conflict', () async {
        final other = fixtures.signedIn(await registered('tomas@example.com'));
        await endpoints.profiles.me(other);

        await expectLater(
          endpoints.profiles.update(elena, ProfileEdit(username: 'tomas')),
          throwsNexo(NexoErrorCode.conflict),
        );
      });

      test('then an invalid or reserved username is rejected', () async {
        for (final bad in ['ab', 'elena.ux', 'admin', 'a' * 25]) {
          await expectLater(
            endpoints.profiles.update(elena, ProfileEdit(username: bad)),
            throwsNexo(NexoErrorCode.invalidInput),
            reason: bad,
          );
        }
      });

      test('then a bio over the limit is rejected', () async {
        await expectLater(
          endpoints.profiles.update(elena, ProfileEdit(bio: 'x' * 161)),
          throwsNexo(NexoErrorCode.invalidInput),
        );
      });

      test('then the new name shows up as post author', () async {
        await endpoints.profiles.update(
          elena,
          ProfileEdit(username: 'elena_ux', displayName: 'Elena Vega'),
        );

        final post = await endpoints.posts.create(
          elena,
          fixtures.draft('hola'),
        );

        expect(post.authorUsername, 'elena_ux');
        expect(post.authorName, 'Elena Vega');
      });
    });

    group('when becoming a creator', () {
      test('then the account is a creator but not verified', () async {
        final id = await registered('creadora@example.com');

        final me = await endpoints.profiles.becomeCreator(
          fixtures.signedIn(id),
        );

        expect(me.profile.isCreator, isTrue);
        expect(me.profile.verification, VerificationStatus.none);
      });

      test('then it is audited once, even if asked twice', () async {
        final id = await registered('creadora@example.com');
        final session = fixtures.signedIn(id);

        await endpoints.profiles.becomeCreator(session);
        await endpoints.profiles.becomeCreator(session);

        final audit = await AuditLog.db.find(
          fixtures.session,
          where: (t) => t.action.equals('identity.becomeCreator'),
        );
        expect(audit, hasLength(1));
        expect(audit.single.actorId, id);
      });
    });

    group('when looking up a public profile', () {
      test('then a guest sees it by username, in any case', () async {
        final id = await registered('elena@example.com');
        await endpoints.profiles.me(fixtures.signedIn(id));

        final profile = await endpoints.profiles.byUsername(
          fixtures.guest,
          'ELENA',
        );

        expect(profile.userId, id);
      });

      test('then an unknown username is not found', () async {
        await expectLater(
          endpoints.profiles.byUsername(fixtures.guest, 'nadie'),
          throwsNexo(NexoErrorCode.notFound),
        );
      });
    });
  });
}
