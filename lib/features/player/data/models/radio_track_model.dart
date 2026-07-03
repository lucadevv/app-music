import '../../domain/entities/radio_track_entity.dart';

/// Modelo de datos para una canción de radio (similar songs)
///
/// Representa la respuesta del endpoint /music/watch/ con radio=true
class RadioTrackModel {
  final String videoId;
  final String title;
  final String? artist;
  final List<RadioTrackArtist>? artists;
  final String? thumbnail;
  final String? streamUrl;
  final String? length;
  final int? durationSeconds;

  const RadioTrackModel({
    required this.videoId,
    required this.title,
    this.artist,
    this.artists,
    this.thumbnail,
    this.streamUrl,
    this.length,
    this.durationSeconds,
  });

  /// Crea un modelo desde un JSON del API
  factory RadioTrackModel.fromJson(Map<String, dynamic> json) {
    // Parse duration from "length" string (e.g., "3:45")
    int? durationSecs;
    final lengthStr = json['length'] as String?;
    if (lengthStr != null) {
      final parts = lengthStr.split(':');
      if (parts.length == 2) {
        final mins = int.tryParse(parts[0]) ?? 0;
        final secs = int.tryParse(parts[1]) ?? 0;
        durationSecs = mins * 60 + secs;
      } else if (parts.length == 3) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final mins = int.tryParse(parts[1]) ?? 0;
        final secs = int.tryParse(parts[2]) ?? 0;
        durationSecs = hours * 3600 + mins * 60 + secs;
      }
    }

    // Parse artists list
    List<RadioTrackArtist>? artistsList;
    if (json['artists'] != null && json['artists'] is List) {
      artistsList = (json['artists'] as List)
          .map((a) => RadioTrackArtist.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    return RadioTrackModel(
      videoId: json['videoId'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown',
      artist: json['artist'] as String?,
      artists: artistsList,
      streamUrl: (json['stream_url'] ?? json['streamUrl']) as String?,
      durationSeconds: durationSecs,
    );
  }

  /// Convierte el modelo a JSON
  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'artist': artist,
      'artists': artists?.map((a) => a.toJson()).toList(),
      'thumbnail': thumbnail,
      'stream_url': streamUrl,
      'length': length,
      'durationSeconds': durationSeconds,
    };
  }

  /// Convierte a Entity del dominio
  RadioTrackEntity toEntity() {
    return RadioTrackEntity(
      videoId: videoId,
      title: title,
      artist: artist,
      artists: artists?.map((a) => a.name).toList(),
      thumbnail: thumbnail,
      streamUrl: streamUrl,
      length: length,
      durationSeconds: durationSeconds ?? 0,
    );
  }
}

/// Artista dentro de un track de radio
class RadioTrackArtist {
  final String name;

  const RadioTrackArtist({required this.name});

  factory RadioTrackArtist.fromJson(Map<String, dynamic> json) {
    return RadioTrackArtist(name: json['name'] as String? ?? 'Unknown');
  }

  Map<String, dynamic> toJson() => {'name': name};
}
