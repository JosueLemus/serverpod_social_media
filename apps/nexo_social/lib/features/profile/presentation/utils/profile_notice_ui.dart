import '../bloc/public_profile_cubit.dart';

extension ProfileNoticeUI on ProfileNotice {
  String get message => switch (this) {
    ProfileNotice.followFailed =>
      'No pudimos actualizar a quién sigues. Inténtalo de nuevo.',
    ProfileNotice.signInToFollow => 'Inicia sesión para seguir cuentas.',
    ProfileNotice.suspended =>
      'Tu cuenta está suspendida: no puede seguir cuentas.',
  };
}
