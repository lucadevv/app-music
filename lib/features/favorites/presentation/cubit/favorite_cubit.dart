// ignore_for_file: unawaited_futures
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/bloc/base_bloc_mixin.dart';
import 'package:music_app/core/data/offline/services/offline_service.dart';
import 'package:music_app/core/utils/exeptions/app_exceptions.dart';
import 'package:music_app/features/dashboard/presentation/bloc/player_bloc_bloc.dart';
import 'package:music_app/features/library/data/models/library_models.dart';
import 'package:music_app/features/library/domain/entities/favorite_type.dart';
import 'package:music_app/features/library/domain/use_cases/load_favorites_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/toggle_favorite_use_case.dart';
import 'package:music_app/features/offline/presentation/cubit/playlist_offline_cubit.dart';
import 'package:music_app/features/player/domain/entities/now_playing_data.dart';

part 'favorite_state.dart';

/// Cubit para manejar favoritos con estado optimista
/// Clean Architecture: UI → Cubit → UseCases → Repository → DataSource → API
class FavoriteCubit extends Cubit<FavoriteState> with BaseBlocMixin {
  final LoadFavoritesUseCase _loadFavoritesUseCase;
  final ToggleFavoriteUseCase _toggleFavoriteUseCase;
  final PlaylistOfflineCubit _playlistOfflineCubit;
  final OfflineService _offlineService;
  final PlayerBlocBloc _playerBloc;

  final _favoritesController = StreamController<FavoriteEvent>.broadcast();
  Stream<FavoriteEvent> get favoritesStream => _favoritesController.stream;

  FavoriteCubit({
    required LoadFavoritesUseCase loadFavoritesUseCase,
    required ToggleFavoriteUseCase toggleFavoriteUseCase,
    required PlaylistOfflineCubit playlistOfflineCubit,
    required OfflineService offlineService,
    required PlayerBlocBloc playerBloc,
  }) : _loadFavoritesUseCase = loadFavoritesUseCase,
       _toggleFavoriteUseCase = toggleFavoriteUseCase,
       _playlistOfflineCubit = playlistOfflineCubit,
       _offlineService = offlineService,
       _playerBloc = playerBloc,
       super(const FavoriteState()) {
    loadFavorites();
  }

  bool isSongFavorite(String videoId) => state.favoriteSongs.contains(videoId);
  bool isPlaylistFavorite(String playlistId) =>
      state.favoritePlaylists.contains(playlistId);
  bool isGenreFavorite(String externalParams) =>
      state.favoriteGenres.contains(externalParams);

  /// Toggle favorito con actualización optimista
  Future<void> toggleFavorite({
    required String videoId,
    required FavoriteType type,
    required bool isCurrentlyFavorite,
    String? songId,
    SongMetadata? metadata,
    PlaylistMetadata? playlistMetadata,
  }) async {
    // Guardar estado anterior para rollback
    final previousSongs = Set<String>.from(state.favoriteSongs);
    final previousPlaylists = Set<String>.from(state.favoritePlaylists);
    final previousGenres = Set<String>.from(state.favoriteGenres);

    // Actualización optimista inmediata
    if (type == FavoriteType.song) {
      if (isCurrentlyFavorite) {
        state.favoriteSongs.remove(videoId);
      } else {
        state.favoriteSongs.add(videoId);
      }
    } else if (type == FavoriteType.playlist) {
      if (isCurrentlyFavorite) {
        state.favoritePlaylists.remove(videoId);
      } else {
        state.favoritePlaylists.add(videoId);
      }
    } else if (type == FavoriteType.genre) {
      if (isCurrentlyFavorite) {
        state.favoriteGenres.remove(videoId);
      } else {
        state.favoriteGenres.add(videoId);
      }
    }

    emit(state.copyWith());

    // Notificar a otros widgets
    _favoritesController.add(
      FavoriteEvent(type: type, id: videoId, isFavorite: !isCurrentlyFavorite),
    );

    try {
      final params = ToggleFavoriteParams(
        type: type,
        videoId: videoId,
        isCurrentlyFavorite: isCurrentlyFavorite,
        songId: songId ?? state.getSongIdForVideoId(videoId),
        metadata: metadata,
        playlistMetadata: playlistMetadata,
      );

      final result = await _toggleFavoriteUseCase(params);
      
      result.fold(
        (error) => throw error,
        (_) {
          // Additional optimistic cache syncs
          if (type == FavoriteType.playlist) {
            if (isCurrentlyFavorite) {
              _removePlaylistFromOfflineCache(videoId);
            } else {
              _syncPlaylistToOfflineCache(
                externalPlaylistId: videoId,
                metadata: playlistMetadata,
              );
            }
          }
        },
      );
    } catch (e) {
      // Rollback en caso de error
      emit(
        FavoriteState(
          favoriteSongs: previousSongs,
          favoritePlaylists: previousPlaylists,
          favoriteGenres: previousGenres,
          error: _parseError(e),
        ),
      );

      // Notificar rollback
      _favoritesController.add(
        FavoriteEvent(type: type, id: videoId, isFavorite: isCurrentlyFavorite),
      );

      if (kDebugMode) {
        debugPrint('Error toggling favorite: $e');
      }
    }
  }

  /// Cargar favoritos desde el backend
  Future<void> loadFavorites() async {
    if (state.isLoading) return;

    emit(state.copyWith(isLoading: true));

    try {
      final result = await _loadFavoritesUseCase(page: 1, limit: 100);

      if (isClosed) return;

      final data = result.fold(
        (error) => throw error,
        (data) => data,
      );

      emit(
        FavoriteState(
          favoriteSongs: data.songs.songs.map((s) => s.videoId).toSet(),
          favoritePlaylists: data.playlists
              .map((p) => p.externalPlaylistId)
              .toSet(),
          favoriteGenres: data.genres.map((g) => g.externalParams).toSet(),
          songIdByVideoId: data.songs.songIdByVideoId,
          isLoading: false,
        ),
      );

      final favoritePlaylists = data.playlists
          .map(
            (p) => FavoritePlaylist(
              id: p.id,
              playlistId: p.externalPlaylistId,
              externalPlaylistId: p.externalPlaylistId,
              name: p.name,
              description: p.description,
              thumbnail: p.thumbnail,
              trackCount: p.trackCount,
              createdAt: DateTime.now(),
            ),
          )
          .toList();
      _syncAllPlaylistsToOfflineCache(favoritePlaylists);
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, error: _parseError(e)));
    }
  }

  /// Sincroniza una playlist al caché offline (fire and forget)
  ///
  /// Este método no bloquea la UI ni causa rollback si falla.
  /// Verifica conexión antes de intentar sincronizar.
  Future<void> _syncPlaylistToOfflineCache({
    required String externalPlaylistId,
    PlaylistMetadata? metadata,
  }) async {
    try {
      // Verificar conexión antes de sincronizar
      if (!await _offlineService.isOnline) {
        if (kDebugMode) {
          debugPrint('Offline: skipping playlist sync for $externalPlaylistId');
        }
        return;
      }

      // Crear FavoritePlaylist con los datos disponibles
      // Usamos externalPlaylistId como playlistId temporal hasta que se recargue
      final playlistData = FavoritePlaylist(
        id: '',
        playlistId: externalPlaylistId,
        externalPlaylistId: externalPlaylistId,
        name: metadata?.name ?? '',
        description: metadata?.description,
        thumbnail: metadata?.thumbnail,
        trackCount: null,
        createdAt: DateTime.now(),
      );

      // Sincronizar con caché offline
      await _playlistOfflineCubit.syncPlaylist(playlistData);

      if (kDebugMode) {
        debugPrint('Playlist synced to offline cache: $externalPlaylistId');
      }
    } catch (e) {
      // Log error pero no propagar - es fire and forget
      if (kDebugMode) {
        debugPrint('Error syncing playlist to offline cache: $e');
      }
    }
  }

  /// Elimina una playlist del caché offline (fire and forget)
  ///
  /// Este método no bloquea la UI ni causa rollback si falla.
  Future<void> _removePlaylistFromOfflineCache(String playlistId) async {
    try {
      await _playlistOfflineCubit.removeOfflinePlaylist(playlistId);

      if (kDebugMode) {
        debugPrint('Playlist removed from offline cache: $playlistId');
      }
    } catch (e) {
      // Log error pero no propagar - es fire and forget
      if (kDebugMode) {
        debugPrint('Error removing playlist from offline cache: $e');
      }
    }
  }

  /// Sincroniza todas las playlists favoritas con el caché offline (fire and forget)
  ///
  /// Este método no bloquea la UI ni causa rollback si falla.
  /// Verifica conexión antes de intentar sincronizar.
  Future<void> _syncAllPlaylistsToOfflineCache(
    List<FavoritePlaylist> playlists,
  ) async {
    try {
      // Verificar conexión antes de sincronizar
      if (!await _offlineService.isOnline) {
        if (kDebugMode) {
          debugPrint('Offline: skipping sync all playlists');
        }
        return;
      }

      await _playlistOfflineCubit.syncAllFavoritePlaylists(playlists);

      if (kDebugMode) {
        debugPrint(
          'All favorite playlists synced to offline cache: ${playlists.length}',
        );
      }
    } catch (e) {
      // Log error pero no propagar - es fire and forget
      if (kDebugMode) {
        debugPrint('Error syncing all playlists to offline cache: $e');
      }
    }
  }

  /// Reproduce una canción específica
  /// NO disparamos LoadTrackEvent aquí - PlayerScreen lo hace
  NowPlayingData playSong(FavoriteSong song) {
    final nowPlayingData = _mapToNowPlaying(song);
    return nowPlayingData;
  }

  /// Reproduce todas las canciones
  /// Si ya hay una canción de la lista reproduciéndose, continúa desde esa posición
  void playAllSongs(List<FavoriteSong> songs) {
    if (songs.isEmpty) return;

    final playlist = songs.map(_mapToNowPlaying).toList();

    // Verificar si hay una canción reproduciéndose actualmente que esté en la playlist
    int startIndex = 0;
    final currentTrack = _playerBloc.state.currentTrack;

    if (currentTrack != null) {
      // Buscar el índice de la canción actual en la nueva playlist
      final currentIndex = playlist.indexWhere(
        (track) => track.videoId == currentTrack.videoId,
      );
      if (currentIndex != -1) {
        startIndex = currentIndex;
      }
    }

    _playerBloc.add(
      LoadPlaylistEvent(
        playlist: playlist,
        startIndex: startIndex,
        sourceId: 'favorites',
      ),
    );
  }

  /// Elimina una canción de favoritos
  void removeSong(FavoriteSong song) {
    toggleFavorite(
      videoId: song.videoId,
      songId: song.songId,
      type: FavoriteType.song,
      isCurrentlyFavorite: true,
    );
  }

  NowPlayingData _mapToNowPlaying(FavoriteSong song) {
    return NowPlayingData.fromBasic(
      videoId: song.videoId,
      title: song.title,
      artistNames: song.artist.split(', '),
      albumName: '',
      duration: song.duration != null
          ? _formatDuration(song.duration!)
          : '0:00',
      durationSeconds: song.duration,
      thumbnailUrl: song.thumbnail,
      streamUrl: song.streamUrl,
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  String _parseError(dynamic error) {
    if (error is AppException) {
      return getErrorMessage(error);
    }
    return error?.toString() ?? 'An error occurred';
  }

  @override
  Future<void> close() {
    _favoritesController.close();
    return super.close();
  }
}
