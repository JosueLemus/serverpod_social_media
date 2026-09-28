import '../bloc/live_room_cubit.dart';

/// La copy de cada rechazo. Dice qué pasó con lo que la persona intentaba
/// hacer; el texto del servidor nunca se pinta.
extension LiveRoomIssueUI on LiveRoomIssue {
  String get message => switch (this) {
    LiveRoomIssue.notVerified =>
      'Tu cuenta de creador no está verificada. Solo las cuentas verificadas '
          'pueden iniciar un vivo.',
    LiveRoomIssue.forbidden => 'Tu cuenta no tiene permiso para hacer esto.',
    LiveRoomIssue.suspended => 'Tu cuenta está suspendida.',
    LiveRoomIssue.muted =>
      'Estás silenciado en este momento y no puedes comentar.',
    LiveRoomIssue.conflict =>
      'Esta acción ya no es posible desde el estado actual del vivo.',
    LiveRoomIssue.other =>
      'No pudimos completar la acción. Inténtalo de nuevo.',
  };
}
