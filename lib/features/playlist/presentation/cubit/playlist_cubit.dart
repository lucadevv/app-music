import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/bloc/base_bloc_mixin.dart';
import 'package:music_app/features/dashboard/presentation/bloc/player_bloc_bloc.dart';
import 'package:music_app/features/player/domain/entities/now_playing_data.dart';
import 'package:music_app/features/playlist/domain/entities/playlist_response.dart';
import 'package:music_app/features/playlist/domain/entities/playlist_track.dart';
import 'package:music_app/features/playlist/presentation/cubit/playlist_state.dart';
import '../../domain/use_cases/get_playlist_use_case.dart';

/// Cubit para manejar el estado de la playlist
///
/// Implementa paginación infinita:
/// - loadPlaylist() carga los primeros 10 tracks
/// - loadMore() carga más tracks (10 por página)
/// - playAll() reproduce la playlist completa (acumula todos los tracks)
class PlaylistCubit extends Cubit<PlaylistState> with BaseBlocMixin {
  final GetPlaylistUseCase _getPlaylistUseCase;
  final PlayerBlocBloc _playerBloc;

  String? _currentPlaylistId;
  static const int _pageSize = 10;
  StreamSubscription? _playbackStartedSubscription;

  PlaylistCubit({
    required GetPlaylistUseCase getPlaylistUseCase,
    required PlayerBlocBloc playerBloc,
  }) : _getPlaylistUseCase = getPlaylistUseCase,
       _playerBloc = playerBloc,
       super(const PlaylistState()) {
    _listenToPlaybackStarted();
  }

  void _listenToPlaybackStarted() {
    _playbackStartedSubscription = _playerBloc.playlistPlaybackStartedStream
        .listen((event) {
          if (event.sourceId == state.loadingPlaylistId &&
              state.isLoadingForPlay) {
            debugPrint(
              'PlaylistCubit: Playback started for playlist ${event.sourceId}',
            );
            completeLoading();
          }
        });
  }

  /// Carga los datos iniciales de una playlist (primeros 10 tracks)
  Future<void> loadPlaylist(String id) async {
    if (state.status == PlaylistStatus.loading) {
      return;
    }

    // Validar que el ID no esté vacío
    if (id.isEmpty) {
      emit(
        state.copyWith(
          status: PlaylistStatus.failure,
          errorMessage: 'El ID de la playlist no puede estar vacío',
        ),
      );
      return;
    }

    _currentPlaylistId = id;
    emit(
      state.copyWith(
        status: PlaylistStatus.loading,
        errorMessage: null,
        currentPage: 0,
        hasMore: true,
        allTracks: [],
      ),
    );

    final result = await _getPlaylistUseCase(
      id,
      startIndex: 0,
      limit: _pageSize,
    );

    result.fold(
      (failure) {
        if (isClosed) return;
        final String errorMessage = getErrorMessage(failure);
        emit(
          state.copyWith(
            status: PlaylistStatus.failure,
            errorMessage: errorMessage,
          ),
        );
      },
      (response) {
        if (isClosed) return;
        final hasMore = response.tracks.length >= _pageSize;
        emit(
          state.copyWith(
            status: PlaylistStatus.success,
            response: response,
            errorMessage: null,
            currentPage: 0,
            hasMore: hasMore,
            allTracks: List.from(response.tracks),
          ),
        );
      },
    );
  }

  /// Carga más tracks (paginación infinita)
  Future<void> loadMore() async {
    // No cargar si ya está cargando, no hay más, o no hay playlist
    if (state.status == PlaylistStatus.loadingMore ||
        !state.hasMore ||
        _currentPlaylistId == null ||
        state.response == null) {
      return;
    }

    emit(state.copyWith(status: PlaylistStatus.loadingMore));

    final nextPage = state.currentPage + 1;
    final startIndex = nextPage * _pageSize;

    final result = await _getPlaylistUseCase(
      _currentPlaylistId!,
      startIndex: startIndex,
      limit: _pageSize,
    );

    result.fold(
      (failure) {
        if (isClosed) return;
        // Si falla, mantener el estado actual
        emit(state.copyWith(status: PlaylistStatus.success));
      },
      (response) {
        if (isClosed) return;
        // Filtrar tracks válidos (no forzar streamUrl para dar cabida a offline/dynamic)
        final validTracks = response.tracks
            .where(
              (track) =>
                  track.videoId != null &&
                  track.isAvailable,
            )
            .toList();

        // Convertir a NowPlayingData
        final nowPlayingTracks = validTracks
            .map(NowPlayingData.fromPlaylistTrack)
            .toList();

        // Si hay una playlist reproduciéndose, agregar los nuevos tracks al player
        final isSamePlaybackContext =
            _playerBloc.state.sourceId == _currentPlaylistId;
        if (isSamePlaybackContext && _playerBloc.state.hasCurrentTrack) {
          _playerBloc.add(AddMultipleToPlaylistEvent(nowPlayingTracks));
        }

        // Acumular los nuevos tracks
        final newTracks = List<PlaylistTrack>.from(state.allTracks)
          ..addAll(response.tracks);

        final hasMore = response.tracks.length >= _pageSize;

        // Actualizar tracks en el response existente (el objeto es inmutable, crear nuevo)
        final updatedTracks = List<PlaylistTrack>.from(state.response!.tracks)
          ..addAll(response.tracks);

        emit(
          state.copyWith(
            status: PlaylistStatus.success,
            currentPage: nextPage,
            hasMore: hasMore,
            allTracks: newTracks,
            // Actualizar el response con los tracks acumulados
            response: _createUpdatedResponse(state.response!, updatedTracks),
          ),
        );
      },
    );
  }

  /// Crea una copia del PlaylistResponse con tracks actualizados
  PlaylistResponse _createUpdatedResponse(
    PlaylistResponse original,
    List<PlaylistTrack> newTracks,
  ) {
    return PlaylistResponse(
      owned: original.owned,
      id: original.id,
      privacy: original.privacy,
      description: original.description,
      views: original.views,
      duration: original.duration,
      trackCount: original.trackCount,
      title: original.title,
      thumbnails: original.thumbnails,
      author: original.author,
      year: original.year,
      related: original.related,
      tracks: newTracks,
      durationSeconds: original.durationSeconds,
    );
  }

  /// Reproduce la playlist desde el inicio
  ///
  /// Los tracks ya tienen streamUrl del endpoint (include_stream_urls=true)
  /// Solo convierte a NowPlayingData y envía toda la playlist al player
  Future<void> playAll() async {
    if (state.response == null) return;
    if (state.isLoadingForPlay) return;

    // Usar los tracks acumulados o los del response
    final availableTracks = state.allTracks.isNotEmpty
        ? state.allTracks
        : state.response!.tracks;

    // Filtrar tracks válidos (sin exigir streamUrl directamente para permitir offline/estrategias)
    final validTracks = availableTracks
        .where(
          (track) =>
              track.videoId != null &&
              track.videoId!.isNotEmpty &&
              track.isAvailable,
        )
        .toList();

    if (validTracks.isEmpty) {
      emit(
        state.copyWith(
          isLoadingForPlay: false,
          errorMessage: 'No hay canciones disponibles para reproducir',
        ),
      );
      return;
    }

    // Convertir a NowPlayingData (ya tienen streamUrl del endpoint)
    final nowPlayingTracks = validTracks
        .map(NowPlayingData.fromPlaylistTrack)
        .toList();

    // Resetear estado de carga con el ID de la playlist
    emit(
      state.copyWith(
        isLoadingForPlay: true,
        loadedCount: 0,
        totalCount: nowPlayingTracks.length,
        loadingPlaylistId: state.response?.id,
      ),
    );

    // Reiniciar el player antes de cargar
    _playerBloc.add(const StopEvent());

    // Pequeño delay para asegurar que el stop se procese
    await Future.delayed(const Duration(milliseconds: 100));

    // Enviar toda la playlist de una vez al PlayerBloc
    // El player se encarga de reproducir la primera canción
    _playerBloc.add(
      LoadPlaylistEvent(
        playlist: nowPlayingTracks,
        startIndex: 0,
        sourceId: state.response?.id, // Identificador de la playlist
      ),
    );

    // NO completamos el loading aquí - lo completamos cuando el player confirma reproducción
    // Esto permite que el widget muestre el loading hasta que realmente reproduzca
  }

  /// Cancela la carga de la playlist
  void cancelLoading() {
    emit(
      state.copyWith(
        isLoadingForPlay: false,
        loadedCount: 0,
        totalCount: 0,
        clearLoadingPlaylistId: true,
      ),
    );
  }

  /// Filtra la playlist guardando el string de búsqueda.
  void filterPlaylist(String query) {
    emit(state.copyWith(filterQuery: query));
  }

  /// Completa el loading cuando el player confirma reproducción
  void completeLoading() {
    emit(
      state.copyWith(
        isLoadingForPlay: false,
        loadedCount: state.totalCount,
        clearLoadingPlaylistId: true,
      ),
    );
  }

  /// Reinicia el estado del cubit
  void reset() {
    _currentPlaylistId = null;
    emit(const PlaylistState());
  }

  @override
  Future<void> close() {
    _playbackStartedSubscription?.cancel();
    return super.close();
  }
}
