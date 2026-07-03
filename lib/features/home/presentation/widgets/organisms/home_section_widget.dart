import 'package:flutter/material.dart';
import 'package:music_app/core/presentation/widgets/molecules/shared_media_card.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';
import 'package:music_app/core/widgets/song_card.dart';
import 'package:music_app/features/home/domain/entities/home_content_item.dart';
import 'package:music_app/features/home/domain/entities/home_section.dart';

import 'home_content_widgets.dart';

class HomeSectionWidget extends StatelessWidget {
  final HomeSection section;
  final Function(HomeContentItem) onSongTap;
  final Function(HomeContentItem)? onPlaylistTap;
  final Function(HomeContentItem)? onAlbumTap;

  const HomeSectionWidget({
    required this.section,
    required this.onSongTap,
    super.key,
    this.onPlaylistTap,
    this.onAlbumTap,
  });

  @override
  Widget build(BuildContext context) {
    if (section.contents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                section.title,
                style: const TextStyle(
                  color: AppColorsDark.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),

        // Section Content
        _buildContent(),
      ],
    );
  }

  Widget _buildContent() {
    final songs = section.contents
        .where((item) => item.contentType == HomeContentType.song)
        .toList();
    final albums = section.contents
        .where((item) => item.contentType == HomeContentType.album)
        .toList();
    final playlists = section.contents
        .where((item) => item.contentType == HomeContentType.playlist)
        .toList();

    // Use our beautiful new SongCard for songs
    if (songs.length == section.contents.length) {
      return SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: section.contents.length,
          itemBuilder: (context, index) {
            final item = section.contents[index];
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SongCard(
                title: item.title,
                artist: item.album?.name ?? 'Unknown Artist',
                imageUrl: item.bestThumbnailUrl ?? '',
                onTap: () => onSongTap(item),
              ),
            );
          },
        ),
      );
    }

    // For albums (use AlbumCardWidget legacy or replace entirely, using original for now but stylized spacing)
    if (albums.length == section.contents.length) {
      return SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: section.contents.length,
          itemBuilder: (context, index) {
            final item = section.contents[index];
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SharedMediaCard(
                title: item.title,
                subtitle: item.artists.isNotEmpty
                    ? item.artists.map((a) => a.name).join(', ')
                    : null,
                imageUrl: item.bestThumbnailUrl,
                placeholderIcon: Icons.album,
                width: 160,
                onTap: () => onAlbumTap?.call(item),
              ),
            );
          },
        ),
      );
    }

    // For playlists
    if (playlists.length == section.contents.length) {
      return SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: section.contents.length,
          itemBuilder: (context, index) {
            final item = section.contents[index];
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SharedMediaCard(
                title: item.title,
                subtitle: item.description,
                imageUrl: item.bestThumbnailUrl,
                placeholderIcon: Icons.playlist_play,
                width: 160,
                onTap: () => onPlaylistTap?.call(item),
              ),
            );
          },
        ),
      );
    }

    // Mixed list (Fallback)
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: section.contents.length,
      itemBuilder: (context, index) {
        final item = section.contents[index];

        switch (item.contentType) {
          case HomeContentType.song:
            return SongListItemWidget(item: item, onTap: () => onSongTap(item));
          case HomeContentType.album:
            return AlbumListItemWidget(
              item: item,
              onTap: () => onAlbumTap?.call(item),
            );
          case HomeContentType.playlist:
            return PlaylistListItemWidget(
              item: item,
              onTap: () => onPlaylistTap?.call(item),
            );
          case HomeContentType.unknown:
            return const SizedBox.shrink();
        }
      },
    );
  }
}
