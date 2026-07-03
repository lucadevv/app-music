import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/playable_audio.dart';

/// Entidad del dominio para una canción en los resultados de búsqueda
///
/// Refactorizada para usar Polimorfismo (PlayableAudio) en lugar del 
/// antipatrón God Entity.
class Song implements PlayableAudio {
  // --------- PlayableAudio Mappers ---------
  @override
  String get id => videoId;

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
  final SearchAlbum album;
  final List<SearchArtist> artists;
  final String videoId;
  final String duration;
  final int durationSeconds;
  final String views;
  final bool isExplicit;
  final bool inLibrary;
  final List<Thumbnail> thumbnails;
  // URL de streaming (viene del endpoint con include_stream_urls=true)
  final Thumbnail? thumbnail; // Thumbnail de mejor calidad (viene junto con stream_url)

  const Song({
    required this.title,
    required this.album,
    required this.artists,
    required this.videoId,
    required this.duration,
    required this.durationSeconds,
    required this.views,
    required this.isExplicit,
    required this.inLibrary,
    required this.thumbnails,
    this.streamUrl,
    this.thumbnail,
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Indica si la canción pertenece a más de un artista
  bool get hasMultipleArtists => artists.length > 1;

  /// Indica si la canción pertenece a un disco con nombre válido
  bool get hasAlbum => album.name.trim().isNotEmpty && album.name.toLowerCase() != 'unknown';

  /// Retorna un string con todos los artistas separados por coma
  String get allArtistsNames => artists.map((a) => a.name).join(', ');
}

/// Entidad de álbum en búsqueda
class SearchAlbum {
  final String id;
  final String name;
  final List<SearchArtist> artists;

  const SearchAlbum({
    required this.id,
    required this.name,
    required this.artists,
  });
}

/// Entidad de artista
class SearchArtist {
  final String id;
  final String name;

  const SearchArtist({required this.id, required this.name});
}

/// Miniaturas en diferentes tamaños
class Thumbnail extends Equatable {
  final String url;
  final int? width;
  final int? height;

  const Thumbnail({required this.url, this.width, this.height});

  @override
  List<Object?> get props => [url, width, height];
}
