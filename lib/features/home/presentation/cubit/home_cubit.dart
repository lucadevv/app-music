import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/bloc/base_bloc_mixin.dart';
import 'package:music_app/features/dashboard/presentation/bloc/player_bloc_bloc.dart';
import 'package:music_app/features/home/domain/entities/chart_playlist.dart';
import 'package:music_app/features/home/domain/entities/home_content_item.dart';
import 'package:music_app/features/home/domain/entities/home_response.dart';
import 'package:music_app/features/home/domain/entities/home_section.dart';
import 'package:music_app/features/home/domain/use_cases/get_home_use_case.dart';
import 'package:music_app/features/player/domain/entities/now_playing_data.dart';

part 'home_state.dart';

/// Cubit para manejar el estado del home
///
/// SOLID: Single Responsibility Principle (SRP)
/// Responsable única: Gestionar el estado y lógica del home
///
/// Clean Architecture: Capa de presentación - maneja el estado de la UI
class HomeCubit extends Cubit<HomeState> with BaseBlocMixin {
  final GetHomeUseCase _getHomeUseCase;
  final PlayerBlocBloc _playerBloc;

  HomeCubit(this._getHomeUseCase, this._playerBloc) : super(const HomeState());

  /// Carga los datos del home
  Future<void> loadHome() async {
    if (state.status == HomeStatus.loading) {
      return;
    }

    emit(state.copyWith(status: HomeStatus.loading, clearError: true));

    final result = await _getHomeUseCase();

    if (isClosed) return;

    result.fold(
      (error) {
        final String errorMessage = getErrorMessage(error);
        emit(
          state.copyWith(
            status: HomeStatus.failure,
            errorMessage: errorMessage,
          ),
        );
      },
      (homeResponse) {
        emit(
          state.copyWith(
            status: HomeStatus.success,
            homeResponse: homeResponse,
            clearError: true,
          ),
        );
      },
    );
  }

  /// Reproduce una canción de un item de contenido
  void playContentItem(HomeContentItem item) {
    final nowPlaying = _mapContentItemToNowPlaying(item);
    if (nowPlaying == null) return;
    final playlist = [nowPlaying];
    _playerBloc.add(
      LoadPlaylistEvent(playlist: playlist, startIndex: 0, sourceId: 'home'),
    );
  }

  /// Filtra las secciones del home en base a un string de búsqueda.
  void filterHome(String query) {
    emit(state.copyWith(filterQuery: query));
  }

  /// Reproduce una canción específica de un item de contenido
  void playContentItemTrack(HomeContentItem item, int trackIndex) {
    final nowPlaying = _mapContentItemToNowPlaying(item);
    if (nowPlaying == null) return;
    final playlist = [nowPlaying];
    _playerBloc.add(
      LoadPlaylistEvent(
        playlist: playlist,
        startIndex: trackIndex,
        sourceId: 'home',
      ),
    );
  }

  /// Reproduce un HomeContentItem como una sola canción (primer track o videoId directo)
  /// Retorna el NowPlayingData para navegación
  NowPlayingData? playContentItemAsSingle(HomeContentItem item) {
    // DEBUG: Verificar que el item tiene los datos correctos
    debugPrint('DEBUG playContentItemAsSingle:');
    debugPrint('  - contentType: ${item.contentType}');
    debugPrint('  - videoId: ${item.videoId}');
    debugPrint('  - title: ${item.title}');
    debugPrint('  - streamUrl: ${item.streamUrl}');
    debugPrint(
      '  - has streamUrl: ${item.streamUrl != null && item.streamUrl!.isNotEmpty}',
    );

    NowPlayingData? nowPlayingData;

    // Determinar tipo de contenido usando PATTERN MATCHING DART 3
    switch (item) {
      case final HomeSongItem song:
        // Es una canción - reproducir directamente
        if (song.videoId.isNotEmpty) {
          nowPlayingData = NowPlayingData.fromBasic(
            videoId: song.videoId,
            title: song.title,
            artistNames: song.artists.map((a) => a.name).toList(),
            albumName: song.album?.name ?? '',
            albumId: song.album?.id,
            duration: '0:00',
            views: song.views,
            isExplicit: song.isExplicit,
            thumbnails: song.thumbnails,
            thumbnail: song.thumbnail,
            streamUrl: song.streamUrl,
          );
          debugPrint(
            'DEBUG: Creando NowPlayingData con streamUrl: ${nowPlayingData.streamUrl}',
          );
          // NO disparamos LoadTrackEvent aquí - PlayerScreen lo hace
          return nowPlayingData;
        }
        break;

      case HomeAlbumItem _:
        // Es un álbum - no se reproduce directamente, se navega al álbum
        debugPrint('DEBUG: Es un álbum, no se reproduce directamente');
        break;

      case HomePlaylistItem _:
        // Es una playlist - no se reproduce directamente, se navega a la playlist
        debugPrint('DEBUG: Es una playlist, no se reproduce directamente');
        break;

      case HomeUnknownItem _:
        debugPrint('DEBUG: Tipo desconocido');
        break;
    }

    // No hay tracks anidados disponibles en HomeContentItem; retornar lo que haya cargado
    return nowPlayingData;
  }

  /// Navega a una playlist de chart
  /// Retorna el NowPlayingData para navegación
  NowPlayingData playChartPlaylist(ChartPlaylist playlist) {
    final nowPlayingData = NowPlayingData.fromBasic(
      videoId: playlist.playlistId,
      title: playlist.title,
      artistNames: const [],
      albumName: '',
      duration: '0:00',
      durationSeconds: 0,
      thumbnails: playlist.thumbnails,
    );

    return nowPlayingData;
  }

  NowPlayingData? _mapContentItemToNowPlaying(HomeContentItem item) {
    if (item is HomeSongItem && item.videoId.isNotEmpty) {
      return NowPlayingData.fromBasic(
        videoId: item.videoId,
        title: item.title,
        artistNames: item.artists.map((a) => a.name).toList(),
        albumName: item.album?.name ?? '',
        duration: '0:00',
        durationSeconds: 0,
        views: item.views,
        isExplicit: item.isExplicit,
        inLibrary: false,
        thumbnails: item.thumbnails,
        streamUrl: item.streamUrl,
        thumbnailUrl: item.thumbnail?.url ?? item.bestThumbnailUrl,
      );
    }
    return null;
  }

  /// Reinicia el estado
  void reset() {
    emit(const HomeState());
  }
}
