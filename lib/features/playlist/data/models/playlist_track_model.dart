import '../../../search/data/models/search_album_model.dart'
    show SearchAlbumModel;
import '../../../search/data/models/search_artist_model.dart'
    show SearchArtistModel;
import '../../../search/data/models/thumbnail_model.dart' show ThumbnailModel;
import '../../domain/entities/playlist_track.dart';

/// Modelo de datos para una canción en una playlist
class PlaylistTrackModel extends PlaylistTrack {
  const PlaylistTrackModel({
    required super.title,
    required super.artists,
    required super.thumbnails,
    required super.isAvailable,
    required super.isExplicit,
    required super.duration,
    required super.durationSeconds,
    super.videoId,
    super.album,
    super.likeStatus,
    super.inLibrary,
    super.pinnedToListenAgain,
    super.videoType,
    super.views,
    super.streamUrl,
    super.thumbnail,
  });

  factory PlaylistTrackModel.fromJson(Map<String, dynamic> json) {
    return PlaylistTrackModel(
      videoId: json['videoId'] as String?,
      title: json['title'] as String? ?? '',
      artists:
          (json['artists'] as List<dynamic>?)
              ?.map(
                (artist) =>
                    SearchArtistModel.fromJson(artist as Map<String, dynamic>),
              )
              .toList() ??
          [],
      album: json['album'] != null
          ? SearchAlbumModel.fromJson(json['album'] as Map<String, dynamic>)
          : null,
      likeStatus: json['likeStatus'] as String?,
      inLibrary: json['inLibrary'] as bool?,
      pinnedToListenAgain: json['pinnedToListenAgain'] as bool?,
      thumbnails: json['thumbnails'] != null
          ? (json['thumbnails'] as List<dynamic>)
                .whereType<Map<String, dynamic>>()
                .map(ThumbnailModel.fromJson)
                .toList()
          : [],
      isAvailable: json['isAvailable'] as bool? ?? true,
      isExplicit: json['isExplicit'] as bool? ?? false,
      videoType: json['videoType'] as String?,
      views: json['views']?.toString(),
      duration: json['duration'] as String? ?? '0:00',
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      streamUrl: (json['streamUrl'] ?? json['stream_url']) as String?,
      thumbnail: json['thumbnail'] != null
          ? (json['thumbnail'] is Map<String, dynamic>
                ? ThumbnailModel.fromJson(
                    json['thumbnail'] as Map<String, dynamic>,
                  )
                : null) // Si thumbnail es String, ignorarlo (usar thumbnails array)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'artists': artists
          .map((artist) => (artist as SearchArtistModel).toJson())
          .toList(),
      'album': album != null ? (album as SearchAlbumModel).toJson() : null,
      'likeStatus': likeStatus,
      'inLibrary': inLibrary,
      'pinnedToListenAgain': pinnedToListenAgain,
      'thumbnails': thumbnails
          .map((thumb) => (thumb as ThumbnailModel).toJson())
          .toList(),
      'isAvailable': isAvailable,
      'isExplicit': isExplicit,
      'videoType': videoType,
      'views': views,
      'duration': duration,
      'duration_seconds': durationSeconds,
      if (streamUrl != null) 'stream_url': streamUrl,
      if (thumbnail != null)
        'thumbnail': (thumbnail as ThumbnailModel).toJson(),
    };
  }
}
