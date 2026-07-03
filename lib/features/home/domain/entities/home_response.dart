import 'chart_playlist.dart';
import 'home_section.dart';
import 'mood_genre.dart';

/// Entidad para la respuesta completa del endpoint /api/music/explore
///
/// SOLID: Single Responsibility Principle (SRP)
/// Responsable única: Representar la respuesta del endpoint de exploración
class HomeResponse {
  final List<MoodGenre> moods;
  final List<MoodGenre> genres;
  final Charts charts;
  final List<HomeSection> sections; // Secciones de contenido (tendencias, etc.)

  const HomeResponse({
    required this.moods,
    required this.genres,
    required this.charts,
    this.sections = const [], // Opcional, por si la API no las retorna
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Indica si hay algún tipo de contenido para renderizar en el Home
  bool get hasAnyContent =>
      moods.isNotEmpty ||
      genres.isNotEmpty ||
      sections.isNotEmpty ||
      charts.topSongs.isNotEmpty ||
      charts.trending.isNotEmpty;

  /// Indica si el Home incluye contenido promocionado o secciones curadas
  bool get hasPromotedSections => sections.isNotEmpty;
}

/// Entidad para los charts (top_songs y trending)
///
/// NOTA: La API retorna playlistId (referencias a playlists), NO canciones directas.
/// Los charts son playlists populares de YouTube Music.
///
/// SOLID: Single Responsibility Principle (SRP)
/// Responsable única: Representar los charts con playlists populares
class Charts {
  final List<ChartPlaylist> topSongs;
  final List<ChartPlaylist> trending;

  const Charts({required this.topSongs, required this.trending});

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Verifica si las gráficas de popularidad están completamente vacías
  bool get isEmpty => topSongs.isEmpty && trending.isEmpty;

  /// Indica si hay nuevas tendencias para descubrir
  bool get hasTrending => trending.isNotEmpty;
}
