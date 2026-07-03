import 'package:dartz/dartz.dart';
import 'package:music_app/core/domain/entities/song.dart';
import 'package:music_app/core/utils/exeptions/app_exceptions.dart';
import 'package:music_app/features/favorites/data/datasources/favorites_remote_data_source.dart';
import 'package:music_app/features/favorites/domain/repositories/favorites_repository.dart';

/// Implementation of FavoritesRepository.
class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesRemoteDataSource _remoteDataSource;

  FavoritesRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<AppException, List<Song>>> getFavorites({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _remoteDataSource.getFavorites(
        page: page,
        limit: limit,
      );
      // Map FavoriteSong (from library_models.dart) to core Song entity
      final songs = response.data
          .map(
            (favSong) => Song(
              videoId: favSong.videoId,
              title: favSong.title,
              artist: favSong.artist,
              thumbnail: favSong.thumbnail,
              streamUrl: favSong.streamUrl,
              durationSeconds: favSong.duration ?? 0,
            ),
          )
          .toList();
      return Right(songs);
    } catch (e) {
      return Left(UnknownException(e.toString()));
    }
  }

  @override
  Future<Either<AppException, void>> addFavorite(Song song) async {
    try {
      await _remoteDataSource.addFavorite(
        videoId: song.videoId,
        title: song.title,
        artist: song.artist,
        thumbnail: song.thumbnail,
        duration: song.durationSeconds,
      );
      return const Right(null);
    } catch (e) {
      return Left(UnknownException(e.toString()));
    }
  }

  @override
  Future<Either<AppException, void>> removeFavorite(String videoId) async {
    try {
      await _remoteDataSource.removeFavorite(videoId);
      return const Right(null);
    } catch (e) {
      return Left(UnknownException(e.toString()));
    }
  }

  @override
  Future<Either<AppException, bool>> isFavorite(String videoId) async {
    try {
      final result = await _remoteDataSource.isFavorite(videoId);
      return Right(result);
    } catch (e) {
      return Left(UnknownException(e.toString()));
    }
  }
}
