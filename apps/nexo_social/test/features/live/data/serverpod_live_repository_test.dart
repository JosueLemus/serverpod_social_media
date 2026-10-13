import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_client/nexo_client.dart' as api;
import 'package:nexo_social/features/live/data/repositories/serverpod_live_repository.dart';
import 'package:nexo_social/features/live/domain/entities/live_media_grant.dart';
import 'package:nexo_social/features/live/domain/entities/live_room_event.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';

void main() {
  final elena = api.UuidValue.fromString(
    '550e8400-e29b-41d4-a716-446655440000',
  );
  final tomas = api.UuidValue.fromString(
    '660e8400-e29b-41d4-a716-446655440000',
  );

  api.LiveShowView view({
    api.LiveShowStatus status = api.LiveShowStatus.live,
    api.LiveShowAccess access = api.LiveShowAccess.public,
    String? hostName = 'Elena Vega',
  }) => api.LiveShowView(
    id: 12,
    hostId: elena,
    hostUsername: 'elena_ux',
    hostName: hostName,
    title: 'Masterclass',
    description: 'Diseño mobile',
    startsAt: DateTime.utc(2026, 10, 11, 20),
    durationMinutes: 60,
    access: access,
    allowQuestions: true,
    recordReplay: false,
    status: status,
    startedAt: DateTime.utc(2026, 10, 11, 20, 5),
    endedByModeration: false,
    viewerCount: 3,
    guestIds: [tomas],
  );

  api.LiveChatMessageView message({required api.UuidValue author}) =>
      api.LiveChatMessageView(
        id: 7,
        showId: 12,
        authorId: author,
        authorUsername: 'tomas',
        authorName: 'Tomás Ríos',
        body: 'hola',
        createdAt: DateTime.utc(2026, 10, 11, 20, 6),
      );

  test('the server show maps field by field', () {
    final session = ServerpodLiveRepository.toSession(view());

    expect(session.id, '12');
    expect(session.hostId, elena.toString());
    expect(session.hostUsername, 'elena_ux');
    expect(session.hostName, 'Elena Vega');
    expect(session.status, LiveStatus.live);
    expect(session.viewers, 3);
    expect(session.recordReplay, isFalse);
    expect(session.cohostIds, [tomas.toString()]);
    expect(session.startedAt, DateTime.utc(2026, 10, 11, 20, 5).toLocal());
    expect(session.scheduledAt, DateTime.utc(2026, 10, 11, 20).toLocal());
  });

  test('every server status has a domain status with the same name', () {
    for (final status in api.LiveShowStatus.values) {
      expect(
        ServerpodLiveRepository.toSession(view(status: status)).status.name,
        status.name,
      );
    }
  });

  test('a members show is premium and a missing name falls back', () {
    final session = ServerpodLiveRepository.toSession(
      view(access: api.LiveShowAccess.members, hostName: null),
    );

    expect(session.isPremium, isTrue);
    expect(session.hostName, 'elena_ux');
  });

  test('a chat message is mine only when the author is the session', () {
    expect(
      ServerpodLiveRepository.toComment(
        message(author: tomas),
        me: tomas.toString(),
      ).isMine,
      isTrue,
    );
    final other = ServerpodLiveRepository.toComment(
      message(author: tomas),
      me: elena.toString(),
    );
    expect(other.isMine, isFalse);
    expect(other.id, '7');
    expect(other.author, 'Tomás Ríos');
  });

  group('server events become room events', () {
    test('a snapshot carries session, role and history', () {
      final event = ServerpodLiveRepository.toEvent(
        api.LiveEvent(
          kind: api.LiveEventKind.snapshot,
          liveShow: view(),
          role: api.LiveShowRole.moderator,
          viewerCount: 3,
          history: [message(author: tomas)],
        ),
        me: null,
      );

      expect(event, isA<LiveRoomSnapshot>());
      final snapshot = event! as LiveRoomSnapshot;
      expect(snapshot.role, LiveRole.moderator);
      expect(snapshot.comments.single.id, '7');
    });

    test('status, viewers, chat and chatHidden map one to one', () {
      LiveRoomEvent? map(api.LiveEvent e) =>
          ServerpodLiveRepository.toEvent(e, me: null);

      expect(
        map(api.LiveEvent(kind: api.LiveEventKind.status, liveShow: view())),
        isA<LiveSessionChanged>(),
      );
      expect(
        map(api.LiveEvent(kind: api.LiveEventKind.viewers, viewerCount: 5)),
        const LiveViewersChanged(5),
      );
      expect(
        map(
          api.LiveEvent(
            kind: api.LiveEventKind.chat,
            message: message(author: tomas),
          ),
        ),
        isA<LiveCommentAdded>(),
      );
      expect(
        map(
          api.LiveEvent(kind: api.LiveEventKind.chatHidden, hiddenMessageId: 7),
        ),
        const LiveCommentHidden('7'),
      );
    });

    test('an event missing its payload is ignored, not a crash', () {
      expect(
        ServerpodLiveRepository.toEvent(
          api.LiveEvent(kind: api.LiveEventKind.status),
          me: null,
        ),
        isNull,
      );
    });
  });

  test('the server media grant maps field by field', () {
    final expiresAt = DateTime.utc(2026, 10, 11, 22);
    expect(
      ServerpodLiveRepository.toGrant(
        api.LiveMediaGrant(
          appId: 'app',
          channel: 'nexo_live_12',
          uid: 4242,
          token: '007abc',
          role: api.LiveMediaGrantRole.publisher,
          expiresAt: expiresAt,
        ),
      ),
      LiveMediaGrant(
        appId: 'app',
        channel: 'nexo_live_12',
        uid: 4242,
        token: '007abc',
        role: LiveMediaGrantRole.publisher,
        expiresAt: expiresAt,
      ),
    );
  });

  group('el escenario', () {
    final stage = api.LiveStageView(
      speakers: [
        api.LiveSpeakerView(
          userId: elena,
          username: 'elena_ux',
          name: 'Elena Vega',
          role: api.LiveShowRole.host,
          micMuted: false,
          cameraOn: true,
        ),
      ],
      hands: [
        api.LiveHandView(
          userId: tomas,
          username: 'tomas',
          raisedAt: DateTime.utc(2026, 10, 12, 20),
        ),
      ],
    );

    test('se traduce con quién es "yo"', () {
      final result = ServerpodLiveRepository.toStage(
        stage,
        me: tomas.toString(),
      );

      expect(result.speakers.single.role, LiveRole.host);
      expect(result.speakers.single.cameraOn, isTrue);
      expect(result.speakers.single.isMe, isFalse);
      // Sin nombre, el handle: nunca una fila en blanco.
      expect(result.hands.single.name, 'tomas');
      expect(result.myHandRaised, isTrue);
    });

    test('llega en el snapshot y como evento propio', () {
      final event = ServerpodLiveRepository.toEvent(
        api.LiveEvent(kind: api.LiveEventKind.stage, stage: stage),
        me: elena.toString(),
      );
      expect(event, isA<LiveStageChanged>());
      expect((event! as LiveStageChanged).stage.meOnStage, isTrue);

      final snapshot = ServerpodLiveRepository.toEvent(
        api.LiveEvent(
          kind: api.LiveEventKind.snapshot,
          liveShow: view(),
          stage: stage,
        ),
        me: null,
      );
      expect((snapshot! as LiveRoomSnapshot).stage.speakers, hasLength(1));
    });

    test('un cambio de rol dice si es mío', () {
      api.LiveEvent changed(api.UuidValue who) => api.LiveEvent(
        kind: api.LiveEventKind.roleChanged,
        targetId: who,
        role: api.LiveShowRole.cohost,
      );

      final mine = ServerpodLiveRepository.toEvent(
        changed(tomas),
        me: tomas.toString(),
      );
      expect(
        mine,
        LiveRoleChanged(
          userId: tomas.toString(),
          role: LiveRole.cohost,
          isMine: true,
        ),
      );
      final theirs = ServerpodLiveRepository.toEvent(
        changed(elena),
        me: tomas.toString(),
      );
      expect((theirs! as LiveRoleChanged).isMine, isFalse);
    });
  });
}
