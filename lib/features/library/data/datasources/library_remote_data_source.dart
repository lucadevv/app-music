// ignore_for_file: avoid_dynamic_calls
import 'package:dio/dio.dart';
import 'package:music_app/core/services/network/api_services.dart';
import '../models/library_models.dart';

/// Remote data source for library feature.
/// Handles all API calls to the backend using proper DTOs.
class LibraryRemoteDataSource {
  final ApiServices _api;

  LibraryRemoteDataSource(this._api);

  /// Get library summary (favorite songs count, playlists count, etc.)
  Future<LibrarySummary> getSummary() async {
    try {
      final response = await _api.get('/library/summary');
      final data = response is Response ? response.data : response;
      return LibrarySummary.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get favorite songs with pagination
  Future<FavoriteSongsResponse> getFavoriteSongs({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _api.get(
        '/library/songs',
        queryParameters: {
          'page': page,
          'limit': limit,
          'include_stream_urls': true,
        },
      );
      final data = response is Response ? response.data : response;
      return FavoriteSongsResponse.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get favorite playlists
  Future<FavoritePlaylistsResponse> getFavoritePlaylists({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _api.get(
        '/library/playlists',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response is Response ? response.data : response;
      return FavoritePlaylistsResponse.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get favorite genres
  Future<FavoriteGenresResponse> getFavoriteGenres({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _api.get(
        '/library/genres',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response is Response ? response.data : response;
      return FavoriteGenresResponse.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Add song to favorites.
  /// Backend only accepts {videoId, title, artist} — thumbnail and duration
  /// are accepted as params for caller compatibility but NOT sent to the API.
  Future<void> addFavoriteSong({
    required String videoId,
    String? title,
    String? artist,
    String? thumbnail,
    int? duration,
  }) async {
    try {
      await _api.post(
        '/library/songs',
        data: {'videoId': videoId, 'title': title, 'artist': artist},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Remove song from favorites
  Future<void> removeFavoriteSong(String videoId) async {
    try {
      await _api.delete('/library/songs/$videoId');
    } catch (e) {
      rethrow;
    }
  }

  /// Check if song is favorite.
  /// NOTE: The backend endpoint /library/songs/:videoId/check currently returns 500.
  /// We gracefully return false on any error — if we can't verify, assume not favorite.
  Future<bool> isSongFavorite(String videoId) async {
    try {
      final response = await _api.get('/library/songs/$videoId/check');
      final data = response is Response ? response.data : response;
      return data['isFavorite'] ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Add playlist to favorites
  Future<void> addFavoritePlaylist(
    String externalPlaylistId, {
    String? name,
    String? thumbnail,
    String? description,
    int? trackCount,
  }) async {
    try {
      await _api.post(
        '/library/playlists',
        data: {
          'externalPlaylistId': externalPlaylistId,
          'name': ?name,
          'thumbnail': ?thumbnail,
          'description': ?description,
          'trackCount': ?trackCount,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Remove playlist from favorites
  Future<void> removeFavoritePlaylist(String playlistId) async {
    try {
      await _api.delete('/library/playlists/$playlistId');
    } catch (e) {
      rethrow;
    }
  }

  /// Add genre to favorites
  Future<void> addFavoriteGenre(String externalParams, {String? name}) async {
    try {
      await _api.post(
        '/library/genres',
        data: {'externalParams': externalParams, 'name': ?name},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Remove genre from favorites
  Future<void> removeFavoriteGenre(String genreId) async {
    try {
      await _api.delete('/library/genres/$genreId');
    } catch (e) {
      rethrow;
    }
  }

  /// Get user playlists
  Future<UserPlaylistsResponse> getUserPlaylists({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _api.get(
        '/library/user-playlists',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response is Response ? response.data : response;
      return UserPlaylistsResponse.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Create user playlist
  Future<UserPlaylist> createUserPlaylist({
    required String name,
    String? description,
    String? thumbnail,
    bool isPublic = false,
  }) async {
    try {
      final response = await _api.post(
        '/library/user-playlists',
        data: {
          'name': name,
          'description': ?description,
          'thumbnail': ?thumbnail,
          'isPublic': isPublic,
        },
      );
      final data = response is Response ? response.data : response;
      return UserPlaylist.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get user playlist by ID
  Future<UserPlaylistDetail> getUserPlaylist(String playlistId) async {
    try {
      final response = await _api.get('/library/user-playlists/$playlistId');
      final data = response is Response ? response.data : response;
      return UserPlaylistDetail.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Update user playlist
  Future<UserPlaylistDetail> updateUserPlaylist(
    String playlistId, {
    String? name,
    String? description,
    String? thumbnail,
    bool? isPublic,
  }) async {
    try {
      final response = await _api.put(
        '/library/user-playlists/$playlistId',
        data: {
          'name': ?name,
          'description': ?description,
          'thumbnail': ?thumbnail,
          'isPublic': ?isPublic,
        },
      );
      final data = response is Response ? response.data : response;
      return UserPlaylistDetail.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete user playlist
  Future<void> deleteUserPlaylist(String playlistId) async {
    try {
      await _api.delete('/library/user-playlists/$playlistId');
    } catch (e) {
      rethrow;
    }
  }

  /// Add song to user playlist
  Future<UserPlaylistDetail> addSongToUserPlaylist(
    String playlistId, {
    required String videoId,
    String? title,
    String? artist,
    String? thumbnail,
    int? duration,
  }) async {
    try {
      final response = await _api.post(
        '/library/user-playlists/$playlistId/songs',
        data: {
          'videoId': videoId,
          'title': ?title,
          'artist': ?artist,
          'thumbnail': ?thumbnail,
          'duration': ?duration,
        },
      );
      final data = response is Response ? response.data : response;
      return UserPlaylistDetail.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Remove song from user playlist
  Future<void> removeSongFromUserPlaylist(
    String playlistId,
    String songId,
  ) async {
    try {
      await _api.delete('/library/user-playlists/$playlistId/songs/$songId');
    } catch (e) {
      rethrow;
    }
  }

  /// Get lyrics for a song
  Future<LyricsResponse> getLyrics(String videoIdOrBrowseId) async {
    try {
      final response = await _api.get('/music/lyrics/$videoIdOrBrowseId');
      final data = response is Response ? response.data : response;
      return LyricsResponse.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }
}
