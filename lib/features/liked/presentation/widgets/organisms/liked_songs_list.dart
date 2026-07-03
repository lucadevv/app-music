import 'package:flutter/material.dart';
import 'package:music_app/core/presentation/widgets/song_list_item.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/features/library/data/models/library_models.dart';

class LikedSongsList extends StatelessWidget {
  final List<FavoriteSong> songs;
  final bool isLoadingMore;
  final bool hasMore;
  final String? currentTrackId;
  final bool isPlaying;
  final void Function(FavoriteSong song, int index)? onSongTap;
  final void Function(FavoriteSong song)? onRemove;

  const LikedSongsList({
    required this.songs,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.currentTrackId,
    this.isPlaying = false,
    this.onSongTap,
    this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        // Mostrar indicador de carga al final de la lista
        if (index == songs.length) {
          if (isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColorsDark.primary,
                  strokeWidth: 2,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final song = songs[index];
        final isCurrentTrack = song.videoId == currentTrackId;
        
        return SharedSongListTile.fromPlayable(
          playable: song,
          isCurrentTrack: isCurrentTrack,
          isPlaying: isPlaying && isCurrentTrack,
          onTap: onSongTap != null ? () => onSongTap!(song, index) : null,
          trailing: onRemove != null ? IconButton(
            icon: const Icon(Icons.close, color: AppColorsDark.onSurface54),
            onPressed: () => onRemove!(song),
          ) : null,
        );
      }, childCount: songs.length + (isLoadingMore || hasMore ? 1 : 0)),
    );
  }
}
