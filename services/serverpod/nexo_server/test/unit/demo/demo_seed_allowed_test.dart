import 'package:nexo_server/src/shared/demo/demo_seed.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

void main() {
  test('Given a run mode, then the demo seed only runs where it is safe', () {
    expect(demoSeedAllowedIn(ServerpodRunMode.development), isTrue);
    expect(demoSeedAllowedIn(ServerpodRunMode.staging), isTrue);
    // En producción una variable de entorno no puede crear un admin.
    expect(demoSeedAllowedIn(ServerpodRunMode.production), isFalse);
    expect(demoSeedAllowedIn(ServerpodRunMode.test), isFalse);
  });
}
