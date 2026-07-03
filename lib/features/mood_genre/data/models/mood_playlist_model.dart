import 'package:music_app/features/mood_genre/domain/entities/mood_playlist.dart';

class MoodPlaylistModel extends MoodPlaylist {
  const MoodPlaylistModel({
    required super.playlistId,
    required super.title,
    super.description,
    super.thumbnail,
    super.videoCount,
  });

  factory MoodPlaylistModel.fromJson(Map<String, dynamic> json) {
    return MoodPlaylistModel(
      playlistId: json['playlistId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      thumbnail: (json['thumbnail'] as List<dynamic>?)?.cast<String>(),
      videoCount: json['videoCount'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playlistId': playlistId,
      'title': title,
      if (description != null) 'description': description,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (videoCount != null) 'videoCount': videoCount,
    };
  }
}
