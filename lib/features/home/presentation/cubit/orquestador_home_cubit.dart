import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/features/home/domain/entities/chart_playlist.dart';
import 'package:music_app/features/home/domain/entities/home_content_item.dart';
import 'package:music_app/features/player/domain/entities/now_playing_data.dart';
import 'package:music_app/features/playlist/presentation/cubit/playlist_state.dart';

import '../../../mood_genre/presentation/cubit/mood_genre_cubit.dart'
    show MoodGenreCubit, MoodGenreState, MoodGenreStatus;
import '../../../playlist/presentation/cubit/playlist_cubit.dart'
    show PlaylistCubit;
import 'home_cubit.dart' show HomeCubit, HomeState, HomeStatus;

part 'orquestador_home_effect.dart';
part 'orquestador_home_state.dart';

/// Orquestador principal del flujo del home
/// Coordina el flujo completo del home y sus pantallas hijas
class OrquestadorHomeCubit extends Cubit<OrquestadorHomeState> {
  final HomeCubit _homeCubit;
  MoodGenreCubit? _moodGenreCubit;
  PlaylistCubit? _playlistCubit;

  StreamSubscription? _homeSubscription;
  StreamSubscription? _moodGenreSubscription;
  StreamSubscription? _playlistSubscription;

  OrquestadorHomeCubit({required HomeCubit homeCubit})
    : _homeCubit = homeCubit,
      super(OrquestadorHomeState.initial()) {
    _startListening();
  }

  void _startListening() {
    // Escuchar cambios del HomeCubit
    _homeSubscription = _homeCubit.stream.listen(_updateHomeState);
  }

  /// Registra un MoodGenreCubit para escuchar sus cambios
  void registerMoodGenreCubit(MoodGenreCubit moodGenreCubit) {
    if (_moodGenreCubit != null) {
      _moodGenreSubscription?.cancel();
    }
    _moodGenreCubit = moodGenreCubit;
    _moodGenreSubscription = _moodGenreCubit!.stream.listen(
      _updateMoodGenreState,
    );
    // Actualizar el estado inicial
    _updateMoodGenreState(moodGenreCubit.state);
  }

  /// Registra un PlaylistCubit para escuchar sus cambios
  void registerPlaylistCubit(PlaylistCubit playlistCubit) {
    if (_playlistCubit != null) {
      _playlistSubscription?.cancel();
    }
    _playlistCubit = playlistCubit;
    _playlistSubscription = _playlistCubit!.stream.listen(_updatePlaylistState);
    // Actualizar el estado inicial
    _updatePlaylistState(playlistCubit.state);
  }

  void _updateHomeState(HomeState state) {
    // Si hay un error, emitir el effect correspondiente
    if (state.status == HomeStatus.failure) {
      emit(
        this.state.copyWith(
          homeState: state,
          hasError: true,
          errorMessage: state.errorMessage,
          effect: ShowErrorEffect(
            state.errorMessage ?? 'Error al cargar el home',
          ),
        ),
      );
    } else {
      // Limpiar errores si hay éxito o está en otro estado
      emit(
        this.state.copyWith(
          homeState: state,
          hasError: false,
          errorMessage: null,
        ),
      );
    }
  }

  void _updateMoodGenreState(MoodGenreState state) {
    // Si hay un error, emitir el effect correspondiente
    if (state.status == MoodGenreStatus.failure) {
      emit(
        this.state.copyWith(
          moodGenreState: state,
          hasError: true,
          errorMessage: state.errorMessage,
          effect: ShowErrorEffect(
            state.errorMessage ?? 'Error al cargar las playlists',
          ),
        ),
      );
    } else {
      // Limpiar errores si hay éxito o está en otro estado
      emit(
        this.state.copyWith(
          moodGenreState: state,
          hasError: false,
          errorMessage: null,
        ),
      );
    }
  }

  void _updatePlaylistState(PlaylistState state) {
    // Si hay un error, emitir el effect correspondiente
    if (state.status == PlaylistStatus.failure) {
      emit(
        this.state.copyWith(
          playlistState: state,
          hasError: true,
          errorMessage: state.errorMessage,
          effect: ShowErrorEffect(
            state.errorMessage ?? 'Error al cargar la playlist',
          ),
        ),
      );
    } else {
      // Limpiar errores si hay éxito o está en otro estado
      emit(
        this.state.copyWith(
          playlistState: state,
          hasError: false,
          errorMessage: null,
        ),
      );
    }
  }

  /// Actualiza el estado del home manualmente (para compatibilidad)
  void updateHomeState(HomeState state) {
    _updateHomeState(state);
  }

  /// Filtra el contenido del HomeCubit
  void filterHome(String query) {
    _homeCubit.filterHome(query);
  }

  /// Actualiza el estado de mood/genre manualmente (para compatibilidad)
  void updateMoodGenreState(MoodGenreState state) {
    _updateMoodGenreState(state);
  }

  /// Actualiza el estado de playlist manualmente (para compatibilidad)
  void updatePlaylistState(PlaylistState state) {
    _updatePlaylistState(state);
  }

  /// Reinicia el estado del home
  void resetHomeState() {
    _homeCubit.reset();
    emit(
      state.copyWith(homeState: const HomeState(status: HomeStatus.initial)),
    );
  }

  /// Reinicia el estado de mood/genre
  void resetMoodGenreState() {
    _moodGenreCubit?.reset();
    emit(state.copyWith(moodGenreState: const MoodGenreState()));
  }

  /// Reinicia el estado de playlist
  void resetPlaylistState() {
    _playlistCubit?.reset();
    emit(state.copyWith(playlistState: const PlaylistState()));
  }

  /// Limpia el effect después de procesarlo
  void clearEffect() {
    emit(state.copyWith(effect: null));
  }

  /// Reproduce un HomeContentItem como una sola canción
  /// Retorna el NowPlayingData para navegación
  NowPlayingData? playContentItemAsSingle(HomeContentItem item) {
    return _homeCubit.playContentItemAsSingle(item);
  }

  /// Navega a una playlist de chart
  /// Retorna el NowPlayingData para navegación
  NowPlayingData playChartPlaylist(ChartPlaylist playlist) {
    return _homeCubit.playChartPlaylist(playlist);
  }

  /// Reproduce un contenido completo (playlist)
  void playContentItem(HomeContentItem item) {
    _homeCubit.playContentItem(item);
  }

  /// Reinicia todo el flujo
  void reset() {
    _homeCubit.reset();
    _moodGenreCubit?.reset();
    _playlistCubit?.reset();
    emit(OrquestadorHomeState.initial());
  }

  @override
  Future<void> close() {
    _homeSubscription?.cancel();
    _moodGenreSubscription?.cancel();
    _playlistSubscription?.cancel();
    return super.close();
  }
}
