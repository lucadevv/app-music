import 'package:dartz/dartz.dart';
import 'package:music_app/core/utils/exeptions/app_exceptions.dart';
import 'package:music_app/features/library/data/models/library_models.dart';
import 'package:music_app/features/library/domain/repositories/library_repository.dart';
import 'package:music_app/features/library/domain/use_cases/get_favorite_genres_with_mapping_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/get_favorite_playlists_with_mapping_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/get_favorite_songs_with_mapping_use_case.dart';

class FavoriteDataAggregated {
  final FavoriteSongsWithMapping songs;
  final List<FavoritePlaylist> playlists;
  final List<FavoriteGenre> genres;

  FavoriteDataAggregated({
    required this.songs,
    required this.playlists,
    required this.genres,
  });
}

class LoadFavoritesUseCase {
  final GetFavoriteSongsWithMappingUseCase _getFavoriteSongsWithMappingUseCase;
  final GetFavoritePlaylistsWithMappingUseCase _getFavoritePlaylistsWithMappingUseCase;
  final GetFavoriteGenresWithMappingUseCase _getFavoriteGenresWithMappingUseCase;

  LoadFavoritesUseCase({
    required GetFavoriteSongsWithMappingUseCase getFavoriteSongsWithMappingUseCase,
    required GetFavoritePlaylistsWithMappingUseCase getFavoritePlaylistsWithMappingUseCase,
    required GetFavoriteGenresWithMappingUseCase getFavoriteGenresWithMappingUseCase,
  })  : _getFavoriteSongsWithMappingUseCase = getFavoriteSongsWithMappingUseCase,
        _getFavoritePlaylistsWithMappingUseCase = getFavoritePlaylistsWithMappingUseCase,
        _getFavoriteGenresWithMappingUseCase = getFavoriteGenresWithMappingUseCase;

  Future<Either<AppException, FavoriteDataAggregated>> call({
    int page = 1,
    int limit = 100,
  }) async {
    final results = await Future.wait([
      _getFavoriteSongsWithMappingUseCase(page: page, limit: limit),
      _getFavoritePlaylistsWithMappingUseCase(page: page, limit: limit),
      _getFavoriteGenresWithMappingUseCase(page: page, limit: limit),
    ]);

    final songsResult = results[0] as Either<AppException, dynamic>;
    final playlistsResult = results[1] as Either<AppException, dynamic>;
    final genresResult = results[2] as Either<AppException, dynamic>;

    if (songsResult.isLeft()) {
      return Left(songsResult.fold((l) => l, (r) => throw Exception()));
    }
    if (playlistsResult.isLeft()) {
      return Left(playlistsResult.fold((l) => l, (r) => throw Exception()));
    }
    if (genresResult.isLeft()) {
      return Left(genresResult.fold((l) => l, (r) => throw Exception()));
    }

    return Right(FavoriteDataAggregated(
      songs: songsResult.fold((l) => throw Exception(), (r) => r as FavoriteSongsWithMapping),
      playlists: playlistsResult.fold((l) => throw Exception(), (r) => r as List<FavoritePlaylist>),
      genres: genresResult.fold((l) => throw Exception(), (r) => r as List<FavoriteGenre>),
    ));
  }
}
