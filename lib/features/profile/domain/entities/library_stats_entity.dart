import 'package:equatable/equatable.dart';

/// Entity representing library statistics.
class LibraryStatsEntity extends Equatable {
  final int favoriteSongsCount;
  final int favoritePlaylistsCount;
  final int favoriteGenresCount;

  const LibraryStatsEntity({
    this.favoriteSongsCount = 0,
    this.favoritePlaylistsCount = 0,
    this.favoriteGenresCount = 0,
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Verifica si existe algún tipo de actividad o favoritos en la biblioteca
  bool get hasAnyActivity => favoriteSongsCount > 0 || favoritePlaylistsCount > 0 || favoriteGenresCount > 0;

  /// Suma globalizada de todos los elementos guardados por el usuario
  int get totalFavorites => favoriteSongsCount + favoritePlaylistsCount + favoriteGenresCount;

  @override
  List<Object?> get props => [
    favoriteSongsCount,
    favoritePlaylistsCount,
    favoriteGenresCount,
  ];
}
