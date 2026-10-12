import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';
import 'package:nexo_server/src/shared/gateways/email/email_sender.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

/// Credenciales de mentira: los tests nunca mandan correos de verdad.
const _secret = 'app-password-que-no-se-loguea';

const _smtp = {
  'smtpHost': 'smtp.gmail.com',
  'smtpUser': 'nexo.demo@gmail.com',
  'smtpPassword': _secret,
};

void main() {
  const email = VerificationEmail(
    to: 'tomas@nexo.demo',
    code: 'ab12cd34',
    purpose: VerificationPurpose.registration,
    validFor: Duration(minutes: 15),
  );

  group('Given the secrets and the run mode', () {
    test('then development always logs, even with SMTP configured', () {
      expect(
        emailSenderFrom(_smtp, runMode: ServerpodRunMode.development),
        isA<LogEmailSender>(),
      );
    });

    test('then staging with full SMTP credentials sends by SMTP', () {
      final sender = emailSenderFrom(_smtp, runMode: ServerpodRunMode.staging);

      expect(sender, isA<SmtpEmailSender>());
      sender as SmtpEmailSender;
      expect(sender.port, 587);
      expect(sender.from, 'nexo.demo@gmail.com');
      expect(sender.fromName, 'Nexo');
    });

    test('then a missing credential falls back to the log', () {
      final sender = emailSenderFrom({
        'smtpHost': 'smtp-relay.brevo.com',
        'smtpUser': 'nexo@example.com',
      }, runMode: ServerpodRunMode.production);

      expect(sender, isA<LogEmailSender>());
    });

    test('then port, sender address and name come from the secrets', () {
      final sender =
          emailSenderFrom({
                ..._smtp,
                'smtpHost': 'smtp-relay.brevo.com',
                'smtpPort': '465',
                'smtpFrom': 'hola@nexo.example',
                'smtpFromName': 'Nexo Social',
              }, runMode: ServerpodRunMode.staging)
              as SmtpEmailSender;

      expect(sender.host, 'smtp-relay.brevo.com');
      expect(sender.port, 465);
      expect(sender.from, 'hola@nexo.example');
      expect(sender.fromName, 'Nexo Social');
    });
  });

  group('Given an SMTP password', () {
    test('then the Gmail app password loses the spaces Google shows', () {
      expect(
        normalizeSmtpPassword(
          host: 'smtp.gmail.com',
          password: 'abcd efgh ijkl mnop',
        ),
        'abcdefghijklmnop',
      );
    });

    test('then another provider keeps the password untouched', () {
      expect(
        normalizeSmtpPassword(
          host: 'smtp-relay.brevo.com',
          password: 'clave con espacio',
        ),
        'clave con espacio',
      );
    });

    test('then a Gmail password with only spaces counts as missing', () {
      final sender = emailSenderFrom({
        'smtpHost': 'smtp.gmail.com',
        'smtpUser': 'nexo@gmail.com',
        'smtpPassword': '    ',
      }, runMode: ServerpodRunMode.staging);
      expect(sender, isA<LogEmailSender>());
    });
  });

  group('Given the copy of the email', () {
    test('then it says what the code is for and when it expires', () {
      expect(email.subject, 'Tu código de Nexo');
      expect(email.text, contains('confirmar tu cuenta'));
      expect(email.text, contains('ab12cd34'));
      expect(email.text, contains('Vence en 15 minutos.'));
      expect(email.html, contains('ab12cd34'));

      const reset = VerificationEmail(
        to: 'tomas@nexo.demo',
        code: 'zz99',
        purpose: VerificationPurpose.passwordReset,
        validFor: Duration(minutes: 15),
      );
      expect(reset.text, contains('restablecer tu contraseña'));
    });
  });

  group('Given the log sender', () {
    test('then the code goes to the log, marked as copyable', () async {
      final lines = <String>[];
      await const LogEmailSender().send(email, log: lines.add);

      expect(lines.single, 'Registration code for tomas@nexo.demo: <ab12cd34>');
    });
  });

  group('Given the SMTP sender', () {
    SmtpEmailSender sender(
      Future<void> Function(mailer.Message, SmtpServer) transport,
    ) => SmtpEmailSender(
      host: 'smtp.gmail.com',
      port: 587,
      username: 'nexo.demo@gmail.com',
      password: _secret,
      from: 'nexo.demo@gmail.com',
      transport: transport,
    );

    test('then it builds the message and logs without secrets', () async {
      late mailer.Message sent;
      late SmtpServer server;
      final lines = <String>[];

      await sender((message, smtp) async {
        sent = message;
        server = smtp;
      }).send(email, log: lines.add);

      expect(sent.recipients, ['tomas@nexo.demo']);
      expect(sent.subject, 'Tu código de Nexo');
      expect(sent.html, contains('ab12cd34'));
      expect(server.host, 'smtp.gmail.com');
      expect(server.ssl, isFalse, reason: '587 sube con STARTTLS');
      expect(lines.join('\n'), isNot(contains(_secret)));
      expect(lines.join('\n'), isNot(contains('ab12cd34')));
    });

    test(
      'then a failure is logged without the password and never thrown',
      () async {
        final lines = <String>[];

        await sender((_, _) async {
          throw StateError('535 auth failed for $_secret');
        }).send(email, log: lines.add);

        expect(lines.single, startsWith('Failed to send verification email'));
        expect(lines.single, isNot(contains(_secret)));
      },
    );
  });
}
