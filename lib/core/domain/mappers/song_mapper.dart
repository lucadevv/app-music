// ignore_for_file: deprecated_member_use_from_same_package
import 'package:music_app/core/data/offline/models/offline_history.dart'
    as offline;
import 'package:music_app/core/data/offline/models/offline_song.dart'
    as offline;
import 'package:music_app/core/domain/entities/artist.dart' as artist;
import 'package:music_app/core/domain/entities/song.dart' as core;
import 'package:music_app/features/album/domain/entities/album.dart' as album;
import 'package:music_app/features/downloads/domain/entities/downloaded_song.dart';
import 'package:music_app/features/home/domain/entities/chart_playlist.dart';
import 'package:music_app/features/library/data/models/library_models.dart';
import 'package:music_app/features/library/domain/entities/library_entities.dart';
import 'package:music_app/features/player/domain/entities/now_playing_data.dart';
import 'package:music_app/features/playlist/domain/entities/playlist_track.dart';
import 'package:music_app/features/search/domain/entities/song.dart' as search;

/// Entidad para canciones reproducidas recientemente (usada en recently_played)
class RecentSong {
  final String videoId;
  final String title;
  final String artist;
  final String? thumbnail;
  final String duration;
  final int durationSeconds;
  final DateTime? playedAt;

  const RecentSong({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.duration,
    this.thumbnail,
    this.durationSeconds = 0,
    this.playedAt,
  });

  factory RecentSong.fromJson(Map<String, dynamic> json) {
    final durationStr = json['duration'] ?? '0:00';
    int durationSeconds = 0;

    try {
      final parts = durationStr.toString().split(':');
      if (parts.length == 2) {
        durationSeconds = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }
    } catch (_) {}

    return RecentSong(
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? 'Unknown',
      artist: json['artist'] ?? 'Unknown Artist',
      thumbnail: json['thumbnail'],
      duration: durationStr.toString(),
      durationSeconds: durationSeconds,
    );
  }
}

/// Mappers para convertir entre las diferentes entidades de Song y la entidad centralizada.
///
/// Esta clase proporciona métodos para convertir fácilmente
/// desde las entidades específicas de cada feature hacia la entidad [core.Song] central.
class SongMapper {
  /// Crea una instancia de [core.Song] desde [search.Song] (búsqueda)
  static core.Song fromSearchSong(search.Song song) {
    return core.Song(
      videoId: song.videoId,
      title: song.title,
      artist: song.artists.isNotEmpty ? song.artists.first.name : 'Unknown',
      artistNames: song.artists.map((a) => a.name).toList(),
      album: song.album.name,
      thumbnail: song.thumbnails.isNotEmpty ? song.thumbnails.first.url : null,
      highThumbnail: song.thumbnail?.url ?? song.thumbnails.lastOrNull?.url,
      thumbnails: song.thumbnails
          .map(
            (t) => core.Thumbnail(
              url: t.url,
              width: t.width ?? 0,
              height: t.height ?? 0,
            ),
          )
          .toList(),
      streamUrl: song.streamUrl,
      durationSeconds: song.durationSeconds,
      duration: song.duration,
      views: song.views,
      isExplicit: song.isExplicit,
      inLibrary: song.inLibrary,
    );
  }

  /// Crea una instancia de [core.Song] desde [DownloadedSong]
  static core.Song fromDownloadedSong(DownloadedSong song) {
    return core.Song(
      videoId: song.videoId,
      title: song.title,
      artist: song.artist,
      album: song.album,
      thumbnail: song.thumbnail,
      highThumbnail: song.thumbnail,
      localPath: song.localPath,
      durationSeconds: song.duration.inSeconds,
      duration: song.durationFormatted,
      fileSize: song.fileSize,
      downloadedAt: song.downloadedAt,
    );
  }

  /// Crea una instancia de [core.Song] desde [ChartPlaylist]
  static core.Song fromChartPlaylist(ChartPlaylist playlist) {
    return core.Song(
      videoId: playlist.playlistId,
      title: playlist.title,
      artist: '',
      thumbnail: playlist.bestThumbnail,
      highThumbnail: playlist.bestThumbnail,
      thumbnails: playlist.thumbnails
          .map(
            (t) => core.Thumbnail(url: t.url, width: t.width, height: t.height),
          )
          .toList(),
    );
  }

  /// Crea una instancia de [core.Song] desde [SongMetadata] (library)
  static core.Song fromSongMetadata(SongMetadata metadata, String videoId) {
    return core.Song(
      videoId: videoId,
      title: metadata.title ?? 'Unknown',
      artist: metadata.artist ?? 'Unknown',
      thumbnail: metadata.thumbnail,
      durationSeconds: metadata.duration ?? 0,
    );
  }

  /// Crea una instancia de [core.Song] desde [FavoriteSong] (library)
  static core.Song fromFavoriteSong(FavoriteSong song) {
    return core.Song(
      videoId: song.videoId,
      title: song.title,
      artist: song.artist,
      thumbnail: song.thumbnail,
      streamUrl: song.streamUrl,
      durationSeconds: song.duration ?? 0,
      duration: _formatDuration(song.duration ?? 0),
      inLibrary: true,
    );
  }

  /// Crea una instancia de [core.Song] desde [UserPlaylistSong]
  static core.Song fromUserPlaylistSong(UserPlaylistSong song) {
    return core.Song(
      videoId: song.videoId,
      title: song.title,
      artist: song.artist,
      thumbnail: song.thumbnail,
      streamUrl: song.streamUrl,
      durationSeconds: song.duration ?? 0,
      duration: _formatDuration(song.duration ?? 0),
    );
  }

  /// Crea una instancia de [core.Song] desde [RecentSong] (recently played)
  static core.Song fromRecentSong(RecentSong song) {
    return core.Song(
      videoId: song.videoId,
      title: song.title,
      artist: song.artist,
      thumbnail: song.thumbnail,
      durationSeconds: song.durationSeconds,
      duration: _formatDuration(song.durationSeconds),
    );
  }

  /// Crea una instancia de [core.Song] desde [artist.ArtistSong]
  static core.Song fromArtistSong(artist.ArtistSong song) {
    return core.Song(
      videoId: song.videoId,
      title: song.title,
      artist: '', // ArtistSong no tiene campo artist
      thumbnail: song.thumbnail,
      streamUrl: song.streamUrl,
      durationSeconds: song.durationSeconds,
      duration: song.formattedDuration,
      views: song.views > 0 ? song.views.toString() : null,
    );
  }

  /// Crea una instancia de [core.Song] desde [album.AlbumSong]
  static core.Song fromAlbumSong(album.AlbumSong song, {String? artistName}) {
    return core.Song(
      videoId: song.videoId,
      title: song.title,
      artist: artistName ?? '',
      thumbnail: song.thumbnail,
      streamUrl: song.streamUrl,
      durationSeconds: song.durationSeconds,
      duration: song.formattedDuration,
    );
  }

  /// Crea una instancia de [core.Song] desde [FavoriteSongEntity] (library domain)
  static core.Song fromFavoriteSongEntity(FavoriteSongEntity song) {
    int durationSeconds = 0;
    if (song.duration != null) {
      durationSeconds = song.duration!;
    }
    return core.Song(
      videoId: song.videoId,
      title: song.title ?? 'Unknown',
      artist: song.artist ?? 'Unknown Artist',
      thumbnail: song.thumbnail,
      durationSeconds: durationSeconds,
      duration: _formatDuration(durationSeconds),
      inLibrary: true,
    );
  }

  /// Convierte una lista de [search.Song] a [core.Song]
  static List<core.Song> fromSearchSongList(List<search.Song> songs) {
    return songs.map(fromSearchSong).toList();
  }

  /// Convierte una lista de [DownloadedSong] a [core.Song]
  static List<core.Song> fromDownloadedSongList(List<DownloadedSong> songs) {
    return songs.map(fromDownloadedSong).toList();
  }

  /// Convierte una lista de [FavoriteSong] a [core.Song]
  static List<core.Song> fromFavoriteSongList(List<FavoriteSong> songs) {
    return songs.map(fromFavoriteSong).toList();
  }

  /// Convierte una lista de [RecentSong] a [core.Song]
  static List<core.Song> fromRecentSongList(List<RecentSong> songs) {
    return songs.map(fromRecentSong).toList();
  }

  /// Convierte una lista de [artist.ArtistSong] a [core.Song]
  static List<core.Song> fromArtistSongList(List<artist.ArtistSong> songs) {
    return songs.map(fromArtistSong).toList();
  }

  /// Convierte una lista de [album.AlbumSong] a [core.Song]
  static List<core.Song> fromAlbumSongList(
    List<album.AlbumSong> songs, {
    String? artistName,
  }) {
    return songs.map((s) => fromAlbumSong(s, artistName: artistName)).toList();
  }

  /// Convierte una lista de [FavoriteSongEntity] a [core.Song]
  static List<core.Song> fromFavoriteSongEntityList(
    List<FavoriteSongEntity> songs,
  ) {
    return songs.map(fromFavoriteSongEntity).toList();
  }

  /// Convierte [core.Song] a [NowPlayingData] para el reproductor
  static NowPlayingData toNowPlayingData(core.Song song) {
    return NowPlayingData.fromCanonicalSong(song);
  }

  /// Convierte [core.Song] a [offline.OfflineSong] para persistencia offline
  static offline.OfflineSong toOfflineSong(core.Song song) {
    return offline.OfflineSong()
      ..songId = song.videoId
      ..videoId = song.videoId
      ..title = song.title
      ..artist = song.artist
      ..thumbnail = song.thumbnail
      ..duration = song.durationSeconds
      ..localAudioPath = song.localPath
      ..addedAt = song.downloadedAt ?? DateTime.now();
  }

  /// Convierte [offline.OfflineSong] a [core.Song]
  static core.Song fromOfflineSong(offline.OfflineSong offlineSong) {
    return core.Song(
      videoId: offlineSong.videoId,
      title: offlineSong.title,
      artist: offlineSong.artist,
      thumbnail: offlineSong.thumbnail,
      durationSeconds: offlineSong.duration ?? 0,
      duration: _formatDuration(offlineSong.duration ?? 0),
      localPath: offlineSong.localAudioPath,
      downloadedAt: offlineSong.addedAt,
    );
  }

  /// Convierte un Map (respuesta API) a [core.Song]
  static core.Song fromApiSong(Map<String, dynamic> json) {
    final thumbnails = _parseThumbnails(json['thumbnails']);
    return core.Song(
      videoId: json['videoId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artist: _extractArtistName(json),
      artistNames: _extractArtistNames(json),
      album: (json['album'] as Map<String, dynamic>?)?['name'] as String?,
      thumbnail: thumbnails.isNotEmpty ? thumbnails.first.url : null,
      highThumbnail: thumbnails.isNotEmpty ? thumbnails.last.url : null,
      thumbnails: thumbnails,
      streamUrl: json['stream_url'] as String? ?? json['streamUrl'] as String?,
      durationSeconds:
          json['duration_seconds'] as int? ??
          json['durationSeconds'] as int? ??
          0,
      duration: json['duration'] as String? ?? '0:00',
      views: json['views'] as String?,
      isExplicit: json['isExplicit'] as bool? ?? false,
      inLibrary: json['inLibrary'] as bool? ?? false,
    );
  }

  /// Convierte [PlaylistTrack] a [core.Song]
  static core.Song fromPlaylistTrack(PlaylistTrack track) {
    return core.Song(
      videoId: track.videoId ?? '',
      title: track.title,
      artist: track.artists.isNotEmpty ? track.artists.first.name : 'Unknown',
      artistNames: track.artists.map((a) => a.name).toList(),
      album: track.album?.name,
      thumbnail: track.thumbnail?.url ?? track.thumbnails.lastOrNull?.url,
      thumbnails: track.thumbnails
          .map(
            (t) => core.Thumbnail(url: t.url, width: t.width, height: t.height),
          )
          .toList(),
      streamUrl: track.streamUrl,
      durationSeconds: track.durationSeconds,
      duration: track.duration,
      views: track.views,
      isExplicit: track.isExplicit,
      inLibrary: track.inLibrary ?? false,
    );
  }

  /// Convierte una lista de Map (respuesta API) a [core.Song]
  static List<core.Song> fromApiSongList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => fromApiSong(json as Map<String, dynamic>))
        .toList();
  }

  /// Convierte [offline.OfflineHistory] a [core.Song]
  static core.Song fromOfflineHistory(offline.OfflineHistory history) {
    return core.Song(
      videoId: history.videoId,
      title: history.title,
      artist: history.artist,
      thumbnail: history.thumbnail,
      durationSeconds: history.duration ?? 0,
      duration: _formatDuration(history.duration ?? 0),
    );
  }

  // Private helpers
  static List<core.Thumbnail> _parseThumbnails(dynamic data) {
    if (data == null) return [];
    return (data as List).map((t) {
      final map = t as Map<String, dynamic>;
      return core.Thumbnail(
        url: map['url'] as String? ?? '',
        width: map['width'] as int? ?? 0,
        height: map['height'] as int? ?? 0,
      );
    }).toList();
  }

  static String _extractArtistName(Map<String, dynamic> json) {
    final artists = json['artists'] as List<dynamic>?;
    if (artists == null || artists.isEmpty) return 'Unknown Artist';
    return (artists.first as Map<String, dynamic>)['name'] as String? ??
        'Unknown Artist';
  }

  static List<String> _extractArtistNames(Map<String, dynamic> json) {
    final artists = json['artists'] as List<dynamic>?;
    if (artists == null) return [];
    return artists
        .map((a) => (a as Map<String, dynamic>)['name'] as String? ?? '')
        .toList();
  }
}

/// Helper para formatear duración
String _formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  return '$minutes:${secs.toString().padLeft(2, '0')}';
}
