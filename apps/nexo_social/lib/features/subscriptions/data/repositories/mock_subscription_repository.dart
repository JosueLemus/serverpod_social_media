import '../../domain/entities/entitlement.dart';
import '../../domain/repositories/subscription_repository.dart';

class MockSubscriptionRepository implements SubscriptionRepository {
  final _active = <String>{};
  final donations = <String, int>{};
  @override
  Future<Entitlement> entitlement(String creator) async =>
      Entitlement(creator: creator, active: _active.contains(creator));
  @override
  Future<Entitlement> subscribe(String creator) async {
    _active.add(creator);
    return Entitlement(creator: creator, active: true);
  }

  @override
  Future<void> donate(String creator, int amount) async {
    donations[creator] = (donations[creator] ?? 0) + amount;
  }
}
