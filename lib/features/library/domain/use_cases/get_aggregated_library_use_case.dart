import 'package:dartz/dartz.dart';
import 'package:music_app/core/data/offline/services/offline_service.dart';
import 'package:music_app/core/domain/entities/song.dart';
import 'package:music_app/core/utils/exeptions/app_exceptions.dart';
import 'package:music_app/features/library/data/models/library_models.dart';
import 'package:music_app/features/library/domain/entities/aggregated_library.dart';
import 'package:music_app/features/library/domain/entities/library_entities.dart';
import 'package:music_app/features/library/domain/use_cases/get_favorite_genres_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/get_favorite_playlists_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/get_favorite_songs_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/get_library_summary_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/get_user_playlists_use_case.dart';

/// Interactor UseCase que abstrae el manejo de Online/Offline 
/// y consolida los llamados del protocolo de Libería principal.
class GetAggregatedLibraryUseCase {
  final OfflineService _offlineService;
  final GetLibrarySummaryUseCase _getLibrarySummaryUseCase;
  final GetFavoriteSongsUseCase _getFavoriteSongsUseCase;
  final GetFavoritePlaylistsUseCase _getFavoritePlaylistsUseCase;
  final GetFavoriteGenresUseCase _getFavoriteGenresUseCase;
  final GetUserPlaylistsUseCase _getUserPlaylistsUseCase;

  GetAggregatedLibraryUseCase({
    required OfflineService offlineService,
    required GetLibrarySummaryUseCase getLibrarySummaryUseCase,
    required GetFavoriteSongsUseCase getFavoriteSongsUseCase,
    required GetFavoritePlaylistsUseCase getFavoritePlaylistsUseCase,
    required GetFavoriteGenresUseCase getFavoriteGenresUseCase,
    required GetUserPlaylistsUseCase getUserPlaylistsUseCase,
  })  : _offlineService = offlineService,
        _getLibrarySummaryUseCase = getLibrarySummaryUseCase,
        _getFavoriteSongsUseCase = getFavoriteSongsUseCase,
        _getFavoritePlaylistsUseCase = getFavoritePlaylistsUseCase,
        _getFavoriteGenresUseCase = getFavoriteGenresUseCase,
        _getUserPlaylistsUseCase = getUserPlaylistsUseCase;

  Future<Either<AppException, AggregatedLibrary>> call({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final isOnline = await _offlineService.isOnline;

      if (!isOnline) {
        final offlinePlaylists = await _offlineService.getOfflinePlaylists();
        
        final favoritePlaylists = offlinePlaylists
            .map((op) => FavoritePlaylistEntity(
                  id: op.playlistId,
                  externalPlaylistId: op.externalPlaylistId,
                  name: op.name,
                  description: op.description,
                  thumbnail: op.thumbnail ?? op.localThumbnailPath,
                  trackCount: op.trackCount,
                ))
            .toList();

        return Right(AggregatedLibrary(
          favoriteSongs: const [],
          favoritePlaylists: favoritePlaylists,
          userPlaylists: const [],
          favoriteGenres: const [],
          totalSongs: 0,
          totalPlaylists: favoritePlaylists.length,
          totalGenres: 0,
          summary: LibrarySummary(
            favoriteSongs: 0,
            favoritePlaylists: favoritePlaylists.length,
            favoriteGenres: 0,
          ),
          isOffline: true,
        ));
      }

      final songsResult = await _getFavoriteSongsUseCase(page: page, limit: limit);
      final playlistsResult = await _getFavoritePlaylistsUseCase(page: page, limit: limit);
      final userPlaylistsResult = await _getUserPlaylistsUseCase(page: page, limit: limit * 2);
      final genresResult = await _getFavoriteGenresUseCase(page: page, limit: limit);
      final summaryResult = await _getLibrarySummaryUseCase();

      final favoriteSongs = songsResult.fold((error) => <Song>[], (data) => data);
      final favoritePlaylists = playlistsResult.fold((error) => <FavoritePlaylistEntity>[], (data) => data);
      final userPlaylists = userPlaylistsResult.fold((error) => <UserPlaylist>[], (data) => data);
      final favoriteGenres = genresResult.fold((error) => <FavoriteGenreEntity>[], (data) => data);
      
      LibrarySummary? summary;
      summaryResult.fold(
        (error) => null, 
        (data) {
          summary = LibrarySummary(
            favoriteSongs: data.favoriteSongsCount,
            favoritePlaylists: data.favoritePlaylistsCount,
            favoriteGenres: data.favoriteGenresCount,
          );
        }
      );

      final totalSongs = favoriteSongs.length;
      final totalPlaylists = favoritePlaylists.length + userPlaylists.length;
      final totalGenres = favoriteGenres.length;

      return Right(AggregatedLibrary(
        favoriteSongs: favoriteSongs,
        favoritePlaylists: favoritePlaylists,
        userPlaylists: userPlaylists,
        favoriteGenres: favoriteGenres,
        totalSongs: totalSongs,
        totalPlaylists: totalPlaylists,
        totalGenres: totalGenres,
        summary: summary,
        isOffline: false,
      ));

    } catch (e) {
      if (e is AppException) return Left(e);
      return Left(ServerException('Error agregando librería: $e'));
    }
  }
}
