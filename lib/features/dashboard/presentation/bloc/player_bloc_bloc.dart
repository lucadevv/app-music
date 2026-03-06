import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/core/services/audio_handler_service.dart';
import 'package:music_app/data/offline/models/offline_history.dart';
import 'package:music_app/data/offline/services/offline_service.dart';
import 'package:music_app/features/player/domain/entities/now_playing_data.dart';
import 'package:music_app/features/profile/presentation/cubit/profile_cubit.dart';

part 'player_bloc_event.dart';
part 'player_bloc_state.dart';

class PlayerBlocBloc extends Bloc<PlayerBlocEvent, PlayerBlocState> {
  // AudioPlayer se obtiene de forma lazy para evitar dependencia circular
  // AudioPlayerHandler se registra en main.dart después de AudioService.init()
  AudioPlayer? _audioPlayerInstance;

  /// Obtiene el player, creando uno nuevo si no está disponible del handler
  AudioPlayer get _audioPlayer {
    if (_audioPlayerInstance == null) {
      try {
        if (GetIt.I.isRegistered<AudioPlayerHandler>()) {
          _audioPlayerInstance = GetIt.I<AudioPlayerHandler>().player;
        } else {
          // Fallback: crear un AudioPlayer básico si el handler no está disponible
          _audioPlayerInstance = AudioPlayer();
          // IMPORTANTE: Inicializar los streams del fallback player
          _initializePlayer();
        }
      } catch (e) {
        // Fallback final
        _audioPlayerInstance = AudioPlayer();
        // IMPORTANTE: Inicializar los streams del fallback player
        _initializePlayer();
      }
    }
    return _audioPlayerInstance!;
  }

  PlayerBlocBloc() : super(PlayerBlocState.initial()) {
    _registerEventHandlers();
    // No inicializar streams aquí - se hará cuando el player esté disponible
    // Inicializar el handler de audio después de un pequeño delay para asegurar que todo esté listo
    Future.microtask(() {
      add(const InitializeAudioServiceEvent());
    });
  }

  // OfflineService se obtiene de forma lazy para evitar dependencia circular
  OfflineService? _offlineService;

  late StreamSubscription _playerStateSubscription;
  late StreamSubscription _positionSubscription;
  late StreamSubscription _durationSubscription;
  late StreamSubscription _bufferedPositionSubscription;
  late StreamSubscription _currentIndexSubscription;

  // Flag para evitar inicialización múltiple de streams
  bool _isPlayerInitialized = false;

  // ==================== Historial de reproducción ====================
  /// ID de la entrada de historial actual
  String? _currentHistoryId;

  /// Última posición guardada en el historial (en segundos)
  /// Se usa para evitar guardar en cada cambio de posición
  int _lastSavedPositionSeconds = 0;

  /// Intervalo mínimo entre actualizaciones de historial (en segundos)
  static const int _historyUpdateIntervalSeconds = 5;

  /// Obtiene el OfflineService de forma lazy
  Future<OfflineService?> _getOfflineService() async {
    if (_offlineService != null) return _offlineService;

    try {
      if (GetIt.I.isRegistered<OfflineService>()) {
        _offlineService = await GetIt.I.getAsync<OfflineService>();
        return _offlineService;
      }
    } catch (e) {
      // Silently fail - no es crítico
    }
    return null;
  }

  // ==================== Métodos de Historial ====================

  /// Guarda la duración reproducida de la entrada de historial actual
  /// Es "fire and forget" - no bloquea la reproducción
  Future<void> _saveHistoryPlayedDuration(int positionSeconds) async {
    if (_currentHistoryId == null) return;

    // Evitar guardar si la posición no cambió significativamente
    if (positionSeconds - _lastSavedPositionSeconds <
        _historyUpdateIntervalSeconds) {
      return;
    }

    _lastSavedPositionSeconds = positionSeconds;

    // Fire and forget - no esperamos el resultado
    await _saveHistoryPlayedDurationInternal(
      _currentHistoryId!,
      positionSeconds,
    );
  }

  /// Implementación interna del guardado de historial
  Future<void> _saveHistoryPlayedDurationInternal(
    String historyId,
    int positionSeconds,
  ) async {
    try {
      final offlineService = await _getOfflineService();
      if (offlineService != null && offlineService.isInitialized) {
        await offlineService.updateHistoryPlayedDuration(
          historyId,
          positionSeconds,
        );
      }
    } catch (e) {
      // No propagar el error - el historial no debe afectar la reproducción
    }
  }

  /// Actualiza el mediaItem del AudioHandler para que muestre la canción en la notificación
  void _updateHandlerMediaItem(NowPlayingData track) {
    try {
      if (GetIt.I.isRegistered<AudioPlayerHandler>()) {
        final handler = GetIt.I<AudioPlayerHandler>();
        final mediaItem = track.toMediaItem();
        handler.mediaItem.add(mediaItem);
      }
    } catch (e) {
      // Silently fail - no es crítico
    }
  }

  /// Finaliza la entrada de historial actual y crea una nueva para el track
  Future<void> _startNewHistoryEntry(NowPlayingData track) async {
    // Primero, guardar el estado del historial anterior si existe
    await _finalizeCurrentHistoryEntry();

    try {
      final offlineService = await _getOfflineService();
      if (offlineService == null || !offlineService.isInitialized) {
        return;
      }

      // Obtener el nombre del artista
      final String artistName;
      if (track.artists.isNotEmpty) {
        artistName = track.artists.map((a) => a.name).join(', ');
      } else {
        artistName = 'Unknown Artist';
      }

      // Obtener la URL del thumbnail (usar .last para mejor calidad)
      String? thumbnailUrl;
      if (track.thumbnail != null) {
        thumbnailUrl = track.thumbnail?.url;
      } else if (track.thumbnails.isNotEmpty) {
        thumbnailUrl = track.thumbnails.last.url;
      }

      // Crear nueva entrada de historial
      final history = OfflineHistory.create(
        songId: track.videoId, // Usamos videoId como songId si no hay otro
        videoId: track.videoId,
        title: track.title,
        artist: artistName,
        thumbnail: thumbnailUrl,
        duration: track.durationSeconds,
        playedAt: DateTime.now(),
      );

      await offlineService.addToHistory(history);

      // Actualizar tracking
      _currentHistoryId = history.historyId;
      _lastSavedPositionSeconds = 0;
    } catch (e) {
      // No propagar el error - el historial no debe afectar la reproducción
    }
  }

  /// Finaliza la entrada de historial actual
  Future<void> _finalizeCurrentHistoryEntry() async {
    if (_currentHistoryId == null) return;

    try {
      // Guardar la posición final
      await _saveHistoryPlayedDurationInternal(
        _currentHistoryId!,
        _lastSavedPositionSeconds,
      );
    } catch (e) {
      // Silently fail
    } finally {
      // Limpiar estado
      _currentHistoryId = null;
      _lastSavedPositionSeconds = 0;
    }
  }

  void _initializePlayer() {
    // Evitar inicialización múltiple
    if (_isPlayerInitialized) {
      return;
    }

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((
      playerState,
    ) {
      add(AudioPlayerStateChangedEvent(playerState));
    });

    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      add(PositionChangedEvent(position));
    });

    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      add(DurationChangedEvent(duration ?? Duration.zero));
    });

    _bufferedPositionSubscription = _audioPlayer.bufferedPositionStream.listen(
      (bufferedPosition) => add(BufferedPositionChangedEvent(bufferedPosition)),
    );

    _currentIndexSubscription = _audioPlayer.currentIndexStream.listen(
      (index) => add(CurrentIndexChangedEvent(index)),
    );

    _isPlayerInitialized = true;
  }

  void _registerEventHandlers() {
    on<PlayEvent>(_onPlay);
    on<PauseEvent>(_onPause);
    on<StopEvent>(_onStop);
    on<PlayPauseToggleEvent>(_onPlayPauseToggle);

    on<NextTrackEvent>(_onNextTrack);
    on<PreviousTrackEvent>(_onPreviousTrack);
    on<SeekEvent>(_onSeek);

    on<LoadTrackEvent>(_onLoadTrack);
    on<LoadPlaylistEvent>(_onLoadPlaylist);
    on<PlayTrackAtIndexEvent>(_onPlayTrackAtIndex);
    on<AddToPlaylistEvent>(_onAddToPlaylist);
    on<AddMultipleToPlaylistEvent>(_onAddMultipleToPlaylist);
    on<RemoveFromPlaylistEvent>(_onRemoveFromPlaylist);

    on<SetVolumeEvent>(_onSetVolume);
    on<SetSpeedEvent>(_onSetSpeed);
    on<SetLoopModeEvent>(_onSetLoopMode);
    on<ToggleShuffleEvent>(_onToggleShuffle);

    on<AudioPlayerStateChangedEvent>(_onAudioPlayerStateChanged);
    on<PositionChangedEvent>(_onPositionChanged);
    on<DurationChangedEvent>(_onDurationChanged);
    on<BufferedPositionChangedEvent>(_onBufferedPositionChanged);
    on<CurrentIndexChangedEvent>(_onCurrentIndexChanged);
    on<AudioErrorEvent>(_onAudioError);

    on<InitializeAudioServiceEvent>(_onInitializeAudioService);
    on<DisposeAudioServiceEvent>(_onDisposeAudioService);
    on<ResetPlayerEvent>(_onResetPlayer);
  }

  Future<void> _onPlay(PlayEvent event, Emitter<PlayerBlocState> emit) async {
    try {
      await _audioPlayer.play();

      // IMPORTANTE: Emitir estado inmediatamente para actualizar la UI
      // No depender solo del stream, ya que puede no estar inicializado
      emit(
        state.copyWith(
          playbackState: PlaybackState.playing,
          processingState: ProcessingState.ready,
        ),
      );
        } catch (e) {
      add(AudioErrorEvent('Error al reproducir: $e'));
    }
  }

  Future<void> _onPause(PauseEvent event, Emitter<PlayerBlocState> emit) async {
    try {
      await _audioPlayer.pause();

      // IMPORTANTE: Emitir estado inmediatamente para actualizar la UI
      emit(
        state.copyWith(
          playbackState: PlaybackState.paused,
        ),
      );
        } catch (e) {
      add(AudioErrorEvent('Error al pausar: $e'));
    }
  }

  Future<void> _onStop(StopEvent event, Emitter<PlayerBlocState> emit) async {
    try {
      // Finalizar entrada de historial actual antes de detener
      await _finalizeCurrentHistoryEntry();

      await _audioPlayer.stop();
      emit(
        state.copyWith(
          playbackState: PlaybackState.stopped,
          position: Duration.zero,
        ),
      );
        } catch (e) {
      add(AudioErrorEvent('Error al detener: $e'));
    }
  }

  Future<void> _onPlayPauseToggle(
    PlayPauseToggleEvent event,
    Emitter<PlayerBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState.isPlaying) {
      add(const PauseEvent());
    } else {
      add(const PlayEvent());
    }
    }

  Future<void> _onNextTrack(
    NextTrackEvent event,
    Emitter<PlayerBlocState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState.canPlayNext) {
        await _audioPlayer.seekToNext();
      }
        } catch (e) {
      add(AudioErrorEvent('Error al cambiar a siguiente: $e'));
    }
  }

  Future<void> _onPreviousTrack(
    PreviousTrackEvent event,
    Emitter<PlayerBlocState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState.canPlayPrevious) {
        await _audioPlayer.seekToPrevious();
      }
        } catch (e) {
      add(AudioErrorEvent('Error al cambiar a anterior: $e'));
    }
  }

  Future<void> _onSeek(SeekEvent event, Emitter<PlayerBlocState> emit) async {
    try {
      await _audioPlayer.seek(event.position);
    } catch (e) {
      add(AudioErrorEvent('Error al hacer seek: $e'));
    }
  }

  Future<void> _onLoadTrack(
    LoadTrackEvent event,
    Emitter<PlayerBlocState> emit,
  ) async {
    print('DEBUG PlayerBloc _onLoadTrack:');
    print('  - track.videoId: ${event.track.videoId}');
    print('  - track.title: ${event.track.title}');
    print('  - track.streamUrl presente: ${event.track.streamUrl != null && event.track.streamUrl!.isNotEmpty}');
    print('  - sourceId: ${event.sourceId}');
    
    try {
      // Resetear el player antes de cargar
      print('DEBUG _onLoadTrack: Reset player...');
      try {
        await _audioPlayer.stop();
        await _audioPlayer.seek(Duration.zero);
        await _audioPlayer.setVolume(1.0);
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('DEBUG _onLoadTrack: Error al resetear: $e');
      }

      String? streamUrl = event.track.streamUrl;

      // PRIMERO: Verificar si la canción está descargada localmente
      final offlineService = await _getOfflineService();
      if (offlineService != null && offlineService.isInitialized) {
        final localPath = await offlineService.getLocalAudioPath(
          event.track.videoId,
        );

        if (localPath != null && localPath.isNotEmpty) {
          streamUrl = 'file://$localPath';
        }
      }

      // Los endpoints ya devuelven stream_url con include_stream_urls=true
      // Usar directamente la URL del track
      if (streamUrl == null || streamUrl.isEmpty) {
        streamUrl = event.track.streamUrl;
      }

      if (streamUrl == null || streamUrl.isEmpty) {
        emit(
          state.copyWith(
            isLoading: false,
            error:
                'No se pudo obtener la URL de streaming para esta canción. Intenta descargarla para escuchar offline.',
          ),
        );
        return;
      }

      await _loadTrackWithUrl(streamUrl, event.track, emit, sourceId: event.sourceId);
      print('DEBUG _onLoadTrack: _loadTrackWithUrl completado');
    } catch (e) {
      print('DEBUG _onLoadTrack ERROR: $e');
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Error al cargar canción: $e',
        ),
      );
    }
  }

  Future<void> _loadTrackWithUrl(
    String streamUrl,
    NowPlayingData track,
    Emitter<PlayerBlocState> emit, {
    String? sourceId,
  }) async {
    print('DEBUG _loadTrackWithUrl: INICIO');
    print('DEBUG _loadTrackWithUrl: streamUrl = ${streamUrl.substring(0, 50)}...');
    print('DEBUG _loadTrackWithUrl: sourceId = $sourceId');
    
    // Verificar que el player esté conectado
    print('DEBUG _loadTrackWithUrl: connectionState = ${state.connectionState}');
    
    try {
      // La URL ya viene codificada del backend, solo parsear
      final parsedUri = Uri.parse(streamUrl);
      print('DEBUG _loadTrackWithUrl: Uri.parse OK');
      
      // Usar setAudioSource con MediaItem para notificaciones
      print('DEBUG _loadTrackWithUrl: Llamando setAudioSource...');
      
      // Crear un ConcatenatingAudioSource con un solo elemento
      // Esto es más estable que usar AudioSource.uri directamente
      final audioSource = AudioSource.uri(parsedUri, tag: track.toMediaItem());
      await _audioPlayer.setAudioSource(audioSource, preload: false);
      print('DEBUG _loadTrackWithUrl: setAudioSource OK');

      // Esperar a que el audio esté listo (processingState ready)
      try {
        await _audioPlayer.processingStateStream
            .firstWhere((state) => state == ProcessingState.ready)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                return ProcessingState.ready;
              },
            );
      } catch (e) {
        // Timeout o error - continuamos
      }

      // IMPORTANTE: Esperar a que la duración esté disponible
      // El durationStream puede tardar en emitirse mientras se descargan los headers
      Duration actualDuration = _audioPlayer.duration ?? Duration.zero;
      if (actualDuration == Duration.zero) {
        try {
          final durationValue = await _audioPlayer.durationStream
              .firstWhere((d) => d != null && d.inSeconds > 0)
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  // Usar la duración de los metadatos de la canción como fallback
                  return Duration(seconds: track.durationSeconds);
                },
              );
          actualDuration =
              durationValue ?? Duration(seconds: track.durationSeconds);
        } catch (e) {
          // Usar la duración de los metadatos como fallback
          actualDuration = Duration(seconds: track.durationSeconds);
        }
      }

      // ACTUALIZAR NOTIFICACIONES: Actualizar el mediaItem del handler para que muestre la canción en la notificación
      _updateHandlerMediaItem(track);

      emit(
      state.copyWith(
        playlist: [track], // Limpiar playlist - solo esta canción
        playbackState: PlaybackState.playing,
        processingState: ProcessingState.ready,
        connectionState: AudioConnectionState.connected,
        currentTrack: track,
        currentStreamUrl: streamUrl,
        currentIndex: 0, // Resetear índice
        duration: actualDuration,
        position: Duration.zero,
        isLoading: false,
        error: null,
        sourceId: sourceId ?? state.sourceId, // Use provided sourceId or preserve existing
      ),
      );
      print('DEBUG _loadTrackWithUrl: Estado emitido, ahora play()');
      await _audioPlayer.play();
      print('DEBUG _loadTrackWithUrl: play() completado');
    } catch (e) {
      print('DEBUG _loadTrackWithUrl ERROR: $e');
      print('DEBUG _loadTrackWithUrl StackTrace: ${StackTrace.current}');
      emit(
       state.copyWith(
         playlist: [track],
         isLoading: false,
         error: 'Error al cargar audio: $e',
         connectionState: AudioConnectionState.disconnected,
         currentIndex: 0,
         currentTrack: track,
         currentStreamUrl: streamUrl,
         duration: Duration(seconds: track.durationSeconds),
         sourceId: sourceId ?? state.sourceId, // Use provided sourceId or preserve existing
        )
       );
      rethrow;
    }
  }

  Future<void> _onLoadPlaylist(
    LoadPlaylistEvent event,
    Emitter<PlayerBlocState> emit,
  ) async {
    try {
      // Si el player no está inicializado, intentar inicializarlo primero
      if (_audioPlayerInstance == null) {
        // Forzar inicialización del player
        final _ = _audioPlayer;
      }

      final startIndex = event.startIndex ?? 0;
      final safeStartIndex = startIndex < event.playlist.length ? startIndex : 0;
      final totalTracks = event.playlist.length;

      if (event.playlist.isEmpty) {
        emit(
         state.copyWith(
          isLoading: false,
            error: 'La playlist está vacía', 
         )
        );
        return;
      }

      // Crear audio sources de la playlist
      final audioSources = <AudioSource>[];
      for (final track in event.playlist) {
        if (track.streamUrl != null && track.streamUrl!.isNotEmpty) {
          try {
            final parsedUri = Uri.parse(track.streamUrl!);
            audioSources.add(
              AudioSource.uri(
                parsedUri,
                tag: track.toMediaItem(),
              ),
            );
          } catch (e) {
            // Continuar con los otros tracks si uno falla
          }
        }
      }

      if (audioSources.isEmpty) {
        emit(
          state.copyWith(
            isLoading: false,
            error: 'No se pudieron cargar las URLs de streaming',
            playlist: event.playlist,
          ),
        );
        return;
      }

      // Cargar playlist con reintentos
      Exception? lastError;
      for (int retry = 0; retry < 3; retry++) {
        try {
          await _audioPlayer.setAudioSource(
            ConcatenatingAudioSource(children: audioSources),
          );
          break; // Éxito
        } catch (e) {
          lastError = e as Exception;
          if (retry < 2) {
            await Future.delayed(Duration(milliseconds: 500 * (retry + 1)));
          }
        }
      }

      // Habilitar loop de playlist para que pase a la siguiente canción automáticamente
      await _audioPlayer.setLoopMode(LoopMode.all);

      if (lastError != null) {
        emit(
          state.copyWith(
            isLoading: false,
            error: 'Error al cargar playlist: $lastError',
            playlist: event.playlist,
          ),
        );
        return;
      }
      
      // Esperar a que el player procese
      await Future.delayed(const Duration(milliseconds: 500));
       
      final firstTrack = event.playlist[safeStartIndex];
      final actualDuration = Duration(seconds: firstTrack.durationSeconds);
      
      // DEBUG: Verificar sourceId
      print('DEBUG _onLoadPlaylist: event.sourceId=${event.sourceId}');
       
      // Emitir estado
      emit(
       state.copyWith(
          playbackState: PlaybackState.playing,
          playlist: event.playlist,
          isLoading: false,
          loadingCompletedAt: DateTime.now(),
          connectionState: AudioConnectionState.connected,
          currentIndex: safeStartIndex,
          currentTrack: firstTrack,
          duration: actualDuration,
          position: Duration.zero,
          loadedCount: totalTracks,
          totalToLoad: totalTracks,
          sourceId: event.sourceId,
       )
      );
      
      print('DEBUG _onLoadPlaylist: Estado emitido con sourceId=${state.sourceId}');
       
      // Play directamente
      await _audioPlayer.play();
    } catch (e) {
      emit(
       state.copyWith(
         isLoading: false,
          error: 'Error al cargar playlist: $e',
          playlist: event.playlist,
       )
      );
    }
  }

 

  Future<void> _onPlayTrackAtIndex(
    PlayTrackAtIndexEvent event,
    Emitter<PlayerBlocState> emit,
  ) async {
    try {
      final currentState = state;
      if (event.index >= 0 && event.index < currentState.playlist.length) {
        final track = currentState.playlist[event.index];

        final streamUrl = track.streamUrl;

        if (streamUrl == null || streamUrl.isEmpty) {
          add(
            const AudioErrorEvent(
              'La canción no tiene URL de streaming. Asegúrate de usar include_stream_urls=true en el endpoint.',
            ),
          );
          return;
        }

        await _audioPlayer.seek(Duration.zero, index: event.index);
        await _audioPlayer.play();

        emit(
          currentState.copyWith(
            currentIndex: event.index,
            currentTrack: track,
            currentStreamUrl: streamUrl,
            sourceId: currentState.sourceId, // Preserve sourceId
          ),
        );
      }
        } catch (e) {
      add(
        AudioErrorEvent(
          'Error al reproducir canción en índice ${event.index}: $e',
        ),
      );
    }
  }

  Future<void> _onAddToPlaylist(
    AddToPlaylistEvent event,
    Emitter<PlayerBlocState> emit,
  ) async {
    try {
      final currentState = state;

      final streamUrl = event.track.streamUrl;

      if (streamUrl == null || streamUrl.isEmpty) {
        add(
          const AudioErrorEvent(
            'La canción no tiene URL de streaming. Asegúrate de usar include_stream_urls=true en el endpoint.',
          ),
        );
        return;
      }

      final newPlaylist = List<NowPlayingData>.from(currentState.playlist)
        ..add(event.track);

      // La URL ya viene codificada del backend, solo parsear
      final parsedUri = Uri.parse(streamUrl);

      await _audioPlayer.addAudioSource(
        AudioSource.uri(parsedUri, tag: event.track.toMediaItem()),
      );

      emit(currentState.copyWith(playlist: newPlaylist));
    } catch (e) {
      add(AudioErrorEvent('Error al agregar canción a playlist: $e'));
    }
  }

  Future<void> _onAddMultipleToPlaylist(
    AddMultipleToPlaylistEvent event,
    Emitter<PlayerBlocState> emit,
  ) async {
    try {
      final currentState = state;

      // Filtrar tracks que tienen streamUrl válida
      final validTracks = event.tracks.where((track) =>
          track.streamUrl != null && track.streamUrl!.isNotEmpty).toList();

      if (validTracks.isEmpty) {
        return;
      }

      // Crear nuevas fuentes de audio
      final newSources = validTracks.map((track) {
        final parsedUri = Uri.parse(track.streamUrl!);
        return AudioSource.uri(parsedUri, tag: track.toMediaItem());
      }).toList();

      // Agregar todas las fuentes de una vez
      await _audioPlayer.addAudioSource(
        ConcatenatingAudioSource(children: newSources),
      );

      // Actualizar playlist en el estado
      final newPlaylist = List<NowPlayingData>.from(currentState.playlist)
        ..addAll(validTracks);

      emit(currentState.copyWith(playlist: newPlaylist));
    } catch (e) {
      add(AudioErrorEvent('Error al agregar canciones a playlist: $e'));
    }
  }



  Future<void> _onRemoveFromPlaylist(
    RemoveFromPlaylistEvent event,
    Emitter<PlayerBlocState> emit,
  ) async {
    try {
      final currentState = state;
      if (event.index >= 0 && event.index < currentState.playlist.length) {
        final newPlaylist = List<NowPlayingData>.from(currentState.playlist)
          ..removeAt(event.index);

        await _audioPlayer.removeAudioSourceAt(event.index);

        emit(currentState.copyWith(playlist: newPlaylist));
      }
        } catch (e) {
      add(AudioErrorEvent('Error al remover canción de playlist: $e'));
    }
  }

  Future<void> _onSetVolume(
    SetVolumeEvent event,
    Emitter<PlayerBlocState> emit,
  ) async {
    try {
      final clampedVolume = event.volume.clamp(0.0, 1.0);
      await _audioPlayer.setVolume(clampedVolume);

      emit(state.copyWith(volume: clampedVolume));
        } catch (e) {
      add(AudioErrorEvent('Error al cambiar volumen: $e'));
    }
  }

  Future<void> _onSetSpeed(
    SetSpeedEvent event,
    Emitter<PlayerBlocState> emit,
  ) async {
    try {
      final clampedSpeed = event.speed.clamp(0.5, 2.0);
      await _audioPlayer.setSpeed(clampedSpeed);

      emit(state.copyWith(speed: clampedSpeed));
        } catch (e) {
      add(AudioErrorEvent('Error al cambiar velocidad: $e'));
    }
  }

  Future<void> _onSetLoopMode(
    SetLoopModeEvent event,
    Emitter<PlayerBlocState> emit,
  ) async {
    try {
      await _audioPlayer.setLoopMode(event.loopMode);

      emit(state.copyWith(loopMode: event.loopMode));
        } catch (e) {
      add(AudioErrorEvent('Error al cambiar modo de repetición: $e'));
    }
  }

  Future<void> _onToggleShuffle(
    ToggleShuffleEvent event,
    Emitter<PlayerBlocState> emit,
  ) async {
    try {
      final currentState = state;
      final newShuffleState = !currentState.isShuffleEnabled;

      await _audioPlayer.setShuffleModeEnabled(newShuffleState);

      emit(currentState.copyWith(isShuffleEnabled: newShuffleState));
        } catch (e) {
      add(AudioErrorEvent('Error al cambiar modo shuffle: $e'));
    }
  }

  Future<void> _onAudioPlayerStateChanged(
    AudioPlayerStateChangedEvent event,
    Emitter<PlayerBlocState> emit,
  ) async {
    // Si el estado no es PlayerBlocState, crear uno nuevo con los datos del player
    final currentState = state;
    final previousProcessingState = currentState.processingState;
    final playbackState = event.playerState.playing
        ? PlaybackState.playing
        : PlaybackState.paused;

    emit(
      currentState.copyWith(
        playbackState: playbackState,
        processingState: event.playerState.processingState,
      ),
    );

    // Auto-play: cuando termina una canción, reproducir la siguiente automáticamente
    // Solo si:
    // 1. La canción actual terminó (processingState changed to completed)
    // 2. No es el modo loop.one (repetir una)
    // 3. Auto-play está habilitado en settings
    if (previousProcessingState != ProcessingState.completed &&
        event.playerState.processingState == ProcessingState.completed) {
      await _handleAutoPlay();
    }
  }

  /// Maneja la reproducción automática de la siguiente canción
  Future<void> _handleAutoPlay() async {
    try {
      // Verificar si auto-play está habilitado
      final profileCubit = GetIt.I<ProfileCubit>();
      final autoPlayEnabled = profileCubit.state.settings?.autoPlay ?? true;

      if (!autoPlayEnabled) {
        return;
      }

      // Verificar el modo de repetición actual
      final currentState = state;

      // Si está en modo loop.one, no necesitamos avanzar automáticamente
      if (currentState.loopMode == LoopMode.one) {
        return;
      }

      // Verificar si hay siguiente canción
      if (currentState.canPlayNext) {
        add(const NextTrackEvent());
      } else if (currentState.loopMode == LoopMode.all &&
          currentState.playlist.isNotEmpty) {
        // Si está en modo loop all y es la última canción, volver al inicio
        add(const PlayTrackAtIndexEvent(0));
      }
        } catch (e) {
      // Silently fail
    }
  }

  Future<void> _onPositionChanged(
    PositionChangedEvent event,
    Emitter<PlayerBlocState> emit,
  ) async {
    emit(state.copyWith(position: event.position));

    // Actualizar historial cada ~5 segundos (fire and forget)
    unawaited(_saveHistoryPlayedDuration(event.position.inSeconds));
  }

  Future<void> _onDurationChanged(
    DurationChangedEvent event,
    Emitter<PlayerBlocState> emit,
  ) async {
    emit(state.copyWith(duration: event.duration));
    }

  Future<void> _onBufferedPositionChanged(
    BufferedPositionChangedEvent event,
    Emitter<PlayerBlocState> emit,
  ) async {
    emit(
      state.copyWith(
        bufferedPosition: event.bufferedPosition,
      ),
    );
    }

  Future<void> _onCurrentIndexChanged(
    CurrentIndexChangedEvent event,
    Emitter<PlayerBlocState> emit,
  ) async {
    final currentState = state;
    final currentTrack =
        event.index != null && event.index! < currentState.playlist.length
        ? currentState.playlist[event.index!]
        : null;

    // Si cambió el track, crear nueva entrada de historial (fire and forget)
    if (currentTrack != null && event.index != currentState.currentIndex) {
      unawaited(_startNewHistoryEntry(currentTrack));
    }

    emit(
      currentState.copyWith(
        currentIndex: event.index,
        currentTrack: currentTrack,
      ),
    );
  }

  Future<void> _onAudioError(
    AudioErrorEvent event,
    Emitter<PlayerBlocState> emit,
  ) async {
    emit(
      state.copyWith(
        error: event.error,
        processingState: ProcessingState.idle,
      ),
    );
    }

  Future<void> _onInitializeAudioService(
    InitializeAudioServiceEvent event,
    Emitter<PlayerBlocState> emit,
  ) async {
    try {
      // Intentar obtener el AudioPlayerHandler
      if (GetIt.I.isRegistered<AudioPlayerHandler>()) {
        final handler = GetIt.I<AudioPlayerHandler>();
        _audioPlayerInstance = handler.player;
        _initializePlayer();
      } else {
        // Reintentar después de un delay
        await Future.delayed(const Duration(seconds: 2));
        if (GetIt.I.isRegistered<AudioPlayerHandler>()) {
          final handler = GetIt.I<AudioPlayerHandler>();
          _audioPlayerInstance = handler.player;
          _initializePlayer();
        } else {
          // FALLBACK: Crear AudioPlayer básico SI NO se ha creado antes
          // Esto asegura que los streams se inicialicen
          if (_audioPlayerInstance == null) {
            _audioPlayerInstance = AudioPlayer();
            _initializePlayer();
          }
        }
      }

      emit(
        state.copyWith(
          connectionState: AudioConnectionState.connected,
        ),
      );
        } catch (e) {
      add(AudioErrorEvent('Error initializing audio handler: $e'));
    }
  }

  Future<void> _onDisposeAudioService(
    DisposeAudioServiceEvent event,
    Emitter<PlayerBlocState> emit,
  ) async {
    try {
      emit(
        state.copyWith(
          connectionState: AudioConnectionState.disconnected,
        ),
      );
        } catch (e) {
      add(AudioErrorEvent('Error al cerrar audio service: $e'));
    }
  }

  Future<void> _onResetPlayer(
    ResetPlayerEvent event,
    Emitter<PlayerBlocState> emit,
  ) async {
    try {
      // Detener el audio
      await _audioPlayer.stop();
      
      // Limpiar la playlist
      await _audioPlayer.setAudioSource(
        ConcatenatingAudioSource(children: []),
      );

      // Emitir estado inicial
      emit(PlayerBlocState.initial());
        } catch (e) {
      add(AudioErrorEvent('Error al resetear player: $e'));
    }
  }

  @override
  Future<void> close() async {
    // Finalizar entrada de historial antes de dispose
    await _finalizeCurrentHistoryEntry();

    await _playerStateSubscription.cancel();
    await _positionSubscription.cancel();
    await _durationSubscription.cancel();
    await _bufferedPositionSubscription.cancel();
    await _currentIndexSubscription.cancel();
    await _audioPlayer.dispose();
    return super.close();
  }
}
