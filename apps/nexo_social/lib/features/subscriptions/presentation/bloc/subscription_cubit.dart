import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/entitlement.dart';
import '../../domain/repositories/subscription_repository.dart';

class SubscriptionState extends Equatable {
  const SubscriptionState({
    required this.entitlement,
    this.donationTotal = 0,
    this.selectedDonation = 5,
    this.lastDonation,
  });

  final Entitlement entitlement;
  final int donationTotal;

  /// El monto elegido en la fila de apoyo. Vive en el estado y no en el
  /// widget porque el CTA de abajo lo nombra ("Enviar donación de $5"): con un
  /// `setState` local, el botón y las pastillas serían dos fuentes de verdad.
  final int selectedDonation;

  /// Lo último enviado, para confirmarlo en pantalla. Null hasta que haya algo
  /// que confirmar — un cero se leería como una donación de cero.
  final int? lastDonation;

  SubscriptionState copyWith({
    Entitlement? entitlement,
    int? donationTotal,
    int? selectedDonation,
    int? lastDonation,
  }) => SubscriptionState(
    entitlement: entitlement ?? this.entitlement,
    donationTotal: donationTotal ?? this.donationTotal,
    selectedDonation: selectedDonation ?? this.selectedDonation,
    lastDonation: lastDonation ?? this.lastDonation,
  );

  // Todos los campos listados. Una clase de estado sin igualdad por valor hace
  // que cada emit parezca un cambio, y una que lista sólo algunos campos hace
  // que un cambio real parezca ninguno — el segundo es el silencioso.
  @override
  List<Object?> get props => [
    entitlement,
    donationTotal,
    selectedDonation,
    lastDonation,
  ];
}

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit(this._repository, String creator)
    : super(
        SubscriptionState(
          entitlement: Entitlement(creator: creator, active: false),
        ),
      );

  final SubscriptionRepository _repository;

  /// Los montos de apoyo rápido. En el dominio del cubit y no del widget: son
  /// una decisión de producto, no de layout.
  static const donationAmounts = [2, 5, 10];

  Future<void> load() async => emit(
    state.copyWith(
      entitlement: await _repository.entitlement(state.entitlement.creator),
    ),
  );

  Future<void> subscribe() async => emit(
    state.copyWith(
      entitlement: await _repository.subscribe(state.entitlement.creator),
    ),
  );

  void selectDonation(int amount) =>
      emit(state.copyWith(selectedDonation: amount));

  Future<void> donate() async {
    final amount = state.selectedDonation;
    await _repository.donate(state.entitlement.creator, amount);
    emit(
      state.copyWith(
        donationTotal: state.donationTotal + amount,
        lastDonation: amount,
      ),
    );
  }
}
