import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:music_app/core/services/audio_handler_service.dart';
import 'package:music_app/core/services/media_item_mapper.dart';
import 'package:music_app/features/player/domain/entities/now_playing_data.dart';
import 'package:music_app/features/player/domain/player_engine.dart';
import 'package:music_app/features/player/domain/repositories/player_repository.dart';
import 'package:music_app/features/player/domain/strategies/playback_strategy.dart';
import 'package:music_app/features/player/domain/types/player_types.dart';
import 'package:music_app/features/player/domain/usecases/manage_history_use_case.dart';

/// App Service que orquesta el reproductor de audio, persistencia y OS handlers.
///
/// Propósito (SRP): Extraer la lógica de hardware e IO de BD fuera del BLoC,
/// permitiendo que la capa de Presentación se dedique exclusivamente al State.
class AudioSessionController {
  final PlayerEngine _engine;
  final PlayerRepository _repository;
  final ManageHistoryUseCase _manageHistoryUseCase;
  final AudioPlayerHandler? _playerHandler;
  final List<PlaybackStrategy> _strategies;

  AudioSessionController({
    required PlayerEngine engine,
    required PlayerRepository repository,
    required ManageHistoryUseCase manageHistoryUseCase,
    required List<PlaybackStrategy> strategies,
    AudioPlayerHandler? playerHandler,
  }) : _engine = engine,
       _repository = repository,
       _manageHistoryUseCase = manageHistoryUseCase,
       _strategies = strategies,
       _playerHandler = playerHandler;

  // ================= Streams para la UI =================
  Stream<PlayerStateInfo> get playerStateStream => _engine.playerStateStream;
  Stream<Duration> get positionStream => _engine.positionStream;
  Stream<Duration?> get durationStream => _engine.durationStream;
  Stream<Duration> get bufferedPositionStream => _engine.bufferedPositionStream;
  Stream<int?> get currentIndexStream => _engine.currentIndexStream;

  // ================= Controles Básicos =================
  Future<void> play() => _engine.play();
  Future<void> pause() => _engine.pause();

  Future<void> stop() async {
    await _engine.stop();
    await _manageHistoryUseCase.finalizeCurrent();
  }

  Future<void> seek(Duration position) => _engine.seek(position);
  Future<void> seekToNext() => _engine.seekToNext();
  Future<void> seekToPrevious() => _engine.seekToPrevious();
  Future<void> seekToIndex(int index) =>
      _engine.seek(Duration.zero, index: index);

  Future<void> setVolume(double volume) => _engine.setVolume(volume);
  Future<void> setSpeed(double speed) => _engine.setSpeed(speed);
  Future<void> setLoopMode(LoopModeType mode) => _engine.setLoopMode(mode);
  Future<void> setShuffleModeEnabled(bool enabled) =>
      _engine.setShuffleModeEnabled(enabled);

  // ================= Control de Sesión y Playlists =================

  /// Carga y reproduce una única canción
  Future<String?> loadSingleTrack(NowPlayingData track) async {
    final streamUrl = await resolveStreamUrl(track);
    if (streamUrl == null || streamUrl.isEmpty) return null;

    try {
      final config = _buildConfig(track, streamUrl);
      await _engine.setAudioSource(config, preload: false);
      updateHandlerMediaItem(track);
      await play();
      await trackListenEvent(track);
    } catch (e) {
      if (e.toString().contains('Loading interrupted')) {
        debugPrint('AudioSessionController: Loading interrupted (superseded)');
      } else {
        rethrow;
      }
      return null;
    }
    return streamUrl;
  }

  /// Carga y reproduce un listado de fuentes, retornando la lista final (ignorando inválidas)
  Future<List<NowPlayingData>> loadPlaylist(
    List<NowPlayingData> playlist, {
    int startIndex = 0,
  }) async {
    if (playlist.isEmpty) throw ArgumentError('Playlist vacía');

    final sources = <AudioSourceConfig>[];
    final validTracks = <NowPlayingData>[];

    for (final track in playlist) {
      // Intentar resolver la URL dinámicamente si falta (para fallbacks)
      final url = track.streamUrl != null && track.streamUrl!.isNotEmpty
          ? track.streamUrl!
          : await resolveStreamUrl(track);

      if (url != null && url.isNotEmpty) {
        sources.add(_buildConfig(track, url));
        validTracks.add(
          track,
        ); // El track es jugable, lo conservamos en la lista
      } else {
        debugPrint(
          'AudioSessionController: Se omitió pista por falta de URL: ${track.title}',
        );
      }
    }

    if (sources.isEmpty) {
      throw Exception('Ninguna canción tiene URL válida');
    }

    await _engine.setAudioSources(sources, preload: false);
    await _engine.setLoopMode(LoopModeType.all);

    // Mapeo seguro del startIndex: si la canción del index original fue borrada, empezamos la playlist desde 0.
    int safeStartIndex = 0;
    if (startIndex < playlist.length) {
      final originalTarget = playlist[startIndex];
      final newIndex = validTracks.indexWhere(
        (t) => t.videoId == originalTarget.videoId,
      );
      if (newIndex >= 0) safeStartIndex = newIndex;
    }

    final firstTrack = validTracks[safeStartIndex];
    updateHandlerMediaItem(firstTrack);

    await seekToIndex(safeStartIndex);
    await play();
    await trackListenEvent(firstTrack);

    return validTracks; // Para sincronizar PlayerBlocBloc
  }

  /// Añade una fuente extra al final
  Future<void> addToQueue(NowPlayingData track) async {
    if (track.streamUrl == null || track.streamUrl!.isEmpty) {
      throw ArgumentError('La canción no tiene URL');
    }
    await _engine.addAudioSources([_buildConfig(track, track.streamUrl!)]);
  }

  Future<void> addMultipleToQueue(List<NowPlayingData> tracks) async {
    final validTracks = tracks
        .where((t) => t.streamUrl != null && t.streamUrl!.isNotEmpty)
        .toList();
    if (validTracks.isEmpty) return;

    await _engine.addAudioSources(
      validTracks.map((t) => _buildConfig(t, t.streamUrl!)).toList(),
    );
  }

  Future<void> removeFromQueue(int index) => _engine.removeAudioSourceAt(index);

  Future<void> reset() async {
    await _engine.stop();
    await _engine.setAudioSources([]);
    await _manageHistoryUseCase.finalizeCurrent();
  }

  // ================= Resolutores & Persistencia =================

  /// Resuelve local o red utilizando el patrón Strategy
  Future<String?> resolveStreamUrl(NowPlayingData track) async {
    for (final strategy in _strategies) {
      final url = await strategy.resolveUrl(track);
      if (url != null && url.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('Resolved stream using ${strategy.runtimeType}');
        }
        return url;
      }
    }
    return null; // Fallback si ninguna estrategia puede resolverlo
  }

  AudioSourceConfig _buildConfig(NowPlayingData track, String finalUrl) {
    return AudioSourceConfig(
      id: track.videoId,
      url: finalUrl,
      title: track.title,
      artist: track.artistsNames,
      duration: Duration(seconds: track.durationSeconds),
      mediaItem: MediaItemMapper.fromNowPlayingData(track),
    );
  }

  Future<void> trackListenEvent(NowPlayingData track) async {
    try {
      await _manageHistoryUseCase.startNewEntry(track.toSong());
      unawaited(_repository.recordListen(track.videoId));
    } catch (e) {
      debugPrint('AudioSessionController: Error saving history: $e');
    }
  }

  Future<void> trackPositionUpdate(Duration position) async {
    unawaited(_manageHistoryUseCase.updatePlayedDuration(position.inSeconds));
  }

  void updateHandlerMediaItem(NowPlayingData track) {
    try {
      _playerHandler?.updateNowPlaying(track);
    } catch (e) {
      debugPrint('AudioSessionController: Handler update error: $e');
    }
  }

  Future<void> dispose() async {
    await _manageHistoryUseCase.finalizeCurrent();
  }
}
