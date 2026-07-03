import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/playable_audio.dart';

/// Entidad de dominio para una canción de radio (similar songs)
///
/// Esta es la entidad canónica usada en la capa de presentación
class RadioTrackEntity extends Equatable implements PlayableAudio {
  // --------- PlayableAudio Mappers ---------
  @override
  String get id => videoId;

  @override
  String get artist => displayArtist;

  @override
  Duration get audioDuration => Duration(seconds: durationSeconds);

  @override
  String? get bestThumbnail => thumbnail;

  @override
  bool get canPlay => streamUrl != null && streamUrl!.isNotEmpty;
  
  @override
  final String title;
  
  @override
  final String? streamUrl;
  // -----------------------------------------

  final String videoId;
  final String? _artist;
  final List<String>? artists;
  final String? thumbnail;
  final String? length;
  final int durationSeconds;

  const RadioTrackEntity({
    required this.videoId,
    required this.title,
    String? artist,
    this.artists,
    this.thumbnail,
    this.streamUrl,
    this.length,
    this.durationSeconds = 0,
  }) : _artist = artist;

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Indica si la pista cuenta con un cover/thumbnail válido 
  bool get hasValidThumbnail => thumbnail != null && thumbnail!.trim().isNotEmpty;

  /// Indica si la duración del archivo de audio es conocida y mapeada en segundos
  bool get isDurationKnown => durationSeconds > 0;

  /// Obtiene el nombre del artista formateado
  String get displayArtist {
    if (artists != null && artists!.isNotEmpty) {
      return artists!.join(', ');
    }
    return _artist ?? 'Unknown Artist';
  }

  @override
  List<Object?> get props => [
    videoId,
    title,
    _artist,
    artists,
    thumbnail,
    streamUrl,
    length,
    durationSeconds,
  ];
}
