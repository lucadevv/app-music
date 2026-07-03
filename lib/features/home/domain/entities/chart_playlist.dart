import 'package:music_app/features/search/domain/entities/thumbnail.dart';

/// Entidad para playlists de charts
class ChartPlaylist {
  final String title;
  final String playlistId;
  final List<Thumbnail> thumbnails;

  const ChartPlaylist({
    required this.title,
    required this.playlistId,
    required this.thumbnails,
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Verifica si el ID de la lista está poblado
  bool get hasValidId => playlistId.trim().isNotEmpty;

  /// Retorna la miniatura de mejor calidad (usualmente la última)
  String? get bestThumbnail => thumbnails.isNotEmpty ? thumbnails.last.url : null;
}
