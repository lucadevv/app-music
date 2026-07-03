import '../../../../core/domain/entities/playable_audio.dart';
import '../../../search/domain/entities/album.dart' show SearchAlbum;
import '../../../search/domain/entities/artist.dart' show SearchArtist;
import '../../../search/domain/entities/thumbnail.dart' show Thumbnail;

/// Entidad del dominio para una canción en una playlist
class PlaylistTrack implements PlayableAudio {
  // --------- PlayableAudio Mappers ---------
  @override
  String get id => videoId ?? '';

  @override
  String get artist => artists.isNotEmpty ? artists.first.name : 'Unknown Artist';

  @override
  Duration get audioDuration => Duration(seconds: durationSeconds);

  @override
  String? get bestThumbnail => thumbnail?.url ?? (thumbnails.isNotEmpty ? thumbnails.last.url : null);

  @override
  bool get canPlay => streamUrl != null && streamUrl!.isNotEmpty;
  
  @override
  final String title;
  
  @override
  final String? streamUrl;
  // -----------------------------------------

  final String? videoId;
  final List<SearchArtist> artists;
  final SearchAlbum? album;
  final String? likeStatus;
  final bool? inLibrary;
  final bool? pinnedToListenAgain;
  final List<Thumbnail> thumbnails;
  final bool isAvailable;
  final bool isExplicit;
  final String? videoType;
  final String? views;
  final String duration;
  final int durationSeconds;
  
  // Thumbnail de mejor calidad (viene junto con stream_url)
  final Thumbnail? thumbnail;

  const PlaylistTrack({
    required this.title,
    required this.artists,
    required this.thumbnails,
    required this.isAvailable,
    required this.isExplicit,
    required this.duration,
    required this.durationSeconds,
    this.videoId,
    this.album,
    this.likeStatus,
    this.inLibrary,
    this.pinnedToListenAgain,
    this.videoType,
    this.views,
    this.streamUrl,
    this.thumbnail,
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Indica si hay múltiples artistas involucrados
  bool get hasMultipleArtists => artists.length > 1;

  /// Indica si el track pertenece a un álbum concreto y válido
  bool get hasAlbum => album != null && album!.name.trim().isNotEmpty && album!.name.toLowerCase() != 'unknown';

  /// Retorna un string con todos los artistas separados por coma
  String get allArtistsNames => artists.map((a) => a.name).join(', ');

  /// Indica si la canción está explícitamente marcada como 'Explicit'
  bool get isExplicitContent => isExplicit;

  /// Método de Dominio: Retorna true si este track hace match con un string de búsqueda.
  bool matchesQuery(String query) {
    if (query.trim().isEmpty) return true;
    final lowerQuery = query.toLowerCase();

    final matchesTitle = title.toLowerCase().contains(lowerQuery);
    final matchesArtist = artists.any(
      (a) => a.name.toLowerCase().contains(lowerQuery),
    );

    return matchesTitle || matchesArtist;
  }
}
