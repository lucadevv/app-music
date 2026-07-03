import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/features/player/domain/entities/now_playing_data.dart';
import 'package:music_app/features/player/domain/services/audio_session_controller.dart';
import 'package:music_app/features/player/domain/types/player_types.dart';
import 'package:music_app/features/profile/presentation/cubit/profile_cubit.dart';

part 'player_bloc_event.dart';
part 'player_bloc_state.dart';

class PlayerBlocBloc extends Bloc<PlayerBlocEvent, PlayerBlocState> {
  final AudioSessionController _sessionController;

  ProfileCubit? _profileCubit;
  set profileCubit(ProfileCubit cubit) => _profileCubit = cubit;

  final _playlistPlaybackStartedController =
      StreamController<PlaylistPlaybackStartedEvent>.broadcast();
  Stream<PlaylistPlaybackStartedEvent> get playlistPlaybackStartedStream =>
      _playlistPlaybackStartedController.stream;

  String? _lastLoadedVideoId;
  String? _lastLoadedSourceId;
  bool _isLoadingTrack = false;

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _bufferedPositionSubscription;
  StreamSubscription? _currentIndexSubscription;

  PlayerBlocBloc({required AudioSessionController sessionController})
    : _sessionController = sessionController,
      super(PlayerBlocState.initial()) {
    _registerEventHandlers();
    _initializeEngineListeners();
  }

  void _initializeEngineListeners() {
    _playerStateSubscription = _sessionController.playerStateStream.listen(
      (s) => add(AudioPlayerStateChangedEvent(s)),
    );
    _positionSubscription = _sessionController.positionStream.listen(
      (p) => add(PositionChangedEvent(p)),
    );
    _durationSubscription = _sessionController.durationStream.listen(
      (d) => add(DurationChangedEvent(d ?? Duration.zero)),
    );
    _bufferedPositionSubscription = _sessionController.bufferedPositionStream
        .listen((p) => add(BufferedPositionChangedEvent(p)));
    _currentIndexSubscription = _sessionController.currentIndexStream.listen(
      (i) => add(CurrentIndexChangedEvent(i)),
    );
  }

  void _registerEventHandlers() {
    on<PlayEvent>((_, emit) async => _sessionController.play());
    on<PauseEvent>((_, emit) async => _sessionController.pause());
    on<StopEvent>(_onStop);
    on<PlayPauseToggleEvent>(
      (_, emit) =>
          add(state.isPlaying ? const PauseEvent() : const PlayEvent()),
    );

    on<NextTrackEvent>(_onNextTrack);
    on<PreviousTrackEvent>(_onPreviousTrack);
    on<SeekEvent>((e, _) async => _sessionController.seek(e.position));

    on<PlayRequestEvent>(_onPlayRequest);
    on<LoadTrackEvent>(_onLoadTrack);
    on<LoadPlaylistEvent>(_onLoadPlaylist);
    on<PlayTrackAtIndexEvent>(_onPlayTrackAtIndex);
    on<AddToPlaylistEvent>(_onAddToPlaylist);
    on<AddMultipleToPlaylistEvent>(_onAddMultipleToPlaylist);
    on<RemoveFromPlaylistEvent>(_onRemoveFromPlaylist);

    on<SetVolumeEvent>((e, emit) async {
      await _sessionController.setVolume(e.volume);
      emit(state.copyWith(volume: e.volume));
    });
    on<SetSpeedEvent>((e, emit) async {
      await _sessionController.setSpeed(e.speed);
      emit(state.copyWith(speed: e.speed));
    });
    on<SetLoopModeEvent>((e, emit) async {
      await _sessionController.setLoopMode(e.loopMode);
      emit(state.copyWith(loopMode: e.loopMode));
    });
    on<ToggleShuffleEvent>((_, emit) async {
      final newState = !state.isShuffleEnabled;
      await _sessionController.setShuffleModeEnabled(newState);
      emit(state.copyWith(isShuffleEnabled: newState));
    });

    on<AudioPlayerStateChangedEvent>(_onAudioPlayerStateChanged);
    on<PositionChangedEvent>(_onPositionChanged);
    on<DurationChangedEvent>(
      (e, emit) => emit(state.copyWith(duration: e.duration)),
    );
    on<BufferedPositionChangedEvent>(
      (e, emit) => emit(state.copyWith(bufferedPosition: e.bufferedPosition)),
    );
    on<CurrentIndexChangedEvent>(_onCurrentIndexChanged);
    on<AudioErrorEvent>(
      (e, emit) => emit(
        state.copyWith(
          error: e.error,
          processingState: ProcessingStateType.idle,
        ),
      ),
    );

    on<InitializeAudioServiceEvent>(
      (_, emit) =>
          emit(state.copyWith(connectionState: AudioConnectionState.connected)),
    );
    on<DisposeAudioServiceEvent>(
      (_, emit) => emit(
        state.copyWith(connectionState: AudioConnectionState.disconnected),
      ),
    );
    on<ResetPlayerEvent>(_onResetPlayer);
    on<PlaylistPlaybackStartedEvent>(
      (e, _) =>
          debugPrint('PlayerBloc: Playlist playback started - ${e.sourceId}'),
    );
  }

  Future<void> _onStop(_, Emitter<PlayerBlocState> emit) async {
    await _sessionController.stop();
    emit(state.copyWith(position: Duration.zero));
  }

  Future<void> _onNextTrack(_, Emitter<PlayerBlocState> emit) async {
    if (state.canPlayNext) await _sessionController.seekToNext();
  }

  Future<void> _onPreviousTrack(_, Emitter<PlayerBlocState> emit) async {
    if (state.canPlayPrevious) await _sessionController.seekToPrevious();
  }

  Future<void> _onPlayRequest(
    PlayRequestEvent e,
    Emitter<PlayerBlocState> emit,
  ) async {
    if (state.currentTrack?.videoId == e.track.videoId) {
      if (!state.isPlaying) add(const PlayEvent());
      return;
    }
    if (e.playAsSingle) {
      await _handleLoadTrack(e.track, 'single:${e.track.videoId}', emit);
      return;
    }
    final idx = state.playlist.indexWhere((t) => t.videoId == e.track.videoId);
    if (idx >= 0) {
      await _handlePlayTrackAtIndex(idx, emit);
    } else {
      await _handleLoadTrack(e.track, null, emit);
    }
  }

  Future<void> _onLoadTrack(
    LoadTrackEvent e,
    Emitter<PlayerBlocState> emit,
  ) async {
    await _handleLoadTrack(e.track, e.sourceId, emit);
  }

  Future<void> _handleLoadTrack(
    NowPlayingData track,
    String? sourceId,
    Emitter<PlayerBlocState> emit,
  ) async {
    if (_isLoadingTrack &&
        _lastLoadedVideoId == track.videoId &&
        _lastLoadedSourceId == sourceId) {
      return;
    }

    _isLoadingTrack = true;
    _lastLoadedVideoId = track.videoId;
    _lastLoadedSourceId = sourceId;

    try {
      emit(
        state.copyWith(
          isLoading: true,
          error: null,
          currentTrack: track,
          currentIndex: 0,
          playlist: [track],
          sourceId: sourceId,
        ),
      );

      final streamUrl = await _sessionController.loadSingleTrack(track);

      if (streamUrl == null) {
        emit(state.copyWith(isLoading: false, error: 'No se pudo obtener URL'));
        return;
      }

      final duration = Duration(
        seconds: track.durationSeconds > 0 ? track.durationSeconds : 0,
      );

      emit(
        state.copyWith(
          playbackState: PlaybackState.playing,
          processingState: ProcessingStateType.ready,
          connectionState: AudioConnectionState.connected,
          currentTrack: track,
          currentStreamUrl: streamUrl,
          currentIndex: 0,
          duration: duration,
          position: Duration.zero,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e) {
      if (e.toString().contains('Loading interrupted')) {
        debugPrint(
          'PlayerBloc: Loading interrupted (superseded by new track request)',
        );
        return;
      }
      debugPrint('PlayerBloc: Error loading track: $e');
      emit(state.copyWith(isLoading: false, error: 'Error al cargar: $e'));
    } finally {
      if (_lastLoadedVideoId == track.videoId &&
          _lastLoadedSourceId == sourceId) {
        _isLoadingTrack = false;
        _lastLoadedVideoId = null;
        _lastLoadedSourceId = null;
      }
    }
  }

  Future<void> _handlePlayTrackAtIndex(
    int index,
    Emitter<PlayerBlocState> emit,
  ) async {
    if (index < 0 || index >= state.playlist.length) return;
    final track = state.playlist[index];

    if (state.currentIndex == index &&
        state.currentTrack?.videoId == track.videoId) {
      if (!state.isPlaying) {
        await _sessionController.play();
        emit(state.copyWith(playbackState: PlaybackState.playing));
      }
      return;
    }

    await _sessionController.seekToIndex(index);
    await _sessionController.play();
    _sessionController.updateHandlerMediaItem(track);

    emit(
      state.copyWith(
        playbackState: PlaybackState.playing,
        currentIndex: index,
        currentTrack: track,
        currentStreamUrl: track.streamUrl,
      ),
    );
  }

  Future<void> _onLoadPlaylist(
    LoadPlaylistEvent e,
    Emitter<PlayerBlocState> emit,
  ) async {
    if (e.playlist.isEmpty) {
      emit(state.copyWith(isLoading: false, error: 'Playlist vacía'));
      return;
    }

    final startIdx = (e.startIndex ?? 0).clamp(0, e.playlist.length - 1);
    final initialTrack = e.playlist.isNotEmpty ? e.playlist[startIdx] : null;

    emit(
      state.copyWith(
        isLoading: true,
        error: null,
        currentTrack: initialTrack,
        sourceId: e.sourceId,
      ),
    );

    try {
      final loadedPlaylist = await _sessionController.loadPlaylist(
        e.playlist,
        startIndex: startIdx,
      );

      // Encontrar el verdaredro startIndex dentro del nuevo loadedPlaylist
      int actualIndex = 0;
      final originalTarget = e.playlist[startIdx];
      final newIndex = loadedPlaylist.indexWhere(
        (t) => t.videoId == originalTarget.videoId,
      );
      if (newIndex >= 0) actualIndex = newIndex;

      final first = loadedPlaylist[actualIndex];
      final duration = Duration(
        seconds: first.durationSeconds > 0 ? first.durationSeconds : 0,
      );

      emit(
        state.copyWith(
          playbackState: PlaybackState.playing,
          playlist: loadedPlaylist,
          isLoading: false,
          connectionState: AudioConnectionState.connected,
          currentIndex: actualIndex,
          currentTrack: first,
          currentStreamUrl: first.streamUrl,
          duration: duration,
          position: Duration.zero,
          sourceId: e.sourceId,
          error: null,
        ),
      );

      _playlistPlaybackStartedController.add(
        PlaylistPlaybackStartedEvent(sourceId: e.sourceId),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onPlayTrackAtIndex(
    PlayTrackAtIndexEvent e,
    Emitter<PlayerBlocState> emit,
  ) async {
    await _handlePlayTrackAtIndex(e.index, emit);
  }

  Future<void> _onAddToPlaylist(
    AddToPlaylistEvent e,
    Emitter<PlayerBlocState> emit,
  ) async {
    if (state.playlist.any((t) => t.videoId == e.track.videoId)) return;

    try {
      await _sessionController.addToQueue(e.track);
      emit(state.copyWith(playlist: [...state.playlist, e.track]));
    } catch (err) {
      emit(state.copyWith(error: err.toString()));
    }
  }

  Future<void> _onAddMultipleToPlaylist(
    AddMultipleToPlaylistEvent e,
    Emitter<PlayerBlocState> emit,
  ) async {
    final existing = state.playlist.map((t) => t.videoId).toSet();
    final valid = e.tracks
        .where(
          (t) =>
              t.streamUrl != null &&
              t.streamUrl!.isNotEmpty &&
              !existing.contains(t.videoId),
        )
        .toList();
    if (valid.isEmpty) return;

    await _sessionController.addMultipleToQueue(valid);
    emit(state.copyWith(playlist: [...state.playlist, ...valid]));
  }

  Future<void> _onRemoveFromPlaylist(
    RemoveFromPlaylistEvent e,
    Emitter<PlayerBlocState> emit,
  ) async {
    if (e.index < 0 || e.index >= state.playlist.length) return;

    final removed = state.playlist[e.index];
    final wasCurrent = state.currentTrack?.videoId == removed.videoId;
    final newPlaylist = List<NowPlayingData>.from(state.playlist)
      ..removeAt(e.index);

    await _sessionController.removeFromQueue(e.index);

    if (wasCurrent) {
      if (newPlaylist.isEmpty) {
        await _sessionController.stop();
        emit(
          state.copyWith(
            playlist: [],
            clearCurrentIndex: true,
            clearCurrentTrack: true,
            currentStreamUrl: null,
            playbackState: PlaybackState.stopped,
            processingState: ProcessingStateType.idle,
            position: Duration.zero,
          ),
        );
        return;
      }
      final safeIdx = e.index >= newPlaylist.length
          ? newPlaylist.length - 1
          : e.index;
      final next = newPlaylist[safeIdx];
      await _sessionController.seekToIndex(safeIdx);
      emit(
        state.copyWith(
          playlist: newPlaylist,
          currentIndex: safeIdx,
          currentTrack: next,
          currentStreamUrl: next.streamUrl,
        ),
      );
      return;
    }
    emit(state.copyWith(playlist: newPlaylist));
  }

  Future<void> _onAudioPlayerStateChanged(
    AudioPlayerStateChangedEvent e,
    Emitter<PlayerBlocState> emit,
  ) async {
    final prevProcessing = state.processingState;
    final pbState = e.playerState.isPlaying
        ? PlaybackState.playing
        : PlaybackState.paused;

    emit(
      state.copyWith(
        playbackState: pbState,
        processingState: e.playerState.processingState,
      ),
    );

    if (prevProcessing != ProcessingStateType.completed &&
        e.playerState.processingState == ProcessingStateType.completed) {
      await _handleAutoPlay();
    }
  }

  Future<void> _handleAutoPlay() async {
    final autoPlay = _profileCubit?.state.settings?.autoPlay ?? true;
    if (!autoPlay || state.loopMode == LoopModeType.one) return;
    if (state.canPlayNext) {
      add(const NextTrackEvent());
    } else if (state.loopMode == LoopModeType.all &&
        state.playlist.isNotEmpty) {
      add(const PlayTrackAtIndexEvent(0));
    }
  }

  Future<void> _onPositionChanged(
    PositionChangedEvent e,
    Emitter<PlayerBlocState> emit,
  ) async {
    emit(state.copyWith(position: e.position));
    await _sessionController.trackPositionUpdate(e.position);
  }

  Future<void> _onCurrentIndexChanged(
    CurrentIndexChangedEvent e,
    Emitter<PlayerBlocState> emit,
  ) async {
    final track = e.index != null && e.index! < state.playlist.length
        ? state.playlist[e.index!]
        : null;

    if (track != null && e.index != state.currentIndex) {
      _sessionController.updateHandlerMediaItem(track);
      await _sessionController.trackListenEvent(track);
    }
    emit(state.copyWith(currentIndex: e.index, currentTrack: track));
  }

  Future<void> _onResetPlayer(_, Emitter<PlayerBlocState> emit) async {
    await _sessionController.reset();
    emit(PlayerBlocState.initial());
  }

  @override
  Future<void> close() async {
    await _sessionController.dispose();
    await _playerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _bufferedPositionSubscription?.cancel();
    await _currentIndexSubscription?.cancel();
    await _playlistPlaybackStartedController.close();
    return super.close();
  }
}
