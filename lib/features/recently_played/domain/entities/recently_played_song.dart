import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/playable_audio.dart';

/// Entity for recently played song (dominio).
/// Representa la canción en la capa de presentación.
/// El parsing de JSON se hace en el Model (RecentlyPlayedSongModel).
class RecentlyPlayedSong extends Equatable implements PlayableAudio {
  // --------- PlayableAudio Mappers ---------
  @override
  String get id => videoId;

  @override
  Duration get audioDuration => Duration(seconds: durationSeconds);

  @override
  String? get bestThumbnail => thumbnail;

  @override
  bool get canPlay => streamUrl != null && streamUrl!.isNotEmpty;
  
  @override
  final String title;
  
  @override
  final String artist;
  
  @override
  final String? streamUrl;
  // -----------------------------------------

  final String videoId;
  final String? thumbnail;
  final String duration;
  final int durationSeconds;
  final DateTime? playedAt;

  const RecentlyPlayedSong({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.duration,
    this.thumbnail,
    this.durationSeconds = 0,
    this.playedAt,
    this.streamUrl,
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Indica si la pista cuenta con un cover/thumbnail válido 
  bool get hasValidThumbnail => thumbnail != null && thumbnail!.trim().isNotEmpty;

  /// Determina si fue reproducida extremadamente reciente (por defecto, las últimas 24hs)
  bool isPlayedRecently([Duration threshold = const Duration(days: 1)]) {
    if (playedAt == null) return false;
    return DateTime.now().difference(playedAt!) <= threshold;
  }

  @override
  List<Object?> get props => [
    videoId,
    title,
    artist,
    thumbnail,
    duration,
    durationSeconds,
    streamUrl,
  ];
}
