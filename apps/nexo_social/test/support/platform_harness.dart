import 'package:nexo_social/core/mock/mock_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un [MockPlatform] recién sembrado, con la sesión de [accountId].
///
/// Sobre preferencias en memoria: `SharedPreferences.getInstance()` sólo
/// completa en un test si antes se sembraron valores de mentira.
Future<MockPlatform> platformAs(
  String? accountId, {
  DateTime Function()? now,
}) async {
  SharedPreferences.setMockInitialValues({});
  final platform = MockPlatform(await SharedPreferences.getInstance(), now: now)
    ..bindSession(accountId);
  return platform;
}
