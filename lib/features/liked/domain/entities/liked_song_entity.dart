import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/playable_audio.dart';

/// Entity representing a liked song in the domain layer.
class LikedSongEntity extends Equatable implements PlayableAudio {
  // --------- PlayableAudio Mappers ---------
  @override
  String get id => videoId;

  @override
  Duration get audioDuration => Duration(seconds: duration ?? 0);

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
  final int? duration;
  final DateTime? addedAt;

  const LikedSongEntity({
    required this.videoId,
    required this.title,
    required this.artist,
    this.thumbnail,
    this.duration,
    this.streamUrl,
    this.addedAt,
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Indica si la pista cuenta con un cover/thumbnail válido 
  bool get hasValidThumbnail => thumbnail != null && thumbnail!.trim().isNotEmpty;

  /// Determina si la canción fue megusteada recientemente (por defecto la última semana)
  bool isRecentlyLiked([Duration threshold = const Duration(days: 7)]) {
    if (addedAt == null) return false;
    return DateTime.now().difference(addedAt!) <= threshold;
  }

  @override
  List<Object?> get props => [
    videoId,
    title,
    artist,
    thumbnail,
    duration,
    streamUrl,
    addedAt,
  ];
}
