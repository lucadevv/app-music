import 'package:equatable/equatable.dart';
import 'package:music_app/features/search/domain/entities/album.dart';
import 'package:music_app/features/search/domain/entities/artist.dart';
import 'package:music_app/features/search/domain/entities/thumbnail.dart';

/// Tipo de contenido en las secciones del home
enum HomeContentType { song, album, playlist, unknown }

/// Entidad base SELLADA (Sealed Class) para items del home
///
/// PATTERN: Sealed Class (Dart 3) - Permite Pattern Matching exhaustivo en la UI.
/// Cumple con Open/Closed Principle y Liskov Substitution Principle.
sealed class HomeContentItem extends Equatable {
  final String title;
  final List<Thumbnail> thumbnails;
  final bool isExplicit;
  final List<SearchArtist> artists;
  final String views;

  const HomeContentItem({
    required this.title,
    required this.thumbnails,
    required this.artists,
    this.isExplicit = false,
    this.views = '0',
  });

  /// Tipo de contenido (legacy enum for backwards UI compatibility)
  HomeContentType get contentType;

  String? get videoId => this is HomeSongItem ? (this as HomeSongItem).videoId : null;
  String? get streamUrl => this is HomeSongItem ? (this as HomeSongItem).streamUrl : null;
  String? get playlistId => this is HomePlaylistItem ? (this as HomePlaylistItem).playlistId : null;
  String? get browseId => this is HomeAlbumItem ? (this as HomeAlbumItem).browseId : null;
  String? get description => this is HomePlaylistItem ? (this as HomePlaylistItem).description : null;
  SearchAlbum? get album => this is HomeSongItem ? (this as HomeSongItem).album : (this is HomeAlbumItem ? (this as HomeAlbumItem).album : null);

  bool get isPlayable => this is HomeSongItem && (this as HomeSongItem).streamUrl != null;
  bool get isSong => this is HomeSongItem;
  bool get isPlaylist => this is HomePlaylistItem;
  bool get isAlbum => this is HomeAlbumItem;

  bool matchesQuery(String query) {
    if (query.trim().isEmpty) return true;
    final lowerQuery = query.toLowerCase();
    return title.toLowerCase().contains(lowerQuery) ||
        artists.any((a) => a.name.toLowerCase().contains(lowerQuery));
  }

  bool get hasDescription => description != null && description!.trim().isNotEmpty;
  String get allArtistsNames => artists.map((a) => a.name).join(', ');
  String? get bestThumbnailUrl => thumbnails.isNotEmpty ? thumbnails.last.url : null;

  @override
  List<Object?> get props => [title, thumbnails, isExplicit, artists, views];
}

/// Entidad fuertemente tipada para Canciones en Home
class HomeSongItem extends HomeContentItem {
  @override
  final String videoId;
  @override
  final String? streamUrl;
  final Thumbnail? thumbnail; // Thumbnail de calidad asociado al stream
  final String? videoType;
  @override
  final SearchAlbum? album;

  const HomeSongItem({
    required super.title,
    required super.thumbnails,
    required super.artists,
    required this.videoId,
    this.streamUrl,
    this.thumbnail,
    this.videoType,
    this.album,
    super.isExplicit,
    super.views,
  });

  @override
  HomeContentType get contentType => HomeContentType.song;

  @override
  String? get bestThumbnailUrl => thumbnail?.url ?? super.bestThumbnailUrl;

  @override
  List<Object?> get props => [...super.props, videoId, streamUrl, thumbnail, videoType, album];
}

/// Entidad fuertemente tipada para Álbumes en Home
class HomeAlbumItem extends HomeContentItem {
  @override
  final String browseId;
  final String? audioPlaylistId;
  @override
  final SearchAlbum? album;
  final String? type;

  const HomeAlbumItem({
    required super.title,
    required super.thumbnails,
    required super.artists,
    required this.browseId,
    this.audioPlaylistId,
    this.album,
    this.type = 'Album',
    super.isExplicit,
    super.views,
  });

  @override
  HomeContentType get contentType => HomeContentType.album;

  @override
  List<Object?> get props => [...super.props, browseId, audioPlaylistId, album, type];
}

/// Entidad fuertemente tipada para Playlists en Home
class HomePlaylistItem extends HomeContentItem {
  @override
  final String playlistId;
  @override
  final String? description;

  const HomePlaylistItem({
    required super.title,
    required super.thumbnails,
    required super.artists,
    required this.playlistId,
    this.description,
    super.isExplicit,
    super.views,
  });

  @override
  HomeContentType get contentType => HomeContentType.playlist;

  @override
  List<Object?> get props => [...super.props, playlistId, description];
}

/// Fallback para tipos desconocidos
class HomeUnknownItem extends HomeContentItem {
  const HomeUnknownItem({
    required super.title,
    required super.thumbnails,
    required super.artists,
    super.isExplicit,
    super.views,
  });

  @override
  HomeContentType get contentType => HomeContentType.unknown;
}
