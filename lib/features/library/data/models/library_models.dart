// DTOs for Library API responses
// These classes represent the raw data from the API
// Located in data layer as they represent API data structures

library;

import 'package:music_app/core/domain/entities/playable_audio.dart';

// ============ Metadata Classes ============

class SongMetadata {
  final String? title;
  final String? artist;
  final String? thumbnail;
  final int? duration;
  final String? streamUrl;

  const SongMetadata({
    this.title,
    this.artist,
    this.thumbnail,
    this.duration,
    this.streamUrl,
  });

  factory SongMetadata.fromJson(Map<String, dynamic> json) {
    return SongMetadata(
      title: json['title'],
      artist: json['artist'],
      thumbnail: json['thumbnail'],
      duration: json['duration'],
      streamUrl: json['streamUrl'],
    );
  }
}

class PlaylistMetadata {
  final String? name;
  final String? thumbnail;
  final String? description;
  final int? trackCount;

  const PlaylistMetadata({
    this.name,
    this.thumbnail,
    this.description,
    this.trackCount,
  });

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (thumbnail != null) 'thumbnail': thumbnail,
    if (description != null) 'description': description,
    if (trackCount != null) 'trackCount': trackCount,
  };

  factory PlaylistMetadata.fromJson(Map<String, dynamic> json) {
    return PlaylistMetadata(
      name: json['name'],
      thumbnail: json['thumbnail'],
      description: json['description'],
      trackCount: json['trackCount'],
    );
  }
}

// ============ Library Summary ============

class LibrarySummary {
  final int favoriteSongs;
  final int favoritePlaylists;
  final int favoriteGenres;

  LibrarySummary({
    required this.favoriteSongs,
    required this.favoritePlaylists,
    required this.favoriteGenres,
  });

  factory LibrarySummary.fromJson(Map<String, dynamic> json) {
    return LibrarySummary(
      favoriteSongs: json['favoriteSongs'] ?? 0,
      favoritePlaylists: json['favoritePlaylists'] ?? 0,
      favoriteGenres: json['favoriteGenres'] ?? 0,
    );
  }
}

// ============ Favorite Songs ============

class FavoriteSongsResponse {
  final List<FavoriteSong> data;
  final int total;

  FavoriteSongsResponse({required this.data, required this.total});

  factory FavoriteSongsResponse.fromJson(Map<String, dynamic> json) {
    return FavoriteSongsResponse(
      data:
          (json['data'] as List?)
              ?.map((e) => FavoriteSong.fromJson(e))
              .toList() ??
          [],
      total: json['total'] ?? 0,
    );
  }
}

class FavoriteSong implements PlayableAudio {
  @override
  final String id;
  final String songId;
  final String videoId;
  @override
  final String title;
  @override
  final String artist;
  final String? thumbnail;
  final int? duration;
  @override
  final String? streamUrl;
  final DateTime createdAt;

  FavoriteSong({
    required this.id,
    required this.songId,
    required this.videoId,
    required this.title,
    required this.artist,
    required this.createdAt,
    this.thumbnail,
    this.duration,
    this.streamUrl,
  });

  factory FavoriteSong.fromJson(Map<String, dynamic> json) {
    final song = json['song'] as Map<String, dynamic>?;
    return FavoriteSong(
      id: json['id'] ?? '',
      songId: song?['id'] ?? '',
      videoId: song?['videoId'] ?? '',
      title: song?['title'] ?? '',
      artist: song?['artist'] ?? '',
      thumbnail: song?['thumbnail'],
      duration: song?['duration'],
      streamUrl: song?['streamUrl'] ?? song?['audioUrl'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  @override
  Duration get audioDuration => Duration(seconds: duration ?? 0);

  @override
  String? get bestThumbnail => thumbnail;

  @override
  bool get canPlay => streamUrl != null && streamUrl!.isNotEmpty;
}

// ============ Favorite Playlists ============

class FavoritePlaylistsResponse {
  final List<FavoritePlaylist> data;
  final int total;

  FavoritePlaylistsResponse({required this.data, required this.total});

  factory FavoritePlaylistsResponse.fromJson(Map<String, dynamic> json) {
    return FavoritePlaylistsResponse(
      data:
          (json['data'] as List?)
              ?.map((e) => FavoritePlaylist.fromJson(e))
              .toList() ??
          [],
      total: json['total'] ?? 0,
    );
  }
}

class FavoritePlaylist {
  final String id;
  final String playlistId;
  final String externalPlaylistId;
  final String name;
  final String? description;
  final String? thumbnail;
  final int? trackCount;
  final int? cachedTrackCount;
  final DateTime createdAt;

  FavoritePlaylist({
    required this.id,
    required this.playlistId,
    required this.externalPlaylistId,
    required this.name,
    required this.createdAt,
    this.description,
    this.thumbnail,
    this.trackCount,
    this.cachedTrackCount,
  });

  factory FavoritePlaylist.fromJson(Map<String, dynamic> json) {
    final playlist = json['playlist'] as Map<String, dynamic>?;
    return FavoritePlaylist(
      id: json['id'] ?? '',
      playlistId: playlist?['id'] ?? '',
      externalPlaylistId: playlist?['externalPlaylistId'] ?? '',
      name: playlist?['name'] ?? '',
      description: playlist?['description'],
      thumbnail: playlist?['thumbnail'],
      trackCount: (playlist?['songs'] as List?)?.length ?? 0,
      cachedTrackCount: json['cachedTrackCount'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

// ============ Favorite Genres ============

class FavoriteGenresResponse {
  final List<FavoriteGenre> data;
  final int total;

  FavoriteGenresResponse({required this.data, required this.total});

  factory FavoriteGenresResponse.fromJson(Map<String, dynamic> json) {
    return FavoriteGenresResponse(
      data:
          (json['data'] as List?)
              ?.map((e) => FavoriteGenre.fromJson(e))
              .toList() ??
          [],
      total: json['total'] ?? 0,
    );
  }
}

class FavoriteGenre {
  final String id;
  final String genreId;
  final String externalParams;
  final String name;
  final DateTime createdAt;

  FavoriteGenre({
    required this.id,
    required this.genreId,
    required this.externalParams,
    required this.name,
    required this.createdAt,
  });

  factory FavoriteGenre.fromJson(Map<String, dynamic> json) {
    final genre = json['genre'] as Map<String, dynamic>?;
    return FavoriteGenre(
      id: json['id'] ?? '',
      genreId: genre?['id'] ?? '',
      externalParams: genre?['externalParams'] ?? '',
      name: genre?['name'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

// ============ User Playlists ============

class UserPlaylist {
  final String id;
  final String name;
  final String? description;
  final String? thumbnail;
  final int songCount;
  final DateTime createdAt;

  UserPlaylist({
    required this.id,
    required this.name,
    required this.songCount,
    required this.createdAt,
    this.description,
    this.thumbnail,
  });

  factory UserPlaylist.fromJson(Map<String, dynamic> json) {
    return UserPlaylist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      thumbnail: json['thumbnail'],
      songCount: json['songCount'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class UserPlaylistDetail {
  final String id;
  final String name;
  final String? description;
  final String? thumbnail;
  final bool isPublic;
  final List<UserPlaylistSong> songs;
  final DateTime createdAt;

  UserPlaylistDetail({
    required this.id,
    required this.name,
    required this.isPublic,
    required this.songs,
    required this.createdAt,
    this.description,
    this.thumbnail,
  });

  factory UserPlaylistDetail.fromJson(Map<String, dynamic> json) {
    return UserPlaylistDetail(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      thumbnail: json['thumbnail'],
      isPublic: json['isPublic'] ?? false,
      songs:
          (json['songs'] as List?)
              ?.map((e) => UserPlaylistSong.fromJson(e))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class UserPlaylistSong implements PlayableAudio {
  @override
  final String id;
  final String videoId;
  @override
  final String title;
  @override
  final String artist;
  final String? thumbnail;
  final int? duration;
  @override
  final String? streamUrl;

  @override
  Duration get audioDuration => Duration(seconds: duration ?? 0);

  @override
  String? get bestThumbnail => thumbnail;

  @override
  bool get canPlay => true;

  UserPlaylistSong({
    required this.id,
    required this.videoId,
    required this.title,
    required this.artist,
    this.thumbnail,
    this.duration,
    this.streamUrl,
  });

  factory UserPlaylistSong.fromJson(Map<String, dynamic> json) {
    return UserPlaylistSong(
      id: json['id'] ?? '',
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      thumbnail: json['thumbnail'],
      duration: json['duration'],
      streamUrl: json['streamUrl'],
    );
  }
}

class UserPlaylistsResponse {
  final List<UserPlaylist> data;
  final int total;

  UserPlaylistsResponse({required this.data, required this.total});

  factory UserPlaylistsResponse.fromJson(Map<String, dynamic> json) {
    return UserPlaylistsResponse(
      data:
          (json['data'] as List?)
              ?.map((e) => UserPlaylist.fromJson(e))
              .toList() ??
          [],
      total: json['total'] ?? 0,
    );
  }
}

// ============ Lyrics ============

class LyricsResponse {
  final String? lyrics;
  final String? source;

  const LyricsResponse({this.lyrics, this.source});

  factory LyricsResponse.fromJson(Map<String, dynamic> json) {
    return LyricsResponse(lyrics: json['lyrics'], source: json['source']);
  }
}
