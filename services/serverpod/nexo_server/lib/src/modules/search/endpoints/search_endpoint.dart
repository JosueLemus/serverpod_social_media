import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../services/search_service.dart';

/// El buscador de Explorar. Desde Flutter: `client.search`.
class SearchEndpoint extends Endpoint {
  static final _search = SearchService();

  /// Cuentas, publicaciones, vivos y etiquetas que coinciden con [text].
  /// Público: un invitado también busca, y ve sólo lo que vería en el feed.
  /// Con menos de dos letras devuelve todo vacío. [limit] es por sección
  /// (10 por defecto, 20 como máximo).
  Future<SearchResults> query(Session session, String text, {int? limit}) =>
      _search.query(session, text, limit: limit);
}
