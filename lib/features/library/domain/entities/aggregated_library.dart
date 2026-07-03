import 'package:equatable/equatable.dart';
import 'package:music_app/core/domain/entities/song.dart';
import 'package:music_app/features/library/data/models/library_models.dart';
import 'package:music_app/features/library/domain/entities/library_entities.dart';

/// Unifica los datos de los diferentes endpoints del Library
/// Actúa como un Data Transfer Object entre los Casos de Uso y la capa de Presentación
class AggregatedLibrary extends Equatable {
  final List<Song> favoriteSongs;
  final List<FavoritePlaylistEntity> favoritePlaylists;
  final List<UserPlaylist> userPlaylists;
  final List<FavoriteGenreEntity> favoriteGenres;
  final LibrarySummary? summary;
  
  final int totalSongs;
  final int totalPlaylists;
  final int totalGenres;
  
  final bool isOffline;

  const AggregatedLibrary({
    required this.favoriteSongs,
    required this.favoritePlaylists,
    required this.userPlaylists,
    required this.favoriteGenres,
    required this.totalSongs, required this.totalPlaylists, required this.totalGenres, required this.isOffline, this.summary,
  });

  @override
  List<Object?> get props => [
        favoriteSongs,
        favoritePlaylists,
        userPlaylists,
        favoriteGenres,
        summary,
        totalSongs,
        totalPlaylists,
        totalGenres,
        isOffline,
      ];
}
