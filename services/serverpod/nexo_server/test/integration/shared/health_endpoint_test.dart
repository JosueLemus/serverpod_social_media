import 'package:test/test.dart';

import '../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Health endpoint', (sessionBuilder, endpoints) {
    test('when calling ping then returns ok', () async {
      expect(await endpoints.health.ping(sessionBuilder), 'ok');
    });
  });
}
