import 'dart:async';

import '../../domain/entities/entitlement.dart';
import '../../domain/repositories/subscription_repository.dart';

class MockSubscriptionRepository implements SubscriptionRepository {
  final _active = <String>{};
  final donations = <String, int>{};

  /// Los mensajes recibidos por creador. Públicos para los tests: el mock no
  /// los muestra en ningún lado.
  final messages = <String, List<String>>{};
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<void> changes() => _changes.stream;

  @override
  Future<Entitlement> entitlement(String creator) async =>
      Entitlement(creator: creator, active: _active.contains(creator));
  @override
  Future<Entitlement> subscribe(String creator) async {
    if (_active.add(creator)) _changes.add(null);
    return Entitlement(creator: creator, active: true);
  }

  @override
  Future<void> donate(String creator, int amount, {String? message}) async {
    donations[creator] = (donations[creator] ?? 0) + amount;
    if (message != null) messages.putIfAbsent(creator, () => []).add(message);
  }
}
