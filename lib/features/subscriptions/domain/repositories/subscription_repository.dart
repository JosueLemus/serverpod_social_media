import '../entities/entitlement.dart';

abstract interface class SubscriptionRepository {
  Future<Entitlement> entitlement(String creator);
  Future<Entitlement> subscribe(String creator);
  Future<void> donate(String creator, int amount);
}
