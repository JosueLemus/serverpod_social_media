import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// Cuántos avisos sin leer tiene la sesión: el número sobre la campana.
///
/// Singleton, como [AuthCubit]: lo lee el shell en todas las pestañas, y con
/// una instancia por pantalla el badge se reiniciaría al cambiar de pestaña.
/// Sigue a la sesión: con una cuenta pide el conteo y escucha los avisos
/// nuevos; sin sesión, o como invitado, es 0.
class UnreadActivityCubit extends Cubit<int> {
  UnreadActivityCubit(
    this._repository,
    AuthCubit auth, {
    this.reconnectDelays = defaultReconnectDelays,
  }) : super(0) {
    _session = auth.stream.listen(_onSession);
    _onSession(auth.state);
  }

  final NotificationRepository _repository;
  final List<Duration> reconnectDelays;

  static const defaultReconnectDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 5),
  ];

  late final StreamSubscription<AuthState> _session;
  StreamSubscription<AppNotification>? _live;
  StreamSubscription<int>? _marks;
  Timer? _reconnect;
  int _attempt = 0;

  /// La cuenta que se está siguiendo. Cambiar de cuenta reinicia el conteo:
  /// los avisos de una no son de la otra.
  String? _accountId;

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
    if (accountId != null) _start(accountId);
  }

  void _start(String accountId) {
    _marks = _repository.unreadChanges().listen((count) {
      if (!isClosed && _accountId == accountId) emit(count);
    });
    _listen(accountId);
    unawaited(_refresh(accountId));
  }

  Future<void> _refresh(String accountId) async {
    try {
      final count = await _repository.unreadCount();
      if (!isClosed && _accountId == accountId) emit(count);
    } on Failure {
      // Sin conteo el badge queda como estaba; el próximo aviso lo corrige.
    }
  }

  void _listen(String accountId) {
    unawaited(_live?.cancel());
    _live = _repository.watch().listen(
      (notification) {
        if (isClosed || _accountId != accountId) return;
        _attempt = 0;
        if (!notification.read) emit(state + 1);
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
      // Lo que llegó durante el corte no vino por el stream: el conteo del
      // servidor lo incluye.
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
    unawaited(_marks?.cancel());
    _marks = null;
  }

  @override
  Future<void> close() async {
    await _session.cancel();
    _stop();
    return super.close();
  }
}
