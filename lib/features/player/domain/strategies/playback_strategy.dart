import 'package:music_app/features/player/domain/entities/now_playing_data.dart';

/// Contract for different playback resolution strategies (Offline, Network, etc.)
/// Adheres to Open/Closed Principle (OCP)
abstract interface class PlaybackStrategy {
  /// Resolves the final usable URL (either local file path or network HTTP).
  /// Returns null if this strategy cannot resolve the track.
  Future<String?> resolveUrl(NowPlayingData track);
}
