import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../gateways/media_storage_gateway.dart';
import '../gateways/serverpod_media_storage_gateway.dart';

/// La URL del avatar de cada cuenta en [userIds] que tenga uno. Las que no
/// tienen, no aparecen.
///
/// Una consulta por lote, como `profilesOf`: un feed con 20 autores no son
/// 20 viajes a la base.
Future<Map<UuidValue, String>> avatarsOf(
  Session session,
  Iterable<UuidValue> userIds, {
  MediaStorageGateway storage = const ServerpodMediaStorageGateway(),
}) async {
  final ids = userIds.toSet();
  if (ids.isEmpty) return const {};
  final accounts = await AccountProfile.db.find(
    session,
    where: (t) => t.authUserId.inSet(ids) & t.avatarKey.notEquals(null),
  );
  final urls = <UuidValue, String>{};
  for (final account in accounts) {
    final url = await storage.publicUrl(session, account.avatarKey!);
    if (url != null) urls[account.authUserId] = url.toString();
  }
  return urls;
}
