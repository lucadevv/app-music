part of 'favorite_cubit.dart';



class FavoriteEvent {
  final FavoriteType type;
  final String id;
  final bool isFavorite;

  const FavoriteEvent({
    required this.type,
    required this.id,
    required this.isFavorite,
  });
}

class FavoriteState {
  final Set<String> favoriteSongs;
  final Set<String> favoritePlaylists;
  final Set<String> favoriteGenres;
  final Map<String, String> songIdByVideoId; // videoId -> songId mapping
  final bool isLoading;
  final String? error;

  const FavoriteState({
    this.favoriteSongs = const {},
    this.favoritePlaylists = const {},
    this.favoriteGenres = const {},
    this.songIdByVideoId = const {},
    this.isLoading = false,
    this.error,
  });

  /// Obtiene el songId para un videoId dado
  String? getSongIdForVideoId(String videoId) => songIdByVideoId[videoId];

  FavoriteState copyWith({
    Set<String>? favoriteSongs,
    Set<String>? favoritePlaylists,
    Set<String>? favoriteGenres,
    Map<String, String>? songIdByVideoId,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return FavoriteState(
      favoriteSongs: favoriteSongs ?? this.favoriteSongs,
      favoritePlaylists: favoritePlaylists ?? this.favoritePlaylists,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      songIdByVideoId: songIdByVideoId ?? this.songIdByVideoId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
