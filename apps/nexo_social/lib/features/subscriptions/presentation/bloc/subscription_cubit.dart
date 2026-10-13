import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../profile/domain/entities/public_profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/entities/entitlement.dart';
import '../../domain/repositories/subscription_repository.dart';

class SubscriptionState extends Equatable {
  const SubscriptionState({
    required this.entitlement,
    this.creatorProfile,
    this.donationTotal = 0,
    this.selectedDonation = 5,
    this.lastDonation,
    this.isDonating = false,
  });

  final Entitlement entitlement;

  /// El perfil del creador dueño del muro. Null mientras se lee o si no se
  /// pudo leer: la cabecera cae al nombre de usuario, que es lo único que se
  /// sabe seguro, en vez de inventar un nombre.
  final PublicProfile? creatorProfile;
  final int donationTotal;

  /// El monto elegido en la fila de apoyo. Vive en el estado y no en el
  /// widget porque el CTA de abajo lo nombra ("Enviar donación de $5"): con un
  /// `setState` local, el botón y las pastillas serían dos fuentes de verdad.
  final int selectedDonation;

  /// Lo último enviado, para confirmarlo en pantalla. Null hasta que haya algo
  /// que confirmar — un cero se leería como una donación de cero.
  final int? lastDonation;

  /// Enviando una donación. El botón se apaga mientras tanto: dos toques
  /// seguidos eran dos donaciones.
  final bool isDonating;

  SubscriptionState copyWith({
    Entitlement? entitlement,
    PublicProfile? creatorProfile,
    int? donationTotal,
    int? selectedDonation,
    int? lastDonation,
    bool? isDonating,
  }) => SubscriptionState(
    entitlement: entitlement ?? this.entitlement,
    creatorProfile: creatorProfile ?? this.creatorProfile,
    donationTotal: donationTotal ?? this.donationTotal,
    selectedDonation: selectedDonation ?? this.selectedDonation,
    lastDonation: lastDonation ?? this.lastDonation,
    isDonating: isDonating ?? this.isDonating,
  );

  // Todos los campos listados. Una clase de estado sin igualdad por valor hace
  // que cada emit parezca un cambio, y una que lista sólo algunos campos hace
  // que un cambio real parezca ninguno — el segundo es el silencioso.
  @override
  List<Object?> get props => [
    entitlement,
    creatorProfile,
    donationTotal,
    selectedDonation,
    lastDonation,
    isDonating,
  ];
}

/// El muro de membresía de [creator]: su perfil para la cabecera, si quien
/// mira ya es miembro, y las donaciones.
class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit(this._repository, String creator, [this._profiles])
    : super(
        SubscriptionState(
          entitlement: Entitlement(creator: creator, active: false),
        ),
      );

  final SubscriptionRepository _repository;
  final ProfileRepository? _profiles;

  /// Los montos de apoyo rápido. En el dominio del cubit y no del widget: son
  /// una decisión de producto, no de layout.
  static const donationAmounts = [2, 5, 10];

  String get _creator => state.entitlement.creator;

  Future<void> load() async {
    final profile = await _profileOf(_creator);
    final entitlement = await _repository.entitlement(_creator);
    if (isClosed) return;
    emit(state.copyWith(entitlement: entitlement, creatorProfile: profile));
  }

  /// Un muro sin perfil se sigue pudiendo usar: el perfil es la cabecera,
  /// no la razón de la pantalla.
  Future<PublicProfile?> _profileOf(String username) async {
    final profiles = _profiles;
    if (profiles == null) return null;
    try {
      return await profiles.byUsername(username);
    } on Failure {
      return null;
    }
  }

  Future<void> subscribe() async {
    final entitlement = await _repository.subscribe(_creator);
    if (!isClosed) emit(state.copyWith(entitlement: entitlement));
  }

  void selectDonation(int amount) =>
      emit(state.copyWith(selectedDonation: amount));

  /// Devuelve si se envió, para que la View limpie el mensaje sólo entonces:
  /// un mensaje de una donación que falló no se pierde.
  Future<bool> donate({String? message}) async {
    if (state.isDonating) return false;
    final amount = state.selectedDonation;
    final text = message?.trim();
    emit(state.copyWith(isDonating: true));
    try {
      await _repository.donate(
        _creator,
        amount,
        message: (text == null || text.isEmpty) ? null : text,
      );
      if (isClosed) return true;
      emit(
        state.copyWith(
          donationTotal: state.donationTotal + amount,
          lastDonation: amount,
          isDonating: false,
        ),
      );
      return true;
    } on Failure {
      if (!isClosed) emit(state.copyWith(isDonating: false));
      return false;
    }
  }
}
