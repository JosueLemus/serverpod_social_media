import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:nexo_social/features/notifications/domain/entities/app_notification.dart';
import 'package:nexo_social/features/notifications/presentation/bloc/activity_cubit.dart';

import '../support/fake_notification_repository.dart';

void main() {
  group('con la semilla del mock', () {
    late ActivityCubit cubit;

    setUp(() async {
      cubit = ActivityCubit(MockNotificationRepository());
      await cubit.load();
    });

    tearDown(() => cubit.close());

    test('carga la bandeja y queda lista', () {
      expect(cubit.state.status, ActivityStatus.ready);
      expect(cubit.state.items, isNotEmpty);
      expect(cubit.state.visible, hasLength(cubit.state.items.length));
    });

    test('filtrar deja un solo tipo', () {
      cubit.filterBy(NotificationType.follow);

      expect(
        cubit.state.visible.every(
          (item) => item.type == NotificationType.follow,
        ),
        isTrue,
      );
    });

    test('quitar el filtro devuelve todo', () {
      cubit
        ..filterBy(NotificationType.follow)
        ..filterBy(null);

      expect(cubit.state.visible, hasLength(cubit.state.items.length));
    });

    test('marcar una deja las demás como estaban', () async {
      final before = cubit.state.unreadCount;
      final target = cubit.state.items.firstWhere((item) => !item.read);
      await cubit.markRead(target.id);

      final updated = cubit.state.items.firstWhere(
        (item) => item.id == target.id,
      );
      expect(updated.read, isTrue);
      expect(cubit.state.unreadCount, before - 1);
    });

    /// Con un filtro activo, saltar las ocultas deja un badge que el usuario
    /// cree haber limpiado.
    test('"marcar todo" marca también lo que el filtro oculta', () async {
      cubit.filterBy(NotificationType.follow);
      await cubit.markAllRead();

      expect(cubit.state.unreadCount, 0);
      expect(cubit.state.items.every((item) => item.read), isTrue);
    });

    test('cada tipo tiene una etiqueta que no es su identificador', () {
      for (final type in NotificationType.values) {
        expect(type.label, isNotEmpty);
        expect(type.label, isNot(type.name));
      }
    });
  });

  group('contra el servidor', () {
    test('pagina con el cursor opaco y no repite ids', () async {
      final repository = FakeNotificationRepository(
        pages: {
          null: NotificationFeedPage(
            items: [
              notification('3', ago: const Duration(minutes: 1)),
              notification('2', ago: const Duration(minutes: 2)),
            ],
            nextCursor: 'c1',
          ),
          'c1': NotificationFeedPage(
            items: [
              notification('2', ago: const Duration(minutes: 2)),
              notification('1', ago: const Duration(hours: 3)),
            ],
          ),
        },
      );
      final cubit = ActivityCubit(repository);
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state.hasMore, isTrue);

      await cubit.loadMore();
      expect(cubit.state.items.map((item) => item.id), ['3', '2', '1']);
      expect(cubit.state.hasMore, isFalse);
    });

    test(
      'un fallo al cargar es un estado de error, no una lista vacía',
      () async {
        final repository = FakeNotificationRepository()..failList = true;
        final cubit = ActivityCubit(repository);
        addTearDown(cubit.close);

        await cubit.load();

        expect(cubit.state.status, ActivityStatus.failure);
      },
    );

    test('lo que llega en vivo aparece arriba sin recargar', () async {
      final repository = FakeNotificationRepository(
        pages: {
          null: NotificationFeedPage(
            items: [notification('1', ago: const Duration(hours: 1))],
          ),
        },
      );
      final cubit = ActivityCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();

      repository.current.add(
        notification(
          '9',
          type: NotificationType.liveReminder,
          ago: Duration.zero,
          showId: '5',
        ),
      );
      await pumpEventQueue();

      expect(cubit.state.items.first.id, '9');
      expect(cubit.state.unreadCount, 2);
    });

    test('marcar todo va al servidor una sola vez', () async {
      final repository = FakeNotificationRepository(
        pages: {
          null: NotificationFeedPage(
            items: [notification('1'), notification('2')],
          ),
        },
        unread: 2,
      );
      final cubit = ActivityCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();

      await cubit.markAllRead();

      expect(repository.markAllCalls, 1);
      expect(cubit.state.unreadCount, 0);
    });

    test(
      'si el servidor rechaza la marca, el aviso vuelve a no leído',
      () async {
        final repository = FakeNotificationRepository(
          pages: {
            null: NotificationFeedPage(items: [notification('1')]),
          },
        )..failMarks = true;
        final cubit = ActivityCubit(repository);
        addTearDown(cubit.close);
        await cubit.load();

        await cubit.markRead('1');

        expect(cubit.state.items.single.read, isFalse);
        expect(cubit.state.issue, ActivityIssue.markFailed);
        expect(cubit.state.issueSerial, 1);
      },
    );

    test('si se corta el tiempo real, se reconecta y resincroniza', () async {
      final repository = FakeNotificationRepository(
        pages: {
          null: NotificationFeedPage(items: [notification('1')]),
        },
      );
      final cubit = ActivityCubit(
        repository,
        reconnectDelays: const [Duration(milliseconds: 10)],
      );
      addTearDown(cubit.close);
      await cubit.load();
      expect(repository.watchers, hasLength(1));

      repository.current.addError(const NetworkFailure('caída'));
      await pumpEventQueue();
      expect(cubit.state.reconnecting, isTrue);

      // Mientras no había conexión llegó un aviso: la primera página lo trae.
      repository.pages[null] = NotificationFeedPage(
        items: [
          notification('2', ago: Duration.zero),
          notification('1'),
        ],
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(repository.watchers, hasLength(2));
      expect(cubit.state.reconnecting, isFalse);
      expect(cubit.state.items.map((item) => item.id), ['2', '1']);
    });

    test('sin sesión el stream falla y no se insiste', () async {
      final repository = FakeNotificationRepository();
      final cubit = ActivityCubit(
        repository,
        reconnectDelays: const [Duration(milliseconds: 5)],
      );
      addTearDown(cubit.close);
      await cubit.load();

      repository.current.addError(const ForbiddenFailure('sin sesión'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(repository.watchers, hasLength(1));
      expect(cubit.state.reconnecting, isFalse);
    });
  });

  test('el mock entrega avisos nuevos por watch', () async {
    final repository = MockNotificationRepository(seed: const []);
    final cubit = ActivityCubit(repository);
    addTearDown(cubit.close);
    await cubit.load();

    repository.deliver(notification('n'));
    await pumpEventQueue();

    expect(cubit.state.items.single.id, 'n');
  });
}
