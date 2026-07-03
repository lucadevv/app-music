import 'package:flutter/material.dart';
import 'package:music_app/core/domain/entities/artist.dart';
import 'package:music_app/core/presentation/widgets/song_list_item.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/features/song_options/presentation/widgets/song_options_bottom_sheet.dart';
import 'package:music_app/l10n/app_localizations.dart';

class ArtistTopSongsOrganism extends StatelessWidget {
  final List<ArtistSong> songs;
  final void Function(ArtistSong song, List<ArtistSong> allSongs) onSongTap;

  const ArtistTopSongsOrganism({
    required this.songs,
    required this.onSongTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (songs.isEmpty) {
      return const SizedBox.shrink();
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
            child: _buildSectionTitle(l10n.popular),
          ),
        ),
        _buildSongsList(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColorsDark.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSongsList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final song = songs[index];
        return SharedSongListTile.fromPlayable(
          playable: song,
          onTap: () => onSongTap(song, songs),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                song.formattedDuration,
                style: TextStyle(
                  color: AppColorsDark.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
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
      }, childCount: songs.length),
    );
  }
}
