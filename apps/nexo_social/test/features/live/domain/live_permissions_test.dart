import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/features/live/domain/entities/live_permissions.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';

void main() {
  test('la hoja de una persona ofrece sólo lo que el rango permite', () {
    expect(
      LivePermissions.on(LiveRole.moderator, LiveRole.audience),
      containsAll([
        LiveAction.approveRequest,
        LiveAction.muteChat,
        LiveAction.kick,
        LiveAction.hideChat,
      ]),
    );
    expect(
      LivePermissions.on(LiveRole.moderator, LiveRole.audience),
      isNot(contains(LiveAction.ban)),
    );
    expect(LivePermissions.on(LiveRole.moderator, LiveRole.host), isEmpty);
    expect(LivePermissions.on(LiveRole.cohost, LiveRole.audience), isEmpty);
    expect(
      LivePermissions.on(LiveRole.host, LiveRole.moderator),
      containsAll([LiveAction.assignModerator, LiveAction.kick]),
    );
  });

  test('un control se dibuja según el repertorio del rol', () {
    expect(
      LivePermissions.hasAction(LiveRole.audience, LiveAction.raiseHand),
      isTrue,
    );
    expect(
      LivePermissions.hasAction(LiveRole.cohost, LiveAction.speak),
      isTrue,
    );
    expect(
      LivePermissions.hasAction(LiveRole.cohost, LiveAction.kick),
      isFalse,
    );
    expect(LivePermissions.hasAction(LiveRole.host, LiveAction.end), isTrue);
  });
}
