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
