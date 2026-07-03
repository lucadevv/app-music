import 'package:music_app/features/mood_genre/data/data_sources/mood_genre_remote_data_source.dart';
import 'package:music_app/features/relax/domain/entities/relax_entity.dart';

/// Data source for relax playlists.
/// Reuses MoodGenreRemoteDataSource for API calls.
class RelaxDataSource {
  final MoodGenreRemoteDataSourceImpl _moodDataSource;

  RelaxDataSource(this._moodDataSource);

  /// Get relax playlists
  Future<List<RelaxPlaylistEntity>> getRelaxPlaylists() async {
    final result = await _moodDataSource.getMoodPlaylists('relax');

    return result.fold((error) => [], (response) {
      // Filter for relax-related moods from playlists
      final relaxMoods = [
        'morning',
        'evening',
        'focus',
        'sleep',
        'relax',
        'calm',
      ];

      return response.playlists
          .where(
            (playlist) => relaxMoods.contains(playlist.title.toLowerCase()),
          )
          .map(
            (playlist) => RelaxPlaylistEntity(
              id: playlist.playlistId,
              title: playlist.title,
              description: playlist.description ?? '',
              thumbnail:
                  playlist.thumbnail != null && playlist.thumbnail!.isNotEmpty
                  ? playlist.thumbnail!.first
                  : null,
              category: '',
            ),
          )
          .toList();
    });
  }
}
