import 'dart:io';

import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';
import 'package:serverpod_cloud_storage/serverpod_cloud_storage.dart';

import 'src/generated/serverpod.dart';
import 'src/shared/demo/demo_seed.dart';

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  // Initialize Serverpod. The generated Serverpod class is already connected
  // with your project's generated code.
  final pod = Serverpod(args);

  // Initialize authentication services for the server.
  // Token managers will be used to validate and issue authentication keys,
  // and the identity providers will be the authentication options available for users.
  pod.initializeAuthServices(
    tokenManagerBuilders: [
      // Use JWT for authentication keys towards the server.
      JwtConfigFromPasswords(),
    ],
    identityProviderBuilders: [
      // Configure the email identity provider for email/password authentication.
      // The default setup works with Serverpod Cloud without configuration. In
      // development the verification codes are logged to the console, and in
      // staging and production they are sent through the Serverpod Cloud email
      // service. If you want to use a custom provider for sending emails, use
      // `EmailIdpConfigFromPasswords`.
      ServerpodCloudEmailIdpConfig(
        appDisplayName: 'Nexo Social',
      ),
    ],
  );

  // Configure cloud storage.
  // This setup works with Serverpod Cloud without extra configuration.
  // If you want to use a custom provider for cloud storage, replace these
  // with your preferred provider.
  pod.addCloudStorage(
    await ServerpodCloudProvider.private(
      fallback: () => DatabaseCloudStorage('private'),
    ),
  );
  pod.addCloudStorage(
    await ServerpodCloudProvider.public(
      fallback: () => DatabaseCloudStorage('public'),
    ),
  );

  // Start the server.
  await pod.start();

  await _seedDemoIfAsked(pod);
}

/// Siembra las cuentas y el contenido de la demo local (`tool/demo.sh`).
///
/// Sólo en desarrollo y sólo si se pide: en producción, una variable de
/// entorno nunca puede crear una cuenta con el scope `admin`.
Future<void> _seedDemoIfAsked(Serverpod pod) async {
  if (Platform.environment['NEXO_DEMO_SEED'] != '1') return;
  if (pod.runMode != ServerpodRunMode.development) {
    stderr.writeln('NEXO_DEMO_SEED ignorado: sólo se siembra en development.');
    return;
  }
  final session = await pod.createSession(enableLogging: false);
  try {
    final email = AuthServices.getIdentityProvider<EmailIdp>();
    final created = await DemoSeed(
      (session, authUserId, address, password) async {
        await email.admin.createEmailAuthentication(
          session,
          authUserId: authUserId,
          email: address,
          password: password,
        );
      },
    ).run(session);
    stdout.writeln(
      created == 0
          ? 'Demo: las cuentas ya estaban sembradas.'
          : 'Demo: $created cuentas sembradas. Contraseña: '
                '${DemoSeed.password}',
    );
  } finally {
    await session.close();
  }
}
