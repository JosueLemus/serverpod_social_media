import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/features/auth/domain/entities/app_user.dart';
import 'package:nexo_social/features/auth/domain/repositories/auth_repository.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nexo_social/features/notifications/presentation/bloc/unread_activity_cubit.dart';

import '../support/fake_notification_repository.dart';

class _Repository extends Mock implements AuthRepository {
  @override
  Stream<AppUser?> watchSession() => const Stream.empty();
}

/// Una sesión que el test mueve a mano.
class _Session extends AuthCubit {
  _Session() : super(_Repository());

  void become(AuthState next) => emit(next);
}

const _elena = AppUser(
  id: 'elena',
  username: 'elena_ux',
  name: 'Elena Vega',
  role: UserRole.user,
);

const _tomas = AppUser(
  id: 'tomas',
  username: 'tomas',
  name: 'Tomás Ríos',
  role: UserRole.user,
);

const _guest = AppUser(
  id: 'guest',
  username: 'invitado',
  name: 'Invitado',
  role: UserRole.visitor,
);

void main() {
  late _Session session;
  late FakeNotificationRepository repository;

  setUp(() {
    session = _Session();
    repository = FakeNotificationRepository(unread: 3);
  });

  tearDown(() => session.close());

  UnreadActivityCubit build() {
    final cubit = UnreadActivityCubit(
      repository,
      session,
      reconnectDelays: const [Duration(milliseconds: 10)],
    );
    addTearDown(cubit.close);
    return cubit;
  }

  test('sin sesión el badge es 0 y no escucha nada', () async {
    session.become(const AuthUnauthenticated());
    final cubit = build();
    await pumpEventQueue();

    expect(cubit.state, 0);
    expect(repository.watchers, isEmpty);
  });

  test('un invitado no tiene bandeja', () async {
    session.become(const AuthAuthenticated(_guest));
    final cubit = build();
    await pumpEventQueue();

    expect(cubit.state, 0);
    expect(repository.watchers, isEmpty);
  });

  test('con sesión pide el conteo y suma lo que llega en vivo', () async {
    session.become(const AuthAuthenticated(_elena));
    final cubit = build();
    await pumpEventQueue();
    expect(cubit.state, 3);

    repository.current.add(notification('n1'));
    await pumpEventQueue();
    expect(cubit.state, 4);

    // Un aviso que ya llega leído no enciende nada.
    repository.current.add(notification('n2', read: true));
    await pumpEventQueue();
    expect(cubit.state, 4);
  });

  test('baja cuando se marca desde Actividad', () async {
    session.become(const AuthAuthenticated(_elena));
    final cubit = build();
    await pumpEventQueue();

    await repository.markRead(['a']);
    await pumpEventQueue();
    expect(cubit.state, 2);

    await repository.markAllRead();
    await pumpEventQueue();
    expect(cubit.state, 0);
  });

  test('cerrar sesión lo apaga, y otra cuenta empieza de cero', () async {
    session.become(const AuthAuthenticated(_elena));
    final cubit = build();
    await pumpEventQueue();
    expect(cubit.state, 3);

    session.become(const AuthUnauthenticated());
    await pumpEventQueue();
    expect(cubit.state, 0);

    repository.unread = 1;
    session.become(const AuthAuthenticated(_tomas));
    await pumpEventQueue();
    expect(cubit.state, 1);
    expect(repository.watchers, hasLength(2));
  });

  test('si se corta el stream, se vuelve a suscribir', () async {
    session.become(const AuthAuthenticated(_elena));
    final cubit = build();
    await pumpEventQueue();

    repository.unread = 5;
    repository.current.addError(const NetworkFailure('caída'));
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(repository.watchers, hasLength(2));
    // El conteo del servidor incluye lo que llegó durante el corte.
    expect(cubit.state, 5);
  });
}
