import 'package:flutter/material.dart';
import 'package:music_app/core/presentation/widgets/song_list_item.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/features/library/data/models/library_models.dart';
import 'package:music_app/features/song_options/presentation/widgets/song_options_bottom_sheet.dart';

class PlaylistSongsListOrganism extends StatelessWidget {
  final List<UserPlaylistSong> songs;
  final Function(int) onPlaySong;

  const PlaylistSongsListOrganism({
    required this.songs,
    required this.onPlaySong,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final song = songs[index];
        return SharedSongListTile.fromPlayable(
          playable: song,
          onTap: () => onPlaySong(index),
          trailing: IconButton(
            icon: Icon(
              Icons.more_vert,
              color: AppColorsDark.onSurface.withValues(alpha: 0.6),
            ),
            onPressed: () {
              SongOptionsBottomSheet.show(
                context: context,
                song: SongOptionsData(
                  videoId: song.videoId,
                  title: song.title,
                  artist: song.artist,
                  thumbnail: song.thumbnail,
                  durationSeconds: song.duration ?? 0,
                  isFavorite: false,
                ),
              );
            },
          ),
        );
      }, childCount: songs.length),
    );
  }
}
