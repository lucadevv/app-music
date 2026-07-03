// ignore_for_file: avoid_dynamic_calls
import '../../domain/entities/recently_played_song.dart';

/// Modelo de datos para RecentlyPlayedSong.
///
/// Este modelo representa la respuesta de la API y se convierte
/// a la entidad de dominio en el repository o mapper.
class RecentlyPlayedSongModel extends RecentlyPlayedSong {
  const RecentlyPlayedSongModel({
    required super.videoId,
    required super.title,
    required super.artist,
    required super.duration,
    super.thumbnail,
    super.durationSeconds = 0,
    super.playedAt,
    super.streamUrl,
  });

  /// Crea el modelo desde el JSON de la API
  factory RecentlyPlayedSongModel.fromJson(Map<String, dynamic> json) {
    // duration puede venir como número (segundos) o string ("m:ss")
    int durationSeconds = 0;
    String durationStr = '0:00';

    final rawDuration = json['duration'];
    if (rawDuration != null) {
      if (rawDuration is int) {
        durationSeconds = rawDuration;
        final minutes = durationSeconds ~/ 60;
        final seconds = durationSeconds % 60;
        durationStr = '$minutes:${seconds.toString().padLeft(2, '0')}';
      } else if (rawDuration is String) {
        try {
          if (rawDuration.contains(':')) {
            final parts = rawDuration.split(':');
            if (parts.length == 2) {
              durationSeconds = int.parse(parts[0]) * 60 + int.parse(parts[1]);
              durationStr = rawDuration;
            }
          } else {
            durationSeconds = int.parse(rawDuration);
            final minutes = durationSeconds ~/ 60;
            final seconds = durationSeconds % 60;
            durationStr = '$minutes:${seconds.toString().padLeft(2, '0')}';
          }
        } catch (_) {
          durationSeconds = 0;
        }
      }
    }

    // Extraer stream_url de donde venga (soporta snake_case y camelCase)
    String? streamUrl;
    if (json['stream_url'] != null || json['streamUrl'] != null) {
      streamUrl = (json['stream_url'] ?? json['streamUrl']) as String?;
    } else if (json['songData'] != null &&
        json['songData'] is Map<String, dynamic>) {
      streamUrl = (json['songData']['stream_url'] ?? json['songData']['streamUrl']) as String?;
    }

    return RecentlyPlayedSongModel(
      videoId: json['videoId'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown',
      artist: json['artist'] as String? ?? 'Unknown Artist',
      thumbnail: json['thumbnail'] as String?,
      duration: durationStr,
      durationSeconds: durationSeconds,
      streamUrl: streamUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'artist': artist,
      'thumbnail': thumbnail,
      'duration': durationSeconds,
      if (streamUrl != null) 'stream_url': streamUrl,
    };
  }
}

/// Modelo para la respuesta de la API de Recently Played
class RecentlyPlayedResponse {
  final List<RecentlyPlayedSongModel> songs;
  final int total;

  const RecentlyPlayedResponse({required this.songs, required this.total});

  factory RecentlyPlayedResponse.fromJson(Map<String, dynamic> json) {
    final songsList = json['songs'] as List<dynamic>? ?? [];
    return RecentlyPlayedResponse(
      songs: songsList
          .map(
            (s) => RecentlyPlayedSongModel.fromJson(s as Map<String, dynamic>),
          )
          .toList(),
      total: json['total'] as int? ?? 0,
    );
  }
}
