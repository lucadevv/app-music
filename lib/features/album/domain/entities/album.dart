import 'package:music_app/core/domain/entities/playable_audio.dart';

/// Entity representing an album
///
/// @deprecated Usar [Album] desde `core/domain/entities/album.dart`
/// Esta entidad será eliminada en futuras versiones.
@Deprecated('Usar Album desde core/domain/entities/album.dart')
class Album {
  final String id;
  final String title;
  final String? thumbnail;
  final String? artistName;
  final String? artistId;
  final int year;
  final List<AlbumSong> songs;

  const Album({
    required this.id,
    required this.title,
    this.thumbnail,
    this.artistName,
    this.artistId,
    this.year = 2024,
    this.songs = const [],
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Indica si el álbum tiene asignado un título descriptivo y no genérico
  bool get hasValidTitle => title.trim().isNotEmpty && title.toLowerCase() != 'unknown';

  /// Indica si el álbum cuenta con un nombre de artista asociado
  bool get hasArtist => artistName != null && artistName!.trim().isNotEmpty;

  String get bestThumbnail => thumbnail ?? '';

  int get songCount => songs.length;

  int get totalDurationSeconds =>
      songs.fold(0, (sum, song) => sum + song.durationSeconds);

  String get formattedDuration {
    final totalMinutes = totalDurationSeconds ~/ 60;
    return '$totalMinutes min';
  }
}

/// Song from an album
class AlbumSong implements PlayableAudio {
  final String videoId;
  @override
  final String title;
  final String? thumbnail;
  final int durationSeconds;
  final int trackNumber;
  @override
  final String? streamUrl;

  const AlbumSong({
    required this.videoId,
    required this.title,
    required this.durationSeconds,
    required this.trackNumber,
    this.thumbnail,
    this.streamUrl,
  });

  @override
  String get id => videoId;

  @override
  String get artist => 'Unknown';

  @override
  Duration get audioDuration => Duration(seconds: durationSeconds);

  @override
  String? get bestThumbnail => thumbnail;

  @override
  bool get canPlay => true;

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
