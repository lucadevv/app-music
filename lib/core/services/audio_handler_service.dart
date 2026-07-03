import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/core/services/media_item_mapper.dart';
import 'package:music_app/features/dashboard/presentation/bloc/player_bloc_bloc.dart';
import 'package:music_app/features/player/domain/entities/now_playing_data.dart';

/// Handler de audio para notificaciones y controles en pantalla de bloqueo.
///
/// ESTE ES LA ÚNICA FUENTE DE INSTANCIA DE AudioPlayer.
/// PlayerBlocBloc obtiene el AudioPlayer exclusivamente a través de este handler.
///
/// Los controles de reproducción (play, pause, skip, etc.) que vienen desde
/// las notificaciones y pantalla de bloqueo se delegan al PlayerBloc para
/// mantener una única fuente de verdad del estado.
class AudioPlayerHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  AudioPlayer? _player;
  bool _isInitialized = false;
  final List<StreamSubscription> _subscriptions = [];

  // PlayerBlocBloc para delegar eventos desde notificaciones
  PlayerBlocBloc? _playerBloc;

  /// Setter para inyectar PlayerBlocBloc después de la construcción.
  /// Necesario porque AudioPlayerHandler se crea en main.dart antes que PlayerBlocBloc.
  set playerBloc(PlayerBlocBloc bloc) {
    _playerBloc = bloc;
  }

  /// Obtiene el AudioPlayer. Solo disponible después de init().
  AudioPlayer get player {
    if (_player == null) {
      throw StateError(
        'AudioPlayerHandler.player accessed before init(). '
        'Call init() first.',
      );
    }
    return _player!;
  }

  /// Verifica si el handler está listo (init() fue llamado)
  bool get isReady => _isInitialized && _player != null;

  AudioPlayerHandler();

  /// Inicializa el handler. Debe llamarse UNA SOLA VEZ.
  /// Es idempotente: llamadas múltiples no tienen efecto.
  void init() {
    if (_isInitialized) {
      return;
    }

    _player ??= AudioPlayer();
    _setupStreams();
    _isInitialized = true;
  }

  void _setupStreams() {
    if (_player == null) return;

    // Limpiar suscripciones anteriores si existen
    _disposeSubscriptions();

    // Escuchar cambios de estado del player para broadcast a notificaciones
    _subscriptions.add(
      _player!.playerStateStream.listen((_) => _broadcastState()),
    );
    _subscriptions.add(
      _player!.playbackEventStream.listen((_) => _broadcastState()),
    );
  }

  void _disposeSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  /// Actualiza el mediaItem en las notificaciones con datos de NowPlayingData
  Future<void> updateNowPlaying(NowPlayingData track) async {
    final mediaItem = MediaItemMapper.fromNowPlayingData(track);
    this.mediaItem.add(mediaItem);
  }

  /// Broadcast del estado actual a las notificaciones
  void _broadcastState() {
    if (_player == null) return;

    final playing = _player!.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _mapProcessingState(_player!.processingState),
        playing: playing,
        updatePosition: _player!.position,
        bufferedPosition: _player!.bufferedPosition,
        speed: _player!.speed,
        queueIndex: _player!.currentIndex ?? 0,
      ),
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  // ========== Controles de reproducción delegadas al PlayerBloc ==========
  // Estos métodos se llaman cuando el usuario interactúa con las notificaciones
  // o controles de pantalla de bloqueo. Delegamos al bloc para mantener
  // una única fuente de verdad.

  @override
  Future<void> play() async {
    _delegateToBloc(const PlayEvent());
  }

  @override
  Future<void> pause() async {
    _delegateToBloc(const PauseEvent());
  }

  @override
  Future<void> stop() async {
    _delegateToBloc(const StopEvent());
  }

  @override
  Future<void> seek(Duration position) async {
    _delegateToBloc(SeekEvent(position));
  }

  @override
  Future<void> skipToNext() async {
    _delegateToBloc(const NextTrackEvent());
  }

  @override
  Future<void> skipToPrevious() async {
    _delegateToBloc(const PreviousTrackEvent());
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    _delegateToBloc(PlayTrackAtIndexEvent(index));
  }

  /// Delega un evento al PlayerBloc si está disponible
  void _delegateToBloc(PlayerBlocEvent event) {
    _playerBloc?.add(event);
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await _player?.dispose();
    _disposeSubscriptions();
    _isInitialized = false;
    _player = null;
    await super.onTaskRemoved();
  }
}
