import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

enum ActivityStatus { loading, ready, failure }

/// Por qué falló una acción sobre la bandeja. La View lo traduce.
enum ActivityIssue { markFailed, loadMoreFailed }

class ActivityState extends Equatable {
  const ActivityState({
    this.status = ActivityStatus.loading,
    this.items = const [],
    this.featured,
    this.filter,
    this.nextCursor,
    this.loadingMore = false,
    this.reconnecting = false,
    this.issue,
    this.issueSerial = 0,
  });

  final ActivityStatus status;
  final List<AppNotification> items;
  final FeaturedActivity? featured;

  /// Null es "todo". Un enum nullable en vez de un miembro centinela para que
  /// los switch exhaustivos sobre NotificationType sigan siendo exhaustivos.
  final NotificationType? filter;

  /// El cursor de la próxima página; null es que no hay más.
  final String? nextCursor;
  final bool loadingMore;

  /// Se cortó la conexión en tiempo real. La lista sigue ahí; lo nuevo
  /// llega cuando vuelve.
  final bool reconnecting;

  /// El último rechazo. [issueSerial] crece con cada uno, así que el mismo
  /// fallo dos veces seguidas también se avisa dos veces.
  final ActivityIssue? issue;
  final int issueSerial;

  bool get hasMore => nextCursor != null;

  List<AppNotification> get visible => filter == null
      ? items
      : items.where((item) => item.type == filter).toList();

  int get unreadCount => items.where((item) => !item.read).length;

  /// Cuántas de las visibles están sin leer. Es lo que muestra el encabezado
  /// de cada franja, y tiene que respetar el filtro: contar todas diría "3
  /// nuevas" sobre una lista donde no se ve ninguna.
  int unreadIn(ActivityBucket bucket, {DateTime? now}) => visible
      .where((item) => !item.read && item.bucket(now: now) == bucket)
      .length;

  List<AppNotification> inBucket(ActivityBucket bucket, {DateTime? now}) =>
      visible.where((item) => item.bucket(now: now) == bucket).toList();

  ActivityState copyWith({
    ActivityStatus? status,
    List<AppNotification>? items,
    FeaturedActivity? featured,
    NotificationType? filter,
    bool clearFilter = false,
    String? nextCursor,
    bool clearCursor = false,
    bool? loadingMore,
    bool? reconnecting,
    ActivityIssue? issue,
    int? issueSerial,
  }) => ActivityState(
    status: status ?? this.status,
    items: items ?? this.items,
    featured: featured ?? this.featured,
    filter: clearFilter ? null : (filter ?? this.filter),
    nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
    loadingMore: loadingMore ?? this.loadingMore,
    reconnecting: reconnecting ?? this.reconnecting,
    issue: issue ?? this.issue,
    issueSerial: issueSerial ?? this.issueSerial,
  );

  @override
  List<Object?> get props => [
    status,
    items,
    featured,
    filter,
    nextCursor,
    loadingMore,
    reconnecting,
    issue,
    issueSerial,
  ];
}

class ActivityCubit extends Cubit<ActivityState> {
  ActivityCubit(
    this._repository, {
    this.reconnectDelays = defaultReconnectDelays,
  }) : super(const ActivityState());

  final NotificationRepository _repository;

  /// Entre reintentos cuando se corta el tiempo real: rápido al principio y
  /// después cada 5 s, sin rendirse mientras la pantalla esté abierta.
  final List<Duration> reconnectDelays;

  static const defaultReconnectDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 5),
  ];

  StreamSubscription<AppNotification>? _live;
  Timer? _reconnect;
  int _attempt = 0;

  /// La primera página y, después, el tiempo real. Lo que llega por el
  /// stream se agrega arriba sin recargar.
  Future<void> load() async {
    emit(state.copyWith(status: ActivityStatus.loading));
    try {
      final page = await _repository.list();
      final featured = await _repository.featured();
      if (isClosed) return;
      emit(
        ActivityState(
          status: ActivityStatus.ready,
          items: _merge(const [], page.items),
          featured: featured,
          filter: state.filter,
          nextCursor: page.nextCursor,
          issueSerial: state.issueSerial,
        ),
      );
    } on Failure {
      if (!isClosed) emit(state.copyWith(status: ActivityStatus.failure));
      return;
    }
    _listen();
  }

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.loadingMore) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _repository.list(cursor: cursor);
      if (isClosed) return;
      emit(
        state.copyWith(
          items: _merge(state.items, page.items),
          nextCursor: page.nextCursor,
          clearCursor: page.nextCursor == null,
          loadingMore: false,
        ),
      );
    } on Failure {
      if (isClosed) return;
      emit(
        state.copyWith(
          loadingMore: false,
          issue: ActivityIssue.loadMoreFailed,
          issueSerial: state.issueSerial + 1,
        ),
      );
    }
  }

  void _listen() {
    unawaited(_live?.cancel());
    _live = _repository.watch().listen(
      (notification) {
        if (isClosed) return;
        _attempt = 0;
        emit(
          state.copyWith(
            items: _merge([notification], state.items),
            reconnecting: false,
          ),
        );
      },
      onError: (Object error) {
        // Sin sesión no hay a qué reconectar: un invitado no tiene bandeja.
        if (isClosed || error is ForbiddenFailure) return;
        _scheduleReconnect();
      },
      onDone: () {
        if (!isClosed) _scheduleReconnect();
      },
      cancelOnError: false,
    );
  }

  void _scheduleReconnect() {
    if (isClosed || (_reconnect?.isActive ?? false)) return;
    unawaited(_live?.cancel());
    _live = null;
    emit(state.copyWith(reconnecting: true));
    final delay =
        reconnectDelays[_attempt.clamp(0, reconnectDelays.length - 1)];
    _attempt++;
    _reconnect = Timer(delay, () {
      if (isClosed) return;
      // Lo que llegó mientras no había conexión no vino por el stream: la
      // primera página lo trae, y `_merge` no duplica lo que ya estaba.
      unawaited(_resync());
      _listen();
    });
  }

  Future<void> _resync() async {
    try {
      final page = await _repository.list();
      if (isClosed) return;
      emit(
        state.copyWith(
          items: _merge(page.items, state.items),
          reconnecting: false,
        ),
      );
    } on Failure {
      // El próximo corte vuelve a intentar.
    }
  }

  /// Une dos listas sin repetir ids, de la más nueva a la más vieja. Lo que
  /// viene primero gana: es lo más reciente que se sabe de ese aviso. A igual
  /// fecha se respeta el orden de llegada (el del servidor): `sort` no es
  /// estable y dos avisos del mismo segundo se intercambiarían.
  static List<AppNotification> _merge(
    List<AppNotification> first,
    List<AppNotification> second,
  ) {
    final seen = <String>{};
    final unique = [
      for (final item in [...first, ...second])
        if (seen.add(item.id)) item,
    ];
    final ordered = unique.indexed.toList()
      ..sort((a, b) {
        final byDate = b.$2.createdAt.compareTo(a.$2.createdAt);
        return byDate != 0 ? byDate : a.$1.compareTo(b.$1);
      });
    return [for (final (_, item) in ordered) item];
  }

  void filterBy(NotificationType? type) => emit(
    type == null
        ? state.copyWith(clearFilter: true)
        : state.copyWith(filter: type),
  );

  /// Abrir un aviso lo marca leído. Optimista: el punto se apaga al tocar, y
  /// si el servidor falla vuelve a encenderse.
  Future<void> markRead(String id) async {
    final before = state.items;
    final target = before.where((item) => item.id == id).firstOrNull;
    if (target == null || target.read) return;
    emit(
      state.copyWith(
        items: [
          for (final item in before)
            item.id == id ? item.copyWith(read: true) : item,
        ],
      ),
    );
    try {
      await _repository.markRead([id]);
    } on Failure {
      _restore(before);
    }
  }

  /// Marca todas, no sólo las visibles: con un filtro activo, saltar las
  /// ocultas deja un badge que el usuario cree haber limpiado. Y todas en el
  /// servidor, no sólo las cargadas: las de páginas sin abrir también.
  Future<void> markAllRead() async {
    final before = state.items;
    emit(
      state.copyWith(
        items: [for (final item in before) item.copyWith(read: true)],
      ),
    );
    try {
      await _repository.markAllRead();
    } on Failure {
      _restore(before);
    }
  }

  void _restore(List<AppNotification> before) {
    if (isClosed) return;
    emit(
      state.copyWith(
        items: before,
        issue: ActivityIssue.markFailed,
        issueSerial: state.issueSerial + 1,
      ),
    );
  }

  void toggleReminder() {
    final featured = state.featured;
    if (featured == null) return;
    emit(
      state.copyWith(
        featured: featured.copyWith(reminderSet: !featured.reminderSet),
      ),
    );
  }

  @override
  Future<void> close() async {
    _reconnect?.cancel();
    await _live?.cancel();
    return super.close();
  }
}
