import 'package:flutter/material.dart';
import 'package:music_app/core/presentation/widgets/song_list_item.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:music_app/features/library/data/models/library_models.dart';
import 'package:music_app/features/playlist/domain/entities/playlist_track.dart';
import 'package:music_app/features/playlist/presentation/widgets/atoms/empty_playlist_widget.dart';
import 'package:music_app/features/playlist/presentation/widgets/atoms/playlist_search_result_empty.dart';

class PlaylistTrackList extends StatelessWidget {
  final List<PlaylistTrack> tracks;
  final String searchQuery;
  final String playlistId;
  final String? currentTrackId;
  final bool isPlaying;
  final Function(PlaylistTrack) onSongTap;
  final Function(PlaylistTrack) onOptionsTap;

  const PlaylistTrackList({
    required this.tracks,
    required this.searchQuery,
    required this.playlistId,
    required this.onSongTap, required this.onOptionsTap, this.currentTrackId,
    this.isPlaying = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final filterQueryTextEmpty = searchQuery.isEmpty;

    if (!filterQueryTextEmpty && tracks.isEmpty) {
      return PlaylistSearchResultEmpty(searchQuery: searchQuery);
    }

    if (tracks.isEmpty) {
      return const SliverFillRemaining(child: EmptyPlaylistWidget());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final track = tracks[index];
        final thumbnail = track.thumbnail?.url ??
            (track.thumbnails.isNotEmpty ? track.thumbnails.last.url : null);
        final isDisabled = !track.isAvailable || track.videoId == null || track.videoId!.isEmpty;
        
        final isCurrentTrack = currentTrackId != null && currentTrackId == track.videoId;
        final isCurrentlyPlaying = isCurrentTrack && isPlaying;
        
        final artistNames = track.artists.isNotEmpty ? track.artists.map((e) => e.name).join(', ') : 'Unknown Artist';

        return Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: SharedSongListTile.fromPlayable(
            playable: track,
            onTap: isDisabled ? null : () => onSongTap(track),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  child: isCurrentlyPlaying
                      ? const Icon(Icons.equalizer, color: AppColorsDark.primary, size: 20)
                      : isCurrentTrack
                          ? const Icon(Icons.play_arrow, color: AppColorsDark.primary, size: 20)
                          : Icon(
                              Icons.play_arrow,
                              color: AppColorsDark.onSurface.withValues(alpha: isDisabled ? 0.3 : 0.6),
                              size: 20,
                            ),
                ),
                const SizedBox(width: 8),
                FavoriteButton(
                  videoId: track.videoId ?? '',
                  size: 20,
                  metadata: SongMetadata(
                    title: track.title,
                    artist: artistNames,
                    thumbnail: thumbnail,
                    duration: track.durationSeconds,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: AppColorsDark.onSurface.withValues(alpha: isDisabled ? 0.3 : 0.6),
                    size: 20,
                  ),
                  onPressed: isDisabled ? null : () => onOptionsTap(track),
                ),
              ],
            ),
          ),
        );
      }, childCount: tracks.length),
    );
  }
}
