// ignore_for_file: deprecated_member_use_from_same_package
import 'package:equatable/equatable.dart';

// Importaciones del núcleo polimórfico
import 'package:music_app/core/domain/entities/playable_audio.dart';

import 'package:music_app/core/domain/entities/song.dart';
import 'package:music_app/features/playlist/domain/entities/playlist_track.dart';
import 'package:music_app/features/search/domain/entities/album.dart'
    as search_album;
import 'package:music_app/features/search/domain/entities/artist.dart'
    as search_artist;
import 'package:music_app/features/search/domain/entities/song.dart' as search;
import 'package:music_app/features/search/domain/entities/thumbnail.dart'
    as search_thumb;

/// Entidad genérica para datos de reproducción actual
/// Puede ser construida desde Song o con datos individuales
///
/// Esta entidad sigue el principio de Single Responsibility (SOLID):
/// - Responsable única: Representar los datos necesarios para reproducir una canción
/// - Inmutable: Todos los campos son final para garantizar inmutabilidad
/// - Reutilizable: Puede construirse desde diferentes fuentes (Song, datos básicos)
class NowPlayingData extends Equatable implements PlayableAudio {
  // --------- PlayableAudio Mappers ---------
  @override
  String get id => videoId;

  @override
  String get artist => artistsNames;

  @override
  Duration get audioDuration => Duration(seconds: durationSeconds);

  @override
  bool get canPlay => streamUrl != null && streamUrl!.isNotEmpty;
  // -----------------------------------------

  final String videoId;
  
  @override
  final String title;
  
  final List<search_artist.SearchArtist> artists;
  final search_album.SearchAlbum album;
  final String duration;
  final int durationSeconds;
  final String views;
  final bool isExplicit;
  final bool inLibrary;
  final List<search_thumb.Thumbnail> thumbnails;
  
  @override
  final String? streamUrl; // URL de streaming (viene del endpoint con include_stream_urls=true)
  final search_thumb.Thumbnail?
  thumbnail; // Thumbnail de mejor calidad (viene junto con stream_url)

  const NowPlayingData({
    required this.videoId,
    required this.title,
    required this.artists,
    required this.album,
    required this.duration,
    required this.durationSeconds,
    required this.views,
    required this.isExplicit,
    required this.inLibrary,
    required this.thumbnails,
    this.streamUrl,
    this.thumbnail,
  });

  /// Constructor desde Song canónico (core/domain/entities/song.dart)
  factory NowPlayingData.fromCanonicalSong(Song song) {
    final thumbnails = song.thumbnails
        .map(
          (t) => search_thumb.Thumbnail(
            url: t.url,
            width: t.width,
            height: t.height,
          ),
        )
        .toList();

    search_thumb.Thumbnail? bestThumb;
    if (song.highThumbnail != null) {
      bestThumb = search_thumb.Thumbnail(
        url: song.highThumbnail!,
        width: 544,
        height: 544,
      );
    } else if (song.thumbnail != null) {
      bestThumb = search_thumb.Thumbnail(
        url: song.thumbnail!,
        width: 544,
        height: 544,
      );
    } else if (thumbnails.isNotEmpty) {
      bestThumb = thumbnails.last;
    }

    return NowPlayingData(
      videoId: song.videoId,
      title: song.title,
      artists: song.artistNames
          .map((name) => search_artist.SearchArtist(name: name, id: ''))
          .toList(),
      album: search_album.SearchAlbum(
        name: song.album ?? 'Unknown Album',
        id: '',
      ),
      duration: song.duration,
      durationSeconds: song.durationSeconds,
      views: song.views ?? '0',
      isExplicit: song.isExplicit,
      inLibrary: song.inLibrary,
      thumbnails: thumbnails,
      streamUrl: song.streamUrl,
      thumbnail: bestThumb,
    );
  }

  /// Constructor desde Song (search.Song - deprecated, usar fromCanonicalSong)
  @Deprecated('Usar NowPlayingData.fromCanonicalSong(Song) en su lugar')
  factory NowPlayingData.fromSong(search.Song song) {
    // Map search.Song properties to now_playing_data types
    final searchThumbnails = song.thumbnails
        .map(
          (t) => search_thumb.Thumbnail(
            url: t.url,
            width: t.width ?? 0,
            height: t.height ?? 0,
          ),
        )
        .toList();

    search_thumb.Thumbnail? bestThumb;
    if (song.thumbnail != null) {
      bestThumb = search_thumb.Thumbnail(
        url: song.thumbnail!.url,
        width: song.thumbnail!.width ?? 0,
        height: song.thumbnail!.height ?? 0,
      );
    } else if (searchThumbnails.isNotEmpty) {
      bestThumb = searchThumbnails.last;
    }

    return NowPlayingData(
      videoId: song.videoId,
      title: song.title,
      artists: song.artists
          .map((a) => search_artist.SearchArtist(id: a.id, name: a.name))
          .toList(),
      album: search_album.SearchAlbum(id: song.album.id, name: song.album.name),
      duration: song.duration,
      durationSeconds: song.durationSeconds,
      views: song.views,
      isExplicit: song.isExplicit,
      inLibrary: song.inLibrary,
      thumbnails: searchThumbnails,
      streamUrl: song.streamUrl,
      thumbnail: bestThumb,
    );
  }

  /// Constructor desde PlaylistTrack
  factory NowPlayingData.fromPlaylistTrack(PlaylistTrack track) {
    // Si no hay videoId, usar un valor por defecto (no debería pasar en producción)
    final videoId = track.videoId ?? 'unknown';

    // Crear un SearchAlbum si no existe
    final album =
        track.album ??
        const search_album.SearchAlbum(name: 'Unknown Album', id: '');

    return NowPlayingData(
      videoId: videoId,
      title: track.title,
      artists: track.artists,
      album: album,
      duration: track.duration,
      durationSeconds: track.durationSeconds,
      views: track.views ?? '0',
      isExplicit: track.isExplicit,
      inLibrary: track.inLibrary ?? false,
      thumbnails: track.thumbnails,
      streamUrl: track.streamUrl,
      thumbnail:
          track.thumbnail, // Usar thumbnail de mejor calidad si está disponible
    );
  }

  /// Constructor con datos básicos (para casos donde no tenemos Song completo)
  factory NowPlayingData.fromBasic({
    required String videoId,
    required String title,
    required List<String> artistNames,
    required String albumName,
    required String duration,
    String? albumId,
    int? durationSeconds,
    String views = '0',
    bool isExplicit = false,
    bool inLibrary = false,
    List<String>? thumbnailUrls,
    List<search_thumb.Thumbnail>?
    thumbnails, // Lista de thumbnails con dimensiones reales
    String?
    streamUrl, // URL de streaming (viene del endpoint con include_stream_urls=true)
    String? thumbnailUrl, // Thumbnail de mejor calidad (URL string - fallback)
    search_thumb.Thumbnail?
    thumbnail, // Thumbnail de mejor calidad (objeto completo con dimensiones reales)
  }) {
    // Priorizar thumbnail completo si está disponible, luego thumbnailUrl, luego thumbnails
    final bestThumbnail =
        thumbnail ??
        (thumbnailUrl != null
            ? search_thumb.Thumbnail(
                url: thumbnailUrl,
                width: 544,
                height: 544,
              ) // Dimensiones típicas de mejor calidad
            : null);

    // Crear lista de thumbnails: priorizar thumbnails con dimensiones reales
    final thumbnailsList =
        thumbnails ??
        (thumbnailUrl != null
            ? [
                search_thumb.Thumbnail(
                  url: thumbnailUrl,
                  width: 544,
                  height: 544,
                ),
              ]
            : (thumbnailUrls
                      ?.map(
                        (url) => search_thumb.Thumbnail(
                          url: url,
                          width: 120,
                          height: 120,
                        ),
                      )
                      .toList() ??
                  []));

    return NowPlayingData(
      videoId: videoId,
      title: title,
      artists: artistNames
          .map((name) => search_artist.SearchArtist(name: name, id: ''))
          .toList(),
      album: search_album.SearchAlbum(name: albumName, id: albumId ?? ''),
      duration: duration,
      durationSeconds: durationSeconds ?? 0,
      views: views,
      isExplicit: isExplicit,
      inLibrary: inLibrary,
      thumbnails: thumbnailsList,
      streamUrl: streamUrl,
      thumbnail: bestThumbnail,
    );
  }

  /// Obtener nombres de artistas como string
  ///
  /// Utiliza un getter computado para evitar duplicación de lógica
  String get artistsNames => artists.map((a) => a.name).join(', ');

  /// Simple alias for duration in UI strings
  String get formattedDuration => duration;

  /// Obtener la mejor thumbnail disponible
  ///
  /// Prioridad:
  /// 1. thumbnail (de mejor calidad, viene con stream_url)
  /// 2. La más grande de thumbnails
  ///
  /// Retorna null si no hay thumbnails disponibles
  @override
  String? get bestThumbnail {
    // Priorizar thumbnail de mejor calidad si está disponible
    if (thumbnail != null) return thumbnail!.url;

    // Si no, usar la más grande de thumbnails
    if (thumbnails.isEmpty) return null;
    return thumbnails.last.url; // La última suele ser la más grande
  }

  /// Thumbnail de alta resolución para el Player
  ///
  /// Siempre genera maxresdefault.jpg (1280x720) desde el videoId
  /// Esto garantiza la mejor calidad en la pantalla del player
  search_thumb.Thumbnail get highResThumbnail => search_thumb.Thumbnail(
    url: 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
    width: 1280,
    height: 720,
  );

  // El método toMediaItem fue extraído a lib/core/services/media_item_mapper.dart
  // para cumplir con la Regla de Dependencia de Clean Architecture.

  /// Convierte NowPlayingData a Song canónico
  ///
  /// Útil para pasar datos a use cases que requieren Song
  Song toSong() {
    return Song(
      videoId: videoId,
      title: title,
      artist: artists.isNotEmpty ? artists.first.name : 'Unknown Artist',
      artistNames: artists.map((a) => a.name).toList(),
      album: album.name,
      thumbnail: bestThumbnail,
      highThumbnail: bestThumbnail,
      thumbnails: thumbnails
          .map((t) => Thumbnail(url: t.url, width: t.width, height: t.height))
          .toList(),
      streamUrl: streamUrl,
      durationSeconds: durationSeconds,
      duration: duration,
      views: views,
      isExplicit: isExplicit,
      inLibrary: inLibrary,
    );
  }

  /// Verifica si tiene información completa
  ///
  /// Útil para validar que la entidad tiene todos los datos necesarios
  bool get hasCompleteData {
    return videoId.isNotEmpty &&
        title.isNotEmpty &&
        artists.isNotEmpty &&
        album.name.isNotEmpty &&
        duration.isNotEmpty;
  }

  @override
  List<Object?> get props => [
    videoId,
    title,
    artists,
    album,
    duration,
    durationSeconds,
    views,
    isExplicit,
    inLibrary,
    thumbnails,
    streamUrl,
    thumbnail,
  ];
}
