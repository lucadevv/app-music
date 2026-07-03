import 'package:music_app/features/home/domain/entities/home_content_item.dart';
import 'package:music_app/features/search/data/models/search_album_model.dart';
import 'package:music_app/features/search/data/models/search_artist_model.dart';
import 'package:music_app/features/search/data/models/thumbnail_model.dart';

/// Mapper (Factory) para HomeContentItem
///
/// PATTERN: Factory Pattern con Dart 3 Pattern Matching
/// Crea las subclases fuertemente tipadas sin usar cadenas de ifs anidados
class HomeContentItemMapper {
  static HomeContentItem fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String? ?? '';
    final isExplicit = json['isExplicit'] as bool? ?? false;
    final views = json['views'] as String? ?? '0';

    final thumbnails =
        (json['thumbnails'] as List<dynamic>?)
            ?.map((item) => ThumbnailModel.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    final artists =
        (json['artists'] as List<dynamic>?)
            ?.map((item) => SearchArtistModel.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    final album =
        json['album'] != null
            ? SearchAlbumModel.fromJson(json['album'] as Map<String, dynamic>)
            : null;

    final streamUrl = json['stream_url'] as String?;
    final thumbnail = _parseThumbnail(json);
    final videoType = json['videoType'] as String?;
    final type = json['type'] as String?;
    final description = json['description'] as String?;

    // DART 3 PATTERN MATCHING FACTORY
    return switch (json) {
      {'videoId': final String vId} when vId.isNotEmpty => HomeSongItem(
        title: title,
        thumbnails: thumbnails,
        artists: artists,
        videoId: vId,
        streamUrl: streamUrl,
        thumbnail: thumbnail,
        videoType: videoType,
        album: album,
        isExplicit: isExplicit,
        views: views,
      ),
      {'browseId': final String bId} when bId.isNotEmpty => HomeAlbumItem(
        title: title,
        thumbnails: thumbnails,
        artists: artists,
        browseId: bId,
        audioPlaylistId: json['audioPlaylistId'] as String?,
        album: album,
        type: type ?? 'Album',
        isExplicit: isExplicit,
        views: views,
      ),
      {'playlistId': final String pId} when pId.isNotEmpty => HomePlaylistItem(
        title: title,
        thumbnails: thumbnails,
        artists: artists,
        playlistId: pId,
        description: description,
        isExplicit: isExplicit,
        views: views,
      ),
      _ => HomeUnknownItem(
        title: title,
        thumbnails: thumbnails,
        artists: artists,
        isExplicit: isExplicit,
        views: views,
      ),
    };
  }

  static Map<String, dynamic> toJson(HomeContentItem item) {
    final base = {
      'title': item.title,
      'thumbnails': item.thumbnails.map((t) => (t as ThumbnailModel).toJson()).toList(),
      'isExplicit': item.isExplicit,
      'artists': item.artists.map((a) => (a as SearchArtistModel).toJson()).toList(),
      'views': item.views,
    };

    return switch (item) {
      final HomeSongItem s => {
        ...base,
        'videoId': s.videoId,
        if (s.streamUrl != null) 'stream_url': s.streamUrl,
        if (s.thumbnail != null) 'thumbnail': (s.thumbnail as ThumbnailModel).toJson(),
        if (s.videoType != null) 'videoType': s.videoType,
        if (s.album != null) 'album': (s.album as SearchAlbumModel).toJson(),
      },
      final HomeAlbumItem a => {
        ...base,
        'browseId': a.browseId,
        if (a.audioPlaylistId != null) 'audioPlaylistId': a.audioPlaylistId,
        if (a.type != null) 'type': a.type,
        if (a.album != null) 'album': (a.album as SearchAlbumModel).toJson(),
      },
      final HomePlaylistItem p => {
        ...base,
        'playlistId': p.playlistId,
        if (p.description != null) 'description': p.description,
      },
      HomeUnknownItem _ => base,
    };
  }

  /// Parser para thumbnail que puede ser String o Map
  static ThumbnailModel? _parseThumbnail(Map<String, dynamic> json) {
    final thumbnail = json['thumbnail'];
    if (thumbnail == null) return null;
    if (thumbnail is String) {
      // Si es string, crear un Thumbnail con esa URL
      return ThumbnailModel(url: thumbnail, width: 800, height: 800);
    }
    if (thumbnail is Map<String, dynamic>) {
      return ThumbnailModel.fromJson(thumbnail);
    }
    return null;
  }
}
