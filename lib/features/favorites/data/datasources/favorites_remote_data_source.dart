import 'package:music_app/features/library/data/datasources/library_remote_data_source.dart';
import 'package:music_app/features/library/data/models/library_models.dart';

/// Remote data source for favorites feature.
/// Delegates to LibraryRemoteDataSource which already has the correct API schema parsing.
/// This eliminates the schema mismatch where the old FavoritesRemoteDataSource
/// was reading wrong fields (songs vs data, totalCount vs total, etc.)
abstract class FavoritesRemoteDataSource {
  Future<FavoriteSongsResponse> getFavorites({int page = 1, int limit = 10});

  Future<void> addFavorite({
    required String videoId,
    String? title,
    String? artist,
    String? thumbnail,
    int? duration,
  });

  Future<void> removeFavorite(String videoId);

  Future<bool> isFavorite(String videoId);
}

class FavoritesRemoteDataSourceImpl implements FavoritesRemoteDataSource {
  final LibraryRemoteDataSource _libraryDataSource;

  FavoritesRemoteDataSourceImpl(this._libraryDataSource);

  @override
  Future<FavoriteSongsResponse> getFavorites({int page = 1, int limit = 10}) {
    return _libraryDataSource.getFavoriteSongs(page: page, limit: limit);
  }

  @override
  Future<void> addFavorite({
    required String videoId,
    String? title,
    String? artist,
    String? thumbnail,
    int? duration,
  }) {
    return _libraryDataSource.addFavoriteSong(
      videoId: videoId,
      title: title,
      artist: artist,
      thumbnail: thumbnail,
      duration: duration,
    );
  }

  @override
  Future<void> removeFavorite(String videoId) {
    return _libraryDataSource.removeFavoriteSong(videoId);
  }

  @override
  Future<bool> isFavorite(String videoId) {
    return _libraryDataSource.isSongFavorite(videoId);
  }
}
