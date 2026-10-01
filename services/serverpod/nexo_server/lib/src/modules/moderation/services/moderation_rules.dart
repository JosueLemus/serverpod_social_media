import '../../../generated/protocol.dart';

/// Reglas puras de moderación.
abstract final class ModerationRules {
  static const maxDetailsLength = 500;
  static const defaultQueueSize = 50;
  static const maxQueueSize = 100;
  static const excerptLength = 280;

  /// La severidad la decide quien recibe el reporte, no quien lo manda: un
  /// cliente que elige su propia severidad pone todo en "alta". Mismo reparto
  /// que la app: primero lo que puede dañar a alguien, después el ruido.
  static ReportSeverity severityOf(ModerationReason reason) => switch (reason) {
    ModerationReason.harassment ||
    ModerationReason.hateSpeech ||
    ModerationReason.violence ||
    ModerationReason.sexualContent => ReportSeverity.high,
    ModerationReason.impersonation ||
    ModerationReason.spam => ReportSeverity.medium,
    ModerationReason.other => ReportSeverity.low,
  };

  static String excerpt(String text) => text.length <= excerptLength
      ? text
      : '${text.substring(0, excerptLength - 1)}…';
}
