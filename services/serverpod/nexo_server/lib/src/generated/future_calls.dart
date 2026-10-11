/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: depend_on_referenced_packages

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _ida;
import 'package:clock/clock.dart' as _io0w16m8;
import 'package:serverpod/serverpod.dart' as _is;
import '../modules/live/future_calls/live_show_future_call.dart' as _ivb8gyo1;
import 'future_calls_generated_models/live_show_future_call_expire_model.dart'
    as _ie5d2xvy;
import 'future_calls_generated_models/live_show_future_call_publish_replay_model.dart'
    as _iy3z9iri;
import 'future_calls_generated_models/live_show_future_call_remind_model.dart'
    as _iqr7hhpp;

/// Invokes a future call.
typedef _InvokeFutureCall =
    Future<void> Function(String name, _is.SerializableModel? object);

extension ServerpodFutureCallsGetter on _is.Serverpod {
  /// Generated future calls.
  FutureCalls get futureCalls => FutureCalls();
}

class FutureCalls extends _is.FutureCallDispatch<_FutureCallRef> {
  FutureCalls._();

  factory FutureCalls() {
    return _instance;
  }

  static final FutureCalls _instance = FutureCalls._();

  _is.FutureCallManager? _futureCallManager;

  String? _serverId;

  String get _effectiveServerId {
    if (_serverId == null) {
      throw StateError('FutureCalls is not initialized.');
    }
    return _serverId!;
  }

  _is.FutureCallManager get _effectiveFutureCallManager {
    if (_futureCallManager == null) {
      throw StateError('FutureCalls is not initialized.');
    }
    return _futureCallManager!;
  }

  @override
  void initialize(
    _is.FutureCallManager futureCallManager,
    String serverId,
  ) {
    var registeredFutureCalls = <String, _is.InvokableFutureCall>{
      'LiveShowRemindFutureCall': LiveShowRemindFutureCall(),
      'LiveShowExpireFutureCall': LiveShowExpireFutureCall(),
      'LiveShowPublishReplayFutureCall': LiveShowPublishReplayFutureCall(),
    };
    _futureCallManager = futureCallManager;
    _serverId = serverId;
    for (final entry in registeredFutureCalls.entries) {
      _futureCallManager?.registerFutureCall(entry.value, entry.key);
    }
  }

  @override
  _FutureCallRef callAtTime(
    DateTime time, {
    String? identifier,
  }) {
    return _FutureCallRef(
      (name, object) {
        return _effectiveFutureCallManager.scheduleFutureCall(
          name,
          object,
          time,
          _effectiveServerId,
          identifier,
        );
      },
    );
  }

  @override
  _FutureCallRef callWithDelay(
    Duration delay, {
    String? identifier,
  }) {
    return _FutureCallRef(
      (name, object) {
        return _effectiveFutureCallManager.scheduleFutureCall(
          name,
          object,
          DateTime.now().toUtc().add(delay),
          _effectiveServerId,
          identifier,
        );
      },
    );
  }

  @override
  _is.RecurringFutureCallDispatch<_FutureCallRef> callRecurring({
    String? identifier,
  }) {
    return _RecurringFutureCallDispatchImpl(
      _effectiveFutureCallManager,
      _effectiveServerId,
      identifier,
    );
  }

  @override
  Future<void> cancel(String identifier) async {
    await _effectiveFutureCallManager.cancelFutureCall(identifier);
  }
}

class _RecurringFutureCallDispatchImpl
    extends _is.RecurringFutureCallDispatch<_FutureCallRef> {
  _RecurringFutureCallDispatchImpl(
    this._futureCallManager,
    this._serverId,
    this._identifier,
  );

  final _is.FutureCallManager _futureCallManager;

  final String _serverId;

  final String? _identifier;

  @override
  _FutureCallRef cron(String cronExpression) {
    return _FutureCallRef(
      (name, object) {
        return _futureCallManager.scheduleFutureCall(
          name,
          object,
          _is.Cron.parse(cronExpression).nextTime(),
          _serverId,
          _identifier,
          scheduling: _is.CronFutureCallScheduling(cron: cronExpression),
        );
      },
    );
  }

  @override
  _FutureCallRef every(
    Duration interval, {
    DateTime? start,
  }) {
    final now = _io0w16m8.clock.now().toUtc();
    return _FutureCallRef(
      (name, object) {
        return _futureCallManager.scheduleFutureCall(
          name,
          object,
          start ?? now.add(interval),
          _serverId,
          _identifier,
          scheduling: _is.IntervalFutureCallScheduling(
            interval: interval,
            start: start,
          ),
        );
      },
    );
  }
}

class _FutureCallRef {
  _FutureCallRef(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  late final liveShow = _LiveShowFutureCallDispatcher(_invokeFutureCall);
}

class _LiveShowFutureCallDispatcher {
  _LiveShowFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> remind(int showId) {
    var object = _iqr7hhpp.LiveShowFutureCallRemindModel(showId: showId);
    return _invokeFutureCall(
      'LiveShowRemindFutureCall',
      object,
    );
  }

  Future<void> expire(int showId) {
    var object = _ie5d2xvy.LiveShowFutureCallExpireModel(showId: showId);
    return _invokeFutureCall(
      'LiveShowExpireFutureCall',
      object,
    );
  }

  Future<void> publishReplay(int showId) {
    var object = _iy3z9iri.LiveShowFutureCallPublishReplayModel(showId: showId);
    return _invokeFutureCall(
      'LiveShowPublishReplayFutureCall',
      object,
    );
  }
}

/// 15 minutos antes: avisa a los seguidores y a los invitados.
class LiveShowRemindFutureCall
    extends _is.FutureCall<_iqr7hhpp.LiveShowFutureCallRemindModel>
    implements
        _is.InvokableFutureCall<_iqr7hhpp.LiveShowFutureCallRemindModel> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _iqr7hhpp.LiveShowFutureCallRemindModel? object,
  ) async {
    if (object != null) {
      await _ivb8gyo1.LiveShowFutureCall().remind(
        session,
        object.showId,
      );
    }
  }
}

/// A los 30 minutos del inicio, un show que no arrancó se cancela.
class LiveShowExpireFutureCall
    extends _is.FutureCall<_ie5d2xvy.LiveShowFutureCallExpireModel>
    implements
        _is.InvokableFutureCall<_ie5d2xvy.LiveShowFutureCallExpireModel> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _ie5d2xvy.LiveShowFutureCallExpireModel? object,
  ) async {
    if (object != null) {
      await _ivb8gyo1.LiveShowFutureCall().expire(
        session,
        object.showId,
      );
    }
  }
}

/// 1 minuto después de terminar, el replay se publica solo.
class LiveShowPublishReplayFutureCall
    extends _is.FutureCall<_iy3z9iri.LiveShowFutureCallPublishReplayModel>
    implements
        _is.InvokableFutureCall<
          _iy3z9iri.LiveShowFutureCallPublishReplayModel
        > {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _iy3z9iri.LiveShowFutureCallPublishReplayModel? object,
  ) async {
    if (object != null) {
      await _ivb8gyo1.LiveShowFutureCall().publishReplay(
        session,
        object.showId,
      );
    }
  }
}
