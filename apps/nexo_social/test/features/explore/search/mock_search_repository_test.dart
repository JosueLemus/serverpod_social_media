import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/features/explore/data/repositories/mock_search_repository.dart';

void main() {
  group('MockSearchRepository.fold', () {
    test('drops accents, ñ and combining marks like the server', () {
      expect(MockSearchRepository.fold('josé'), 'jose');
      expect(MockSearchRepository.fold('canción'), 'cancion');
      expect(MockSearchRepository.fold('pingüino ñandú'), 'pinguino nandu');
      // "é" escrita como "e" + tilde combinable (NFD).
      expect(MockSearchRepository.fold('jose\u0301'), 'jose');
      expect(MockSearchRepository.fold('plain_50%'), 'plain_50%');
    });

    test('normalize keeps the accents: the results say what was typed', () {
      expect(MockSearchRepository.normalize('  @José '), 'josé');
    });
  });
}
