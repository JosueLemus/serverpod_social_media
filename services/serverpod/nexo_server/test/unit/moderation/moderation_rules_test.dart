import 'package:nexo_server/src/generated/protocol.dart';
import 'package:nexo_server/src/modules/moderation/services/moderation_rules.dart';
import 'package:test/test.dart';

void main() {
  group('Given ModerationRules.severityOf', () {
    test('when the reason can harm someone then severity is high', () {
      for (final reason in [
        ModerationReason.harassment,
        ModerationReason.hateSpeech,
        ModerationReason.violence,
        ModerationReason.sexualContent,
      ]) {
        expect(
          ModerationRules.severityOf(reason),
          ReportSeverity.high,
          reason: reason.name,
        );
      }
    });

    test(
      'when the reason is spam or impersonation then severity is medium',
      () {
        expect(
          ModerationRules.severityOf(ModerationReason.spam),
          ReportSeverity.medium,
        );
        expect(
          ModerationRules.severityOf(ModerationReason.impersonation),
          ReportSeverity.medium,
        );
      },
    );

    test('when the reason is other then severity is low', () {
      expect(
        ModerationRules.severityOf(ModerationReason.other),
        ReportSeverity.low,
      );
    });
  });

  group('Given ModerationRules.excerpt', () {
    test('when text is short then keeps it whole', () {
      expect(ModerationRules.excerpt('hola'), 'hola');
    });

    test('when text is long then cuts it with an ellipsis', () {
      final excerpt = ModerationRules.excerpt('a' * 1000);

      expect(excerpt.length, ModerationRules.excerptLength);
      expect(excerpt.endsWith('…'), isTrue);
    });
  });
}
