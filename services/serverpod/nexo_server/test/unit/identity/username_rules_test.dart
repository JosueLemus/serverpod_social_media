import 'package:nexo_server/src/modules/identity/services/username_rules.dart';
import 'package:test/test.dart';

void main() {
  group('suggestFrom', () {
    test('uses the local part of an email, without accents or dots', () {
      expect(UsernameRules.suggestFrom('María.José@example.com'), 'maria_jose');
    });

    test('pads a too-short base instead of producing an invalid one', () {
      expect(UsernameRules.suggestFrom('al@x.com'), 'usuario_al');
      expect(UsernameRules.suggestFrom(null), 'usuario');
    });

    test('never suggests a reserved name', () {
      expect(UsernameRules.suggestFrom('admin@nexo.com'), isNot('admin'));
    });

    test('leaves room for a numeric suffix', () {
      final base = UsernameRules.suggestFrom('${'a' * 40}@x.com');
      expect(base.length, lessThanOrEqualTo(UsernameRules.maxLength - 4));
    });

    test('every suggestion passes validation', () {
      for (final source in [
        'Ñandú@x.com',
        '__raro__@x.com',
        'x@y.z',
        'José Pérez',
        'admin',
      ]) {
        final base = UsernameRules.suggestFrom(source);
        expect(UsernameRules.problemWith(base), isNull, reason: source);
      }
    });
  });

  group('problemWith', () {
    test('accepts lowercase, digits and underscore', () {
      expect(UsernameRules.problemWith('elena_ux_2'), isNull);
    });

    test('rejects dots and hyphens, which read like an underscore', () {
      expect(UsernameRules.problemWith('elena.ux'), isNotNull);
      expect(UsernameRules.problemWith('elena-ux'), isNotNull);
    });
  });
}
