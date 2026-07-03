import 'package:music_app/features/player/domain/entities/now_playing_data.dart';
import 'package:music_app/features/player/domain/strategies/playback_strategy.dart';

/// Strategy that resolves the track using its embedded network stream URL
class NetworkPlaybackStrategy implements PlaybackStrategy {
  @override
  Future<String?> resolveUrl(NowPlayingData track) async {
    if (track.streamUrl != null && track.streamUrl!.isNotEmpty) {
      return track.streamUrl;
    }
    return null;
  }
}
