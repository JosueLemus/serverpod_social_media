import 'package:nexo_server/src/generated/protocol.dart';
import 'package:nexo_server/src/modules/live/services/live_permissions.dart';
import 'package:test/test.dart';

const _host = LiveShowRole.host;
const _mod = LiveShowRole.moderator;
const _guest = LiveShowRole.cohost;
const _audience = LiveShowRole.audience;

void main() {
  group('Given the room hierarchy', () {
    test('then host > moderator > guest > audience', () {
      expect(
        LivePermissions.rank(_host),
        greaterThan(LivePermissions.rank(_mod)),
      );
      expect(
        LivePermissions.rank(_mod),
        greaterThan(LivePermissions.rank(_guest)),
      );
      expect(
        LivePermissions.rank(_guest),
        greaterThan(LivePermissions.rank(_audience)),
      );
    });

    test('then every action has an entry in the table', () {
      expect(LivePermissions.allowed.keys, unorderedEquals(LiveAction.values));
    });
  });

  group('Given an action on oneself', () {
    test('then only the stage roles speak', () {
      expect(LivePermissions.can(_host, LiveAction.speak), isTrue);
      expect(LivePermissions.can(_mod, LiveAction.speak), isTrue);
      expect(LivePermissions.can(_guest, LiveAction.speak), isTrue);
      expect(LivePermissions.can(_audience, LiveAction.speak), isFalse);
    });

    test('then the audience asks for the floor and the host never does', () {
      expect(LivePermissions.can(_audience, LiveAction.raiseHand), isTrue);
      expect(LivePermissions.can(_host, LiveAction.raiseHand), isFalse);
      expect(LivePermissions.can(_guest, LiveAction.raiseHand), isFalse);
    });

    test('then a guest highlights questions but does not moderate', () {
      expect(LivePermissions.can(_guest, LiveAction.highlightQuestion), isTrue);
      for (final action in LivePermissions.targeted) {
        expect(
          LivePermissions.can(_guest, action, target: _audience),
          isFalse,
          reason: '$action',
        );
      }
    });

    test('then everyone chats and reacts', () {
      for (final role in LiveShowRole.values) {
        expect(LivePermissions.can(role, LiveAction.chat), isTrue);
        expect(LivePermissions.can(role, LiveAction.react), isTrue);
      }
    });

    test('then only the host ends the live', () {
      expect(LivePermissions.can(_host, LiveAction.end), isTrue);
      expect(LivePermissions.can(_mod, LiveAction.end), isFalse);
    });
  });

  group('Given an action on someone else', () {
    test('then it needs a strictly higher rank', () {
      expect(
        LivePermissions.can(_mod, LiveAction.kick, target: _audience),
        isTrue,
      );
      expect(
        LivePermissions.can(_mod, LiveAction.kick, target: _guest),
        isTrue,
      );
      expect(LivePermissions.can(_mod, LiveAction.kick, target: _mod), isFalse);
      expect(
        LivePermissions.can(_mod, LiveAction.kick, target: _host),
        isFalse,
      );
      expect(LivePermissions.can(_host, LiveAction.kick, target: _mod), isTrue);
    });

    test('then without a target it is denied', () {
      expect(LivePermissions.can(_host, LiveAction.kick), isFalse);
    });

    test('then the moderator does not touch the stage composition', () {
      expect(
        LivePermissions.can(_mod, LiveAction.approveRequest, target: _audience),
        isTrue,
      );
      expect(
        LivePermissions.can(_mod, LiveAction.inviteToStage, target: _audience),
        isFalse,
      );
      expect(
        LivePermissions.can(_mod, LiveAction.removeFromStage, target: _guest),
        isFalse,
      );
      expect(
        LivePermissions.can(_mod, LiveAction.muteMic, target: _guest),
        isTrue,
      );
    });

    test('then ban and naming the moderator are the host\'s alone', () {
      expect(
        LivePermissions.can(_host, LiveAction.ban, target: _audience),
        isTrue,
      );
      expect(
        LivePermissions.can(_mod, LiveAction.ban, target: _audience),
        isFalse,
      );
      expect(
        LivePermissions.can(_host, LiveAction.assignModerator, target: _guest),
        isTrue,
      );
      expect(
        LivePermissions.can(
          _mod,
          LiveAction.assignModerator,
          target: _audience,
        ),
        isFalse,
      );
    });

    test('then nobody acts on the host', () {
      for (final action in LivePermissions.targeted) {
        for (final actor in LiveShowRole.values) {
          expect(
            LivePermissions.can(actor, action, target: _host),
            isFalse,
            reason: '$actor $action',
          );
        }
      }
    });
  });
}
