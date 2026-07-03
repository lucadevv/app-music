// ignore_for_file: deprecated_member_use_from_same_package
import 'song.dart';

/// Entidad del dominio para la respuesta de búsqueda
class SearchResponse {
  final List<Song> results;
  final String query;

  // Campos adicionales para paginación
  final List<dynamic> albums;
  final List<dynamic> artists;

  const SearchResponse({
    required this.results,
    required this.query,
    this.albums = const [],
    this.artists = const [],
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Verifica si la respuesta arrojó algún tipo de resultado (canción, álbum o artista)
  bool get hasAnyResults => results.isNotEmpty || albums.isNotEmpty || artists.isNotEmpty;

  /// Verifica si la respuesta contiene exclusivamente canciones
  bool get isOnlySongs => results.isNotEmpty && albums.isEmpty && artists.isEmpty;

  /// Obtiene la cantidad total de elementos encontrados
  int get totalResultsCount => results.length + albums.length + artists.length;
}
