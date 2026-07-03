import '../../../search/domain/entities/thumbnail.dart' show Thumbnail;
import 'playlist_author.dart' show PlaylistAuthor;
import 'playlist_track.dart' show PlaylistTrack;

/// Entidad del dominio para la respuesta de una playlist
class PlaylistResponse {
  final bool owned;
  final String id;
  final String privacy;
  final String description;
  final int views;
  final String duration;
  final int trackCount;
  final String title;
  final List<Thumbnail> thumbnails;
  final PlaylistAuthor author;
  final String year;
  final List<dynamic> related;
  final List<PlaylistTrack> tracks;
  final int durationSeconds;

  const PlaylistResponse({
    required this.owned,
    required this.id,
    required this.privacy,
    required this.description,
    required this.views,
    required this.duration,
    required this.trackCount,
    required this.title,
    required this.thumbnails,
    required this.author,
    required this.year,
    required this.related,
    required this.tracks,
    required this.durationSeconds,
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Verifica si la lista de reproducción tiene canciones asignadas
  bool get hasTracks => tracks.isNotEmpty;

  /// Verifica si la privacidad está configurada como 'privada'
  bool get isPrivate => privacy.toLowerCase() == 'private';

  /// Verifica si la lista cuenta con descripción
  bool get hasDescription => description.trim().isNotEmpty;

  /// Obtiene la miniatura de mejor calidad (la última del array usualmente)
  String? get bestThumbnail => thumbnails.isNotEmpty ? thumbnails.last.url : null;
}
