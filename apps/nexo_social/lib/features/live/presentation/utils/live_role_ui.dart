import '../../domain/entities/live_session.dart';

/// Cómo se nombra cada rol en pantalla. El contrato dice `cohost`; la copy
/// dice "Invitado" (SDD 0011, S2). Un enum nunca se pinta con `.name`.
extension LiveRoleUI on LiveRole {
  String get label => switch (this) {
    LiveRole.host => 'Host',
    LiveRole.moderator => 'Moderador',
    LiveRole.cohost => 'Invitado',
    LiveRole.audience => 'Oyente',
  };
}
