import 'package:equatable/equatable.dart';

/// Entity representing song options data.
class SongOptionEntity extends Equatable {
  final String videoId;
  final String title;
  final String artist;
  final String? thumbnail;
  final String? streamUrl;
  final int? durationSeconds;
  final bool isFavorite;
  final bool isDownloaded;

  const SongOptionEntity({
    required this.videoId,
    required this.title,
    required this.artist,
    this.thumbnail,
    this.streamUrl,
    this.durationSeconds,
    this.isFavorite = false,
    this.isDownloaded = false,
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Verifica si el autor está especificado
  bool get hasValidArtist => artist.trim().isNotEmpty && artist.toLowerCase() != 'unknown artist';

  /// Determina si esta canción tiene un archivo que se puede reproducir o stremear
  bool get canPlay => streamUrl != null && streamUrl!.trim().isNotEmpty;

  /// Indica si tiene un cover configurado
  bool get hasValidThumbnail => thumbnail != null && thumbnail!.trim().isNotEmpty;

  SongOptionEntity copyWith({
    String? videoId,
    String? title,
    String? artist,
    String? thumbnail,
    String? streamUrl,
    int? durationSeconds,
    bool? isFavorite,
    bool? isDownloaded,
  }) {
    return SongOptionEntity(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnail: thumbnail ?? this.thumbnail,
      streamUrl: streamUrl ?? this.streamUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isFavorite: isFavorite ?? this.isFavorite,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }

  @override
  List<Object?> get props => [
    videoId,
    title,
    artist,
    thumbnail,
    streamUrl,
    durationSeconds,
    isFavorite,
    isDownloaded,
  ];
}
