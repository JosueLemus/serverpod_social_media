import '../bloc/schedule_show_cubit.dart';

extension ScheduleShowIssueCopy on ScheduleShowIssue {
  String get message => switch (this) {
    ScheduleShowIssue.notVerified =>
      'Solo las cuentas de creador verificadas pueden agendar un show.',
    ScheduleShowIssue.forbidden => 'Tu cuenta no tiene permiso para hacer esto.',
    ScheduleShowIssue.suspended => 'Tu cuenta está suspendida.',
    ScheduleShowIssue.invalid =>
      'Revisa el título y la fecha: el show tiene que ser en el futuro.',
    ScheduleShowIssue.guestNotFound => 'No encontramos a ese usuario.',
    ScheduleShowIssue.guestIsHost =>
      'Ya eres el host de este show; invita a otra persona.',
    ScheduleShowIssue.guestUnavailable =>
      'Esa cuenta no puede participar en vivos ahora mismo.',
    ScheduleShowIssue.guestLimit =>
      'Llegaste al máximo de ${ShowDraft.maxGuests} invitados.',
    ScheduleShowIssue.other =>
      'No pudimos completar la acción. Inténtalo de nuevo.',
  };
}

extension ShowDraftIssueCopy on ShowDraftIssue {
  String get hint => switch (this) {
    ShowDraftIssue.titleMissing => 'Ponle un título a tu show para agendarlo.',
    ShowDraftIssue.titleTooLong =>
      'El título supera los ${ShowDraft.maxTitleLength} caracteres.',
    ShowDraftIssue.startInPast => 'Elige una fecha y hora en el futuro.',
    ShowDraftIssue.tooManyGuests =>
      'Máximo ${ShowDraft.maxGuests} invitados por show.',
  };
}

extension ShowAccessCopy on ShowAccess {
  String get label => switch (this) {
    ShowAccess.public => 'Público Abierto',
    ShowAccess.members => 'Solo Miembros Pro',
  };
}
