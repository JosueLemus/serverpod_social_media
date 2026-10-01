import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

/// Perfil público de cada cuenta en [userIds], para mostrar autores.
///
/// Una consulta por lote, nunca una por fila: un feed de 20 posts con 20
/// autores distintos son 20 viajes a la base si se pide de a uno.
Future<Map<UuidValue, UserProfile>> profilesOf(
  Session session,
  Iterable<UuidValue> userIds,
) async {
  final ids = userIds.toSet();
  if (ids.isEmpty) return const {};
  final profiles = await UserProfile.db.find(
    session,
    where: (t) => t.authUserId.inSet(ids),
  );
  return {for (final p in profiles) p.authUserId: p};
}
