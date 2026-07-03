import 'package:music_app/core/domain/entities/song.dart';

/// Data model para Song que maneja la persistencia y serialización JSON.
/// Aisla a la entidad de dominio de los detalles de infraestructura.
class SongModel {
  static Map<String, dynamic> toJson(Song song) {
    return {
      'videoId': song.videoId,
      'title': song.title,
      'artist': song.artist,
      'artistNames': song.artistNames,
      'album': song.album,
      'thumbnail': song.thumbnail,
      'highThumbnail': song.highThumbnail,
      'thumbnails': song.thumbnails.map((t) => {'url': t.url, 'width': t.width, 'height': t.height}).toList(),
      'streamUrl': song.streamUrl,
      'durationSeconds': song.durationSeconds,
      'duration': song.duration,
      'views': song.views,
      'isExplicit': song.isExplicit,
      'inLibrary': song.inLibrary,
      'localPath': song.localPath,
      'fileSize': song.fileSize,
      'downloadedAt': song.downloadedAt?.toIso8601String(),
    };
  }

  static Song fromJson(Map<String, dynamic> json) {
    return Song(
      videoId: json['videoId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      artistNames:
          (json['artistNames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      album: json['album'] as String?,
      thumbnail: json['thumbnail'] as String?,
      highThumbnail: json['highThumbnail'] as String?,
      thumbnails:
          (json['thumbnails'] as List<dynamic>?)?.map((e) {
            final map = e as Map<String, dynamic>;
            return Thumbnail(
              url: map['url'] as String? ?? '',
              width: map['width'] as int? ?? 0,
              height: map['height'] as int? ?? 0,
            );
          }).toList() ??
          [],
      streamUrl: (json['streamUrl'] ?? json['stream_url']) as String?,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      duration: json['duration'] as String? ?? '0:00',
      views: json['views'] as String? ?? '0',
      isExplicit: json['isExplicit'] as bool? ?? false,
      inLibrary: json['inLibrary'] as bool? ?? false,
      localPath: json['localPath'] as String?,
      fileSize: json['fileSize'] as int?,
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.parse(json['downloadedAt'] as String)
          : null,
    );
  }
}
