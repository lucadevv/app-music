// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/material.dart';
import 'package:music_app/core/presentation/widgets/song_list_item.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/features/album/domain/entities/album.dart';
import 'package:music_app/features/album/presentation/cubit/album_cubit.dart';
import 'package:music_app/features/song_options/presentation/widgets/song_options_bottom_sheet.dart';

/// Organismo: Contenido completo del álbum (actions + songs list)
class AlbumContent extends StatelessWidget {
  final Album album;
  final AlbumState state;
  final void Function(AlbumSong song, List<AlbumSong> allSongs)? onSongTap;
  final VoidCallback? onPlayAllPressed;
  final VoidCallback? onLikePressed;

  const AlbumContent({
    required this.album,
    required this.state,
    super.key,
    this.onSongTap,
    this.onPlayAllPressed,
    this.onLikePressed,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Songs list
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final song = state.songs[index];
            return SharedSongListTile.fromPlayable(
              playable: song,
              onTap: () => onSongTap?.call(song, state.songs),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.formattedDuration,
                    style: TextStyle(
                      color: AppColorsDark.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
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
                          artist: '',
                          thumbnail: song.thumbnail,
                          durationSeconds: song.durationSeconds,
                          isFavorite: false,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }, childCount: state.songs.length),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}
