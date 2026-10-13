import '../entities/search_results.dart';

/// El buscador de Explorar. Con menos de dos letras devuelve todo vacío: el
/// servidor no busca y la app no tiene que adivinar cuándo hacerlo.
abstract interface class SearchRepository {
  Future<SearchResults> search(String text);
}
