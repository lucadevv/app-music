import 'package:dio/dio.dart';
import 'package:music_app/core/managers/auth/auth_manager.dart';
import 'package:music_app/core/services/network/api_services.dart';
import 'package:music_app/features/profile/data/models/library_stats_model.dart';
import 'package:music_app/features/profile/data/models/user_profile_model.dart';
import 'package:music_app/features/profile/data/models/user_settings_model.dart';

/// Remote data source for profile feature.
/// Handles all API calls to the backend.
class ProfileRemoteDataSource {
  final ApiServices _api;
  final AuthManager _authManager;

  ProfileRemoteDataSource(this._api, this._authManager);

  /// Get the current user's profile
  Future<UserProfileModel> getProfile() async {
    try {
      final response = await _api.get('/auth/me');
      final data = response is Response ? response.data : response;
      return UserProfileModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Update the current user's profile
  Future<UserProfileModel> updateProfile({
    String? name,
    String? email,
    String? avatar,
  }) async {
    try {
      final response = await _api.put(
        '/auth/me',
        data: {'name': ?name, 'email': ?email, 'avatar': ?avatar},
      );
      final data = response is Response ? response.data : response;
      return UserProfileModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get user settings
  Future<UserSettingsModel> getSettings() async {
    try {
      final response = await _api.get('/users/me/settings');
      final data = response is Response ? response.data : response;
      return UserSettingsModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Update user settings.
  /// NOTE: PUT /users/me/settings does not exist on the backend (returns 404).
  /// Only GET is supported. This throws an UnsupportedError to make the
  /// backend limitation explicit rather than surfacing a cryptic 404.
  Future<UserSettingsModel> updateSettings(UserSettingsModel settings) async {
    throw UnsupportedError(
      'Settings update is not supported by the backend. '
      'PUT /users/me/settings returns 404. '
      'Only GET /users/me/settings is available.',
    );
  }

  /// Get library statistics
  Future<LibraryStatsModel> getLibraryStats() async {
    try {
      final response = await _api.get('/library/summary');
      final data = response is Response ? response.data : response;
      return LibraryStatsModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    try {
      final refreshToken = await _authManager.getCurrentRefreshToken();
      await _api.post('/auth/logout', data: {'refreshToken': refreshToken});
    } catch (e) {
      rethrow;
    }
  }
}
