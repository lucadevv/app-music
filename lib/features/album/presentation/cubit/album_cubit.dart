// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/bloc/base_bloc_mixin.dart';
import 'package:music_app/features/album/domain/entities/album.dart';
import 'package:music_app/features/album/domain/use_cases/get_album_songs_use_case.dart';
import 'package:music_app/features/album/domain/use_cases/get_album_use_case.dart';
import 'package:music_app/features/album/domain/use_cases/is_liked_album_use_case.dart';
import 'package:music_app/features/album/domain/use_cases/like_album_use_case.dart';
import 'package:music_app/features/album/domain/use_cases/unlike_album_use_case.dart';
import 'package:music_app/features/dashboard/presentation/bloc/player_bloc_bloc.dart';
import 'package:music_app/features/player/domain/entities/now_playing_data.dart';

part 'album_state.dart';

class AlbumCubit extends Cubit<AlbumState> with BaseBlocMixin {
  final GetAlbumUseCase _getAlbumUseCase;
  final GetAlbumSongsUseCase _getAlbumSongsUseCase;
  final LikeAlbumUseCase _likeAlbumUseCase;
  final UnlikeAlbumUseCase _unlikeAlbumUseCase;
  final IsLikedAlbumUseCase _isLikedAlbumUseCase;
  final PlayerBlocBloc _playerBloc;
  String? _currentAlbumId;

  AlbumCubit({
    required GetAlbumUseCase getAlbumUseCase,
    required GetAlbumSongsUseCase getAlbumSongsUseCase,
    required LikeAlbumUseCase likeAlbumUseCase,
    required UnlikeAlbumUseCase unlikeAlbumUseCase,
    required IsLikedAlbumUseCase isLikedAlbumUseCase,
    required PlayerBlocBloc playerBloc,
  }) : _getAlbumUseCase = getAlbumUseCase,
       _getAlbumSongsUseCase = getAlbumSongsUseCase,
       _likeAlbumUseCase = likeAlbumUseCase,
       _unlikeAlbumUseCase = unlikeAlbumUseCase,
       _isLikedAlbumUseCase = isLikedAlbumUseCase,
       _playerBloc = playerBloc,
       super(const AlbumState());

  Future<void> loadAlbum(String albumId) async {
    if (state.status == AlbumStatus.loading) return;

    _currentAlbumId = albumId;
    emit(state.copyWith(status: AlbumStatus.loading));

    try {
      // Load album details and songs in parallel
      final results = await Future.wait([
        _getAlbumUseCase(albumId),
        _getAlbumSongsUseCase(albumId),
        _isLikedAlbumUseCase(albumId),
      ]);

      if (isClosed) return;

      emit(
        AlbumState(
          status: AlbumStatus.success,
          album: results[0] as Album,
          songs: results[1] as List<AlbumSong>,
          isLiked: results[2] as bool,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(status: AlbumStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> toggleLike() async {
    final albumId = _currentAlbumId;
    if (albumId == null) return;

    try {
      if (state.isLiked) {
        await _unlikeAlbumUseCase(albumId);
      } else {
        await _likeAlbumUseCase(albumId);
      }

      if (isClosed) return;
      emit(state.copyWith(isLiked: !state.isLiked));
    } catch (e) {
      // Handle error silently
    }
  }

  bool playSong(AlbumSong song, List<AlbumSong> allSongs) {
    if (song.videoId.isEmpty) {
      emit(state.copyWith(errorMessage: 'ID de canción inválido'));
      return false;
    }

    // NO disparamos LoadTrackEvent aquí - PlayerScreen lo hace
    // Solo preparamos los datos y retornamos true
    return true;
  }

  NowPlayingData? playAllAlbumSongs(
    List<AlbumSong> songs, {
    int startIndex = 0,
  }) {
    if (songs.isEmpty) return null;

    final validSongs = songs
        .where((s) => s.videoId.isNotEmpty)
        .toList();

    if (validSongs.isEmpty) return null;

    if (startIndex < 0 || startIndex >= validSongs.length) {
      startIndex = 0;
    }

    final playlist = validSongs.map(mapAlbumSongToNowPlaying).toList();

    _playerBloc.add(
      LoadPlaylistEvent(
        playlist: playlist,
        startIndex: startIndex,
        sourceId: 'album:$_currentAlbumId',
      ),
    );

    return playlist[startIndex];
  }

  NowPlayingData mapAlbumSongToNowPlaying(AlbumSong song) {
    final albumName = state.album?.title ?? '';
    final artistName = state.album?.artistName ?? 'Unknown Artist';
    return NowPlayingData.fromBasic(
      videoId: song.videoId,
      title: song.title,
      artistNames: [artistName],
      albumName: albumName,
      duration: song.formattedDuration,
      durationSeconds: song.durationSeconds,
      thumbnailUrl: song.thumbnail,
      streamUrl: song.streamUrl,
    );
  }
}
