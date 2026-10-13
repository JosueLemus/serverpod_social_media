import 'package:equatable/equatable.dart';

/// Una sanción dentro de una sala (SDD 0011, S10).
enum LiveSanctionKind {
  /// No escribe en el chat por un rato.
  chatMute,

  /// Fuera de este vivo.
  kick,

  /// Fuera de todos los vivos de este host.
  ban,
}

/// Cuánto dura un silencio en el chat de una sala. Un conjunto cerrado, el
/// mismo que acepta el servidor (`LiveRules.chatMuteMinutes`).
///
/// No es el `MuteDuration` de la consola: aquél silencia la cuenta en toda la
/// plataforma (15 min, 1 h, 24 h); éste, sólo en un vivo.
enum LiveMuteDuration {
  fiveMinutes(5),
  fifteenMinutes(15),
  oneHour(60),

  /// Hasta que termine el vivo.
  restOfLive(null);

  const LiveMuteDuration(this.minutes);

  /// Null: el resto del vivo.
  final int? minutes;
}

/// El silencio vigente de quien mira. [until] null: hasta que termine el vivo.
class LiveChatMute extends Equatable {
  const LiveChatMute({this.until});

  final DateTime? until;

  bool activeAt(DateTime now) => until == null || until!.isAfter(now);

  @override
  List<Object?> get props => [until];
}
