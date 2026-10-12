import 'dart:io';

import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';
import 'package:serverpod_cloud_storage/serverpod_cloud_storage.dart';

import 'src/generated/serverpod.dart';
import 'src/shared/demo/demo_seed.dart';
import 'src/shared/gateways/email/email_sender.dart';

/// Cuánto vale un código de verificación. Es el default de Serverpod, escrito
/// acá porque el correo le dice al usuario cuándo vence.
const _codeLifetime = Duration(minutes: 15);

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
    identityProviderBuilders: [_emailIdpConfig(pod)],
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

/// Email y contraseña, con los códigos por SMTP (SDD 0009, H6).
///
/// No se usa `ServerpodCloudEmailIdpConfig`: fuera de Serverpod Cloud su
/// envío no llega a nadie. Con `smtpHost`, `smtpUser` y `smtpPassword` en los
/// secretos sale por SMTP (Gmail, Brevo…); sin ellos, y siempre en
/// desarrollo, el código va al log.
EmailIdpConfig _emailIdpConfig(Serverpod pod) {
  const smtpKeys = [
    'smtpHost',
    'smtpPort',
    'smtpUser',
    'smtpPassword',
    'smtpFrom',
    'smtpFromName',
  ];
  final sender = emailSenderFrom({
    for (final key in smtpKeys) key: ?pod.getPassword(key),
  }, runMode: pod.runMode);

  Future<void> send(
    Session session,
    String email,
    String code,
    VerificationPurpose purpose,
  ) => sender.send(
    VerificationEmail(
      to: email,
      code: code,
      purpose: purpose,
      validFor: _codeLifetime,
    ),
    log: session.alert,
  );

  return EmailIdpConfigFromPasswords(
    registrationVerificationCodeLifetime: _codeLifetime,
    passwordResetVerificationCodeLifetime: _codeLifetime,
    sendRegistrationVerificationCode:
        (
          session, {
          required email,
          required accountRequestId,
          required verificationCode,
          required transaction,
        }) => send(
          session,
          email,
          verificationCode,
          VerificationPurpose.registration,
        ),
    sendPasswordResetVerificationCode:
        (
          session, {
          required email,
          required passwordResetRequestId,
          required verificationCode,
          required transaction,
        }) => send(
          session,
          email,
          verificationCode,
          VerificationPurpose.passwordReset,
        ),
  );
}

/// Siembra las cuentas y el contenido de la demo (`tool/demo.sh` y el
/// deploy de AWS, que corre en `staging`).
///
/// Sólo si se pide y nunca en producción: ahí una variable de entorno no
/// puede crear una cuenta con el scope `admin` (ver [demoSeedAllowedIn]).
Future<void> _seedDemoIfAsked(Serverpod pod) async {
  if (Platform.environment['NEXO_DEMO_SEED'] != '1') return;
  if (!demoSeedAllowedIn(pod.runMode)) {
    stderr.writeln(
      'NEXO_DEMO_SEED ignorado: no se siembra en ${pod.runMode}, sólo en '
      'development y staging.',
    );
    return;
  }
  final session = await pod.createSession(enableLogging: false);
  try {
    final email = AuthServices.getIdentityProvider<EmailIdp>();
    final created = await DemoSeed(
      (session, authUserId, address, password, transaction) async {
        await email.admin.createEmailAuthentication(
          session,
          authUserId: authUserId,
          email: address,
          password: password,
          transaction: transaction,
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
