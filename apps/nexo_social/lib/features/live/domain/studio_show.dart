import 'entities/live_session.dart';

/// Qué show abre el Studio, entre los del host en sesión.
///
/// El Studio cargaba `live-2` fijo: sólo Elena podía usarlo, y un show
/// recién programado no se podía iniciar nunca. La regla es la que esperaría
/// un host: el que está al aire primero, porque cerrar el Studio a mitad de
/// un vivo y volver tiene que devolverlo ahí; si no, el próximo programado.
///
/// [requested] es el `?show=` de la ruta. Sólo se respeta si es de este
/// host: un id ajeno en la URL no abre el panel de otra persona.
LiveSession? pickStudioShow(Iterable<LiveSession> mine, {String? requested}) {
  if (requested != null) {
    for (final live in mine) {
      if (live.id == requested) return live;
    }
  }
  for (final live in mine) {
    if (live.status == LiveStatus.live || live.status == LiveStatus.ending) {
      return live;
    }
  }
  final upcoming = [
    for (final live in mine)
      if (live.status == LiveStatus.scheduled) live,
  ];
  if (upcoming.isEmpty) return null;
  // Sin fecha va al final: un show sin hora no es el "próximo" de nadie.
  upcoming.sort((a, b) {
    final left = a.scheduledAt;
    final right = b.scheduledAt;
    if (left == null && right == null) return 0;
    if (left == null) return 1;
    if (right == null) return -1;
    return left.compareTo(right);
  });
  return upcoming.first;
}
