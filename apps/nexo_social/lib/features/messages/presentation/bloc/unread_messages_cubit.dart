import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/direct_message.dart';
import '../../domain/repositories/messages_repository.dart';

/// Cuántas conversaciones tienen algo sin leer: el número sobre "Mensajes".
///
/// Singleton, como `UnreadActivityCubit`: lo lee la barra del feed desde
/// cualquier pestaña. Sigue a la sesión; sin cuenta real es 0. Cada evento
/// del servidor trae el total ya calculado (SDD 0010, M8).
class UnreadMessagesCubit extends Cubit<int> {
  UnreadMessagesCubit(
    this._repository,
    AuthCubit auth, {
    this.reconnectDelays = defaultReconnectDelays,
  }) : super(0) {
    _session = auth.stream.listen(_onSession);
    _onSession(auth.state);
  }

  final MessagesRepository _repository;
  final List<Duration> reconnectDelays;

  static const defaultReconnectDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 5),
  ];

  late final StreamSubscription<AuthState> _session;
  StreamSubscription<DirectMessageEvent>? _live;
  Timer? _reconnect;
  int _attempt = 0;
  String? _accountId;

  /// El chat avisa lo que devolvió `markRead`, por si el evento tarda.
  void set(int count) {
    if (!isClosed && _accountId != null) emit(count);
  }

  void _onSession(AuthState state) {
    final user = state is AuthAuthenticated ? state.user : null;
    final accountId = user != null && user.role != UserRole.visitor
        ? user.id
        : null;
    if (accountId == _accountId) return;
    _accountId = accountId;
    _stop();
    if (isClosed) return;
    emit(0);
    if (accountId != null) {
      _listen(accountId);
      unawaited(_refresh(accountId));
    }
  }

  Future<void> _refresh(String accountId) async {
    try {
      final count = await _repository.unreadCount();
      if (!isClosed && _accountId == accountId) emit(count);
    } on Failure {
      // Sin conteo, el badge queda como estaba; el próximo evento lo corrige.
    }
  }

  void _listen(String accountId) {
    unawaited(_live?.cancel());
    _live = _repository.watch().listen(
      (event) {
        if (isClosed || _accountId != accountId) return;
        _attempt = 0;
        emit(event.unreadConversations);
      },
      onError: (Object error) {
        if (isClosed || error is ForbiddenFailure) return;
        _scheduleReconnect(accountId);
      },
      onDone: () {
        if (!isClosed) _scheduleReconnect(accountId);
      },
      cancelOnError: false,
    );
  }

  void _scheduleReconnect(String accountId) {
    if (isClosed || (_reconnect?.isActive ?? false)) return;
    unawaited(_live?.cancel());
    _live = null;
    final delay =
        reconnectDelays[_attempt.clamp(0, reconnectDelays.length - 1)];
    _attempt++;
    _reconnect = Timer(delay, () {
      if (isClosed || _accountId != accountId) return;
      unawaited(_refresh(accountId));
      _listen(accountId);
    });
  }

  void _stop() {
    _reconnect?.cancel();
    _reconnect = null;
    _attempt = 0;
    unawaited(_live?.cancel());
    _live = null;
  }

  @override
  Future<void> close() async {
    await _session.cancel();
    _stop();
    return super.close();
  }
}
