import '../../../../core/data/models/song_model.dart';
import '../../../../core/domain/entities/song.dart';
import '../../domain/entities/recent_search.dart';

/// Modelo de datos para una búsqueda reciente
class RecentSearchModel extends RecentSearch {
  const RecentSearchModel({
    required super.id,
    required super.query,
    required super.videoId,
    required super.songData,
    required super.createdAt,
    required super.lastSearchedAt,
  });

  factory RecentSearchModel.fromJson(Map<String, dynamic> json) {
    // Manejar songData que puede venir como Map o como objeto
    Song songData;
    if (json['songData'] != null) {
      songData = SongModel.fromJson(json['songData'] as Map<String, dynamic>);
    } else {
      // Crear un objeto Song vacío si no hay songData
      songData = Song(
        videoId: '',
        title: '',
        artist: '',
        artistNames: const [],
        album: '',
        thumbnail: '',
        highThumbnail: '',
        thumbnails: const [],
        streamUrl: '',
        durationSeconds: 0,
        duration: '0:00',
        views: '0',
        isExplicit: false,
        inLibrary: false,
        localPath: '',
        fileSize: 0,
        downloadedAt: DateTime.now(),
      );
    }

    return RecentSearchModel(
      id: json['id'] as String? ?? '',
      query: json['query'] as String? ?? '',
      videoId: json['videoId'] as String? ?? '',
      songData: songData,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      lastSearchedAt: DateTime.parse(
        json['lastSearchedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'query': query,
      'videoId': videoId,
      'songData': SongModel.toJson(songData),
      'createdAt': createdAt.toIso8601String(),
      'lastSearchedAt': lastSearchedAt.toIso8601String(),
    };
  }
}
