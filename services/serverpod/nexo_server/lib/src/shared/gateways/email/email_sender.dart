import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';
import 'package:serverpod/serverpod.dart';

/// Para qué es el código: decide el asunto y el texto del correo.
enum VerificationPurpose { registration, passwordReset }

/// Un correo con un código de verificación. Valor puro: la copy se arma acá
/// y se puede testear sin mandar nada.
class VerificationEmail {
  const VerificationEmail({
    required this.to,
    required this.code,
    required this.purpose,
    required this.validFor,
  });

  final String to;
  final String code;
  final VerificationPurpose purpose;
  final Duration validFor;

  String get subject => 'Tu código de Nexo';

  String get _reason => switch (purpose) {
    VerificationPurpose.registration => 'confirmar tu cuenta',
    VerificationPurpose.passwordReset => 'restablecer tu contraseña',
  };

  String get _expiry => 'Vence en ${validFor.inMinutes} minutos.';

  String get text =>
      'Tu código para $_reason en Nexo es: $code\n\n'
      '$_expiry\n\n'
      'Si no lo pediste, ignorá este correo: nadie puede entrar sin él.';

  String get html =>
      '<p>Tu código para $_reason en Nexo es:</p>'
      '<p style="font-size:28px;font-weight:700;letter-spacing:4px">'
      '$code</p>'
      '<p>$_expiry</p>'
      '<p style="color:#666">Si no lo pediste, ignorá este correo: nadie '
      'puede entrar sin él.</p>';
}

/// Manda los códigos de verificación de las cuentas.
///
/// [log] recibe las líneas para el operador. Nunca lleva la contraseña del
/// servidor de correo.
abstract interface class EmailSender {
  Future<void> send(
    VerificationEmail email, {
    required void Function(String line) log,
  });
}

/// Sin servidor de correo: el código va al log, como en desarrollo.
///
/// Es el modo de la demo cuando no hay credenciales SMTP: las cuentas
/// sembradas no necesitan verificarse, y una cuenta nueva lee su código en
/// el log del servidor.
class LogEmailSender implements EmailSender {
  const LogEmailSender();

  @override
  Future<void> send(
    VerificationEmail email, {
    required void Function(String line) log,
  }) async {
    final label = switch (email.purpose) {
      VerificationPurpose.registration => 'Registration',
      VerificationPurpose.passwordReset => 'Password reset',
    };
    // `<…>` lo marca como copiable en la terminal de `serverpod`.
    log('$label code for ${email.to}: <${email.code}>');
  }
}

/// Manda el correo con cualquier servidor SMTP: Gmail con contraseña de
/// aplicación, Brevo, o el que sea, elegido sólo por los secretos.
class SmtpEmailSender implements EmailSender {
  SmtpEmailSender({
    required this.host,
    required this.port,
    required this.username,
    required this._password,
    required this.from,
    this.fromName = 'Nexo',
    Future<void> Function(mailer.Message message, SmtpServer server)? transport,
  }) : _transport = transport ?? _send;

  final String host;
  final int port;
  final String username;
  final String _password;
  final String from;
  final String fromName;
  final Future<void> Function(mailer.Message message, SmtpServer server)
  _transport;

  static Future<void> _send(mailer.Message message, SmtpServer server) =>
      mailer.send(message, server, timeout: const Duration(seconds: 20));

  @override
  Future<void> send(
    VerificationEmail email, {
    required void Function(String line) log,
  }) async {
    final message = mailer.Message()
      ..from = mailer.Address(from, fromName)
      ..recipients.add(email.to)
      ..subject = email.subject
      ..text = email.text
      ..html = email.html;
    // 465 es SSL directo; 587 (y el resto) arranca en claro y sube con
    // STARTTLS, que es lo que piden Gmail y Brevo.
    final server = SmtpServer(
      host,
      port: port,
      ssl: port == 465,
      username: username,
      password: _password,
    );
    try {
      await _transport(message, server);
      log('Verification email sent to ${email.to} via $host');
    } on Object catch (error) {
      // Best effort, igual que el proveedor de Serverpod Cloud: un fallo no
      // rompe el registro, y en un reset de contraseña no revela si la
      // cuenta existe. El error no lleva la contraseña: se loguea el tipo.
      log(
        'Failed to send verification email to ${email.to} via $host '
        '(${error.runtimeType})',
      );
    }
  }
}

/// Elige cómo se mandan los códigos según el run mode y los secretos.
///
/// En desarrollo y tests, siempre al log. En el resto, SMTP si están
/// `smtpHost`, `smtpUser` y `smtpPassword`; si falta alguno, al log.
EmailSender emailSenderFrom(
  Map<String, String> passwords, {
  required String runMode,
}) {
  if (runMode == ServerpodRunMode.development ||
      runMode == ServerpodRunMode.test) {
    return const LogEmailSender();
  }
  final host = passwords['smtpHost']?.trim() ?? '';
  final user = passwords['smtpUser']?.trim() ?? '';
  final password = passwords['smtpPassword'] ?? '';
  if (host.isEmpty || user.isEmpty || password.isEmpty) {
    return const LogEmailSender();
  }
  final from = passwords['smtpFrom']?.trim() ?? '';
  final fromName = passwords['smtpFromName']?.trim() ?? '';
  return SmtpEmailSender(
    host: host,
    port: int.tryParse(passwords['smtpPort'] ?? '') ?? 587,
    username: user,
    password: password,
    from: from.isEmpty ? user : from,
    fromName: fromName.isEmpty ? 'Nexo' : fromName,
  );
}
