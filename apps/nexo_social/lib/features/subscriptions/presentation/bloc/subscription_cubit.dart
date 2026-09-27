import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/entitlement.dart';
import '../../domain/repositories/subscription_repository.dart';

class SubscriptionState {
  const SubscriptionState({required this.entitlement, this.donationTotal = 0});
  final Entitlement entitlement;
  final int donationTotal;
  SubscriptionState copyWith({Entitlement? entitlement, int? donationTotal}) =>
      SubscriptionState(
        entitlement: entitlement ?? this.entitlement,
        donationTotal: donationTotal ?? this.donationTotal,
      );
}

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit(this._repository, String creator)
    : super(
        SubscriptionState(
          entitlement: Entitlement(creator: creator, active: false),
        ),
      );
  final SubscriptionRepository _repository;
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
  Future<void> donate(int amount) async {
    await _repository.donate(state.entitlement.creator, amount);
    emit(state.copyWith(donationTotal: state.donationTotal + amount));
  }
}
