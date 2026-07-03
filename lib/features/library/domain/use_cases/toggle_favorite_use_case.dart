import 'package:dartz/dartz.dart';
import 'package:music_app/core/domain/entities/song.dart';
import 'package:music_app/core/utils/exeptions/app_exceptions.dart';
import 'package:music_app/features/library/data/models/library_models.dart';
import 'package:music_app/features/library/domain/entities/favorite_type.dart';
import 'package:music_app/features/library/domain/use_cases/add_favorite_genre_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/add_favorite_playlist_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/add_favorite_song_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/remove_favorite_genre_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/remove_favorite_playlist_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/remove_favorite_song_use_case.dart';

class ToggleFavoriteParams {
  final FavoriteType type;
  final String videoId;
  final bool isCurrentlyFavorite;
  final String? songId;
  final SongMetadata? metadata;
  final PlaylistMetadata? playlistMetadata;

  ToggleFavoriteParams({
    required this.type,
    required this.videoId,
    required this.isCurrentlyFavorite,
    this.songId,
    this.metadata,
    this.playlistMetadata,
  });
}

class ToggleFavoriteUseCase {
  final AddFavoriteSongUseCase _addFavoriteSongUseCase;
  final RemoveFavoriteSongUseCase _removeFavoriteSongUseCase;
  final AddFavoritePlaylistUseCase _addFavoritePlaylistUseCase;
  final RemoveFavoritePlaylistUseCase _removeFavoritePlaylistUseCase;
  final AddFavoriteGenreUseCase _addFavoriteGenreUseCase;
  final RemoveFavoriteGenreUseCase _removeFavoriteGenreUseCase;

  ToggleFavoriteUseCase({
    required AddFavoriteSongUseCase addFavoriteSongUseCase,
    required RemoveFavoriteSongUseCase removeFavoriteSongUseCase,
    required AddFavoritePlaylistUseCase addFavoritePlaylistUseCase,
    required RemoveFavoritePlaylistUseCase removeFavoritePlaylistUseCase,
    required AddFavoriteGenreUseCase addFavoriteGenreUseCase,
    required RemoveFavoriteGenreUseCase removeFavoriteGenreUseCase,
  })  : _addFavoriteSongUseCase = addFavoriteSongUseCase,
        _removeFavoriteSongUseCase = removeFavoriteSongUseCase,
        _addFavoritePlaylistUseCase = addFavoritePlaylistUseCase,
        _removeFavoritePlaylistUseCase = removeFavoritePlaylistUseCase,
        _addFavoriteGenreUseCase = addFavoriteGenreUseCase,
        _removeFavoriteGenreUseCase = removeFavoriteGenreUseCase;

  Future<Either<AppException, void>> call(ToggleFavoriteParams params) async {
    if (params.isCurrentlyFavorite) {
      switch (params.type) {
        case FavoriteType.song:
          final effectiveSongId = params.songId ?? params.videoId;
          return _removeFavoriteSongUseCase(effectiveSongId);
        case FavoriteType.playlist:
          return _removeFavoritePlaylistUseCase(params.videoId);
        case FavoriteType.genre:
          return _removeFavoriteGenreUseCase(params.videoId);
      }
    } else {
      switch (params.type) {
        case FavoriteType.song:
          final song = Song(
            videoId: params.videoId,
            title: params.metadata?.title ?? '',
            artist: params.metadata?.artist ?? '',
            thumbnail: params.metadata?.thumbnail,
            durationSeconds: params.metadata?.duration ?? 0,
            streamUrl: params.metadata?.streamUrl,
          );
          return _addFavoriteSongUseCase(song);
        case FavoriteType.playlist:
          return _addFavoritePlaylistUseCase(
            externalPlaylistId: params.videoId,
            name: params.playlistMetadata?.name,
            thumbnail: params.playlistMetadata?.thumbnail,
            description: params.playlistMetadata?.description,
            trackCount: params.playlistMetadata?.trackCount,
          );
        case FavoriteType.genre:
          return _addFavoriteGenreUseCase(externalParams: params.videoId);
      }
    }
  }
}
