import 'package:nexo_server/src/modules/search/services/search_rules.dart';
import 'package:test/test.dart';

void main() {
  group('SearchRules', () {
    test('normalize trims, lowercases and drops the leading @ or #', () {
      expect(SearchRules.normalize('  @Elena   Vega '), 'elena vega');
      expect(SearchRules.normalize('##FlutterDev'), 'flutterdev');
      expect(SearchRules.normalize('@ ana'), 'ana');
    });

    test('needs at least two letters', () {
      expect(SearchRules.isSearchable('a'), isFalse);
      expect(SearchRules.isSearchable('ab'), isTrue);
    });

    test('escapes LIKE wildcards and the escape itself', () {
      expect(SearchRules.containsPattern(r'50%_\x'), r'%50\%\_\\x%');
    });

    test('fold drops accents, ñ and combining marks', () {
      expect(SearchRules.fold('josé'), 'jose');
      expect(SearchRules.fold('canción'), 'cancion');
      expect(SearchRules.fold('PINGÜINO Ñandú'), 'PINGuINO nandu');
      // "é" escrita como "e" + tilde combinable (NFD).
      expect(SearchRules.fold('jose\u0301'), 'jose');
      expect(SearchRules.fold('plain_50%'), 'plain_50%');
    });

    test('normalize keeps the accents; the pattern folds them', () {
      expect(SearchRules.normalize('  José '), 'josé');
      expect(SearchRules.containsPattern('josé'), '%jose%');
      expect(SearchRules.containsPattern('canción_50%'), r'%cancion\_50\%%');
    });

    test('foldSql uses the same table as fold, marks last and dropped', () {
      final sql = SearchRules.foldSql('post.body');
      final match = RegExp(
        r"^translate\(lower\(post\.body\), '([^']*)', '([^']*)'\)$",
      ).firstMatch(sql)!;
      final from = match.group(1)!.runes.toList();
      final to = match.group(2)!.runes.toList();
      expect(from.length, greaterThan(to.length));
      for (var i = 0; i < from.length; i++) {
        final char = String.fromCharCode(from[i]);
        final expected = i < to.length ? String.fromCharCode(to[i]) : '';
        expect(SearchRules.fold(char), expected, reason: char);
      }
    });

    test('a prefix match ignores accents', () {
      expect(SearchRules.isPrefixMatch('jose', ['jp', 'José Pérez']), isTrue);
      expect(SearchRules.isPrefixMatch('pérez', ['jp', 'Jose Perez']), isTrue);
    });

    test('limit defaults to 10 and is capped at 20', () {
      expect(SearchRules.limit(null), 10);
      expect(SearchRules.limit(0), 1);
      expect(SearchRules.limit(99), 20);
    });

    test('a prefix of any word counts as starting with the text', () {
      expect(
        SearchRules.isPrefixMatch('veg', ['elena_ux', 'Elena Vega']),
        isTrue,
      );
      expect(SearchRules.isPrefixMatch('ux', ['elena_ux', null]), isTrue);
      expect(
        SearchRules.isPrefixMatch('len', ['elena_ux', 'Elena Vega']),
        isFalse,
      );
    });
  });
}
