import 'package:music_app/features/player/domain/entities/now_playing_data.dart';
import 'package:music_app/features/player/domain/repositories/player_repository.dart';
import 'package:music_app/features/player/domain/strategies/playback_strategy.dart';

/// Strategy that tries to resolve the track from local offline storage
class OfflinePlaybackStrategy implements PlaybackStrategy {
  final PlayerRepository _repository;

  OfflinePlaybackStrategy(this._repository);

  @override
  Future<String?> resolveUrl(NowPlayingData track) async {
    final localPathResult = await _repository.getLocalAudioPath(track.videoId);
    
    return localPathResult.fold(
      (error) => null, // If there's an error, this strategy fails
      (localPath) {
        if (localPath != null && localPath.isNotEmpty) {
          return 'file://$localPath';
        }
        return null; // Not found offline
      },
    );
  }
}
