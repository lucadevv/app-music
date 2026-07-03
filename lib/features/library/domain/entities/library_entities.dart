import 'package:equatable/equatable.dart';

/// Domain entity representing library summary
class LibrarySummaryEntity extends Equatable {
  final int favoriteSongsCount;
  final int favoritePlaylistsCount;
  final int favoriteGenresCount;
  final List<String>? recentlyPlayed;

  const LibrarySummaryEntity({
    this.favoriteSongsCount = 0,
    this.favoritePlaylistsCount = 0,
    this.favoriteGenresCount = 0,
    this.recentlyPlayed,
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Verifica si el usuario posee alguna entidad favorita guardada
  bool get hasFavorites => 
    favoriteSongsCount > 0 || 
    favoritePlaylistsCount > 0 || 
    favoriteGenresCount > 0;

  /// Verifica si el usuario ha registrado actividad reciente
  bool get hasRecentActivity => recentlyPlayed != null && recentlyPlayed!.isNotEmpty;

  @override
  List<Object?> get props => [
    favoriteSongsCount,
    favoritePlaylistsCount,
    favoriteGenresCount,
    recentlyPlayed,
  ];
}

/// Domain entity for a favorite song in library
class FavoriteSongEntity extends Equatable {
  final String videoId;
  final String songId;
  final String? title;
  final String? artist;
  final String? thumbnail;
  final int? duration;
  final DateTime? addedAt;

  const FavoriteSongEntity({
    required this.videoId,
    required this.songId,
    this.title,
    this.artist,
    this.thumbnail,
    this.duration,
    this.addedAt,
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Indica si la canción tiene información válida de artista
  bool get hasArtist => artist != null && artist!.trim().isNotEmpty;

  /// Indica si la canción cuenta con un recurso visual válido
  bool get hasThumbnail => thumbnail != null && thumbnail!.trim().isNotEmpty;

  /// Verifica si la canción fue añadida muy recientemente (por defecto, últimas 24hs)
  bool isRecentlyAdded([Duration threshold = const Duration(hours: 24)]) {
    if (addedAt == null) return false;
    return DateTime.now().difference(addedAt!) <= threshold;
  }

  @override
  List<Object?> get props => [
    videoId,
    songId,
    title,
    artist,
    thumbnail,
    duration,
    addedAt,
  ];
}

/// Domain entity for a favorite playlist
class FavoritePlaylistEntity extends Equatable {
  final String id;
  final String externalPlaylistId;
  final String? name;
  final String? thumbnail;
  final String? description;
  final int? trackCount;

  const FavoritePlaylistEntity({
    required this.id,
    required this.externalPlaylistId,
    this.name,
    this.thumbnail,
    this.description,
    this.trackCount,
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Verifica si la lista cuenta con descripción personalizada
  bool get hasDescription => description != null && description!.trim().isNotEmpty;

  /// Verifica si la lista tiene miniatura asignada
  bool get hasThumbnail => thumbnail != null && thumbnail!.trim().isNotEmpty;

  /// Indica si la lista de reproducción propia no posee canciones
  bool get isEmpty => trackCount == 0 || trackCount == null;

  @override
  List<Object?> get props => [
    id,
    externalPlaylistId,
    name,
    thumbnail,
    description,
    trackCount,
  ];
}

/// Domain entity for a favorite genre
class FavoriteGenreEntity extends Equatable {
  final String id;
  final String externalParams;
  final String? name;

  const FavoriteGenreEntity({
    required this.id,
    required this.externalParams,
    this.name,
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Verifica si tiene parámetros externos válidos para navegación
  bool get hasValidParams => externalParams.trim().isNotEmpty;

  @override
  List<Object?> get props => [id, externalParams, name];
}

/// Response entity containing songs with their ID mapping
/// Used by FavoriteCubit to maintain videoId -> songId mapping for removal
class FavoriteSongsWithMapping extends Equatable {
  final List<FavoriteSongEntity> songs;
  final Map<String, String> songIdByVideoId;

  const FavoriteSongsWithMapping({
    required this.songs,
    required this.songIdByVideoId,
  });

  @override
  List<Object?> get props => [songs, songIdByVideoId];
}
