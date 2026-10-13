import '../entities/entitlement.dart';

abstract interface class SubscriptionRepository {
  Future<Entitlement> entitlement(String creator);
  Future<Entitlement> subscribe(String creator);

  /// [message] es el mensaje de aliento opcional que acompaña la donación.
  Future<void> donate(String creator, int amount, {String? message});

  /// Emite cuando cambia una membresía, para que el perfil del creador
  /// desbloquee su pestaña Premium sin recargar.
  Stream<void> changes();
}
