/// Entity representing an artist
///
/// @deprecated Usar [Artist] desde `core/domain/entities/artist.dart`
/// Esta entidad será eliminada en futuras versiones.
@Deprecated('Usar Artist desde core/domain/entities/artist.dart')
class Artist {
  final String id;
  final String name;
  final String? thumbnail;
  final int? monthlyListeners;
  final String? description;
  final List<ArtistSong> topSongs;
  final List<ArtistAlbum> albums;

  const Artist({
    required this.id,
    required this.name,
    this.thumbnail,
    this.monthlyListeners,
    this.description,
    this.topSongs = const [],
    this.albums = const [],
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Verifica si existe una biografía o descripción textual del artista
  bool get hasDescription => description != null && description!.trim().isNotEmpty;

  /// Indica si el perfil cuenta con las canciones más populares
  bool get hasTopSongs => topSongs.isNotEmpty;

  /// Indica si la discografía del artista se ha renderizado/descargado
  bool get hasAlbums => albums.isNotEmpty;

  String get bestThumbnail => thumbnail ?? '';
}

/// Simplified song from an artist
class ArtistSong {
  final String videoId;
  final String title;
  final String? thumbnail;
  final int durationSeconds;
  final int views;
  final String? streamUrl;

  const ArtistSong({
    required this.videoId,
    required this.title,
    required this.durationSeconds,
    this.thumbnail,
    this.views = 0,
    this.streamUrl,
  });

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Album from an artist
class ArtistAlbum {
  final String id;
  final String title;
  final String? thumbnail;
  final int year;
  final int songCount;

  const ArtistAlbum({
    required this.id,
    required this.title,
    required this.year,
    required this.songCount,
    this.thumbnail,
  });
}
