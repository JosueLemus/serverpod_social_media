import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/core/mock/mock_platform.dart';
import 'package:nexo_social/features/live/data/repositories/mock_live_repository.dart';
import 'package:nexo_social/features/live/domain/entities/live_moderation.dart';
import 'package:nexo_social/features/live/presentation/bloc/live_room_cubit.dart';
import 'package:nexo_social/features/moderation/data/repositories/mock_moderation_repository.dart';

import '../../../support/platform_harness.dart';

/// La sala frente a la moderación (SDD 0011, Etapa 3). Lo que ve cada uno es
/// lo que vuelve del "servidor".
void main() {
  const live = 'live-1';
  late MockPlatform platform;
  late LiveRoomCubit viewer;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() async {
    platform = await platformAs(DemoAccounts.viewer.id);
    viewer = LiveRoomCubit(
      MockLiveRepository(platform),
      MockModerationRepository(platform),
    );
    await viewer.load(live);
  });

  tearDown(() async {
    await viewer.close();
    await platform.dispose();
  });

  /// Lo que hace el host "desde otro dispositivo".
  void asHost(void Function() action) {
    platform.bindSession(DemoAccounts.elena.id);
    action();
    platform.bindSession(DemoAccounts.viewer.id);
  }

  test('un silencio le llega a quien lo recibe', () async {
    asHost(
      () => platform.muteChat(
        live,
        DemoAccounts.viewer.id,
        LiveMuteDuration.restOfLive,
      ),
    );
    await settle();

    expect(viewer.state.myMute, const LiveChatMute());
    await viewer.sendComment('hola');
    expect(viewer.state.issue, LiveRoomIssue.muted);
  });

  test('una expulsión saca de la sala y deja de reconectar', () async {
    asHost(() => platform.kick(live, DemoAccounts.viewer.id));
    await settle();

    expect(viewer.state.exclusion, LiveSanctionKind.kick);
    expect(viewer.state.reconnecting, isFalse);
  });

  test('fijar y despegar se ve en la sala de los demás', () async {
    await viewer.sendComment('link útil');
    final comment = viewer.state.comments.last;

    asHost(() => platform.pinComment(live, comment.id));
    await settle();
    expect(viewer.state.pinnedComment?.id, comment.id);

    asHost(() => platform.pinComment(live, null));
    await settle();
    expect(viewer.state.pinnedComment, isNull);
  });

  test('un oyente no puede fijar: el rechazo llega tipado', () async {
    await viewer.sendComment('mío');
    await viewer.pinComment(viewer.state.comments.last);

    expect(viewer.state.issue, LiveRoomIssue.forbidden);
    expect(viewer.state.pinnedComment, isNull);
  });
}
