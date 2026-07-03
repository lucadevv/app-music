import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_app/core/presentation/widgets/song_list_item.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';
import 'package:music_app/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:music_app/features/home/domain/entities/home_content_item.dart';
import 'package:music_app/features/library/data/models/library_models.dart';
import 'package:music_app/features/song_options/presentation/widgets/song_options_bottom_sheet.dart';

/// Widget para mostrar una canción en formato card horizontal
class SongCardWidget extends StatelessWidget {
  final HomeContentItem item;
  final VoidCallback onTap;

  const SongCardWidget({required this.item, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final thumbnail = item.thumbnails.isNotEmpty ? item.thumbnails.last : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColorsDark.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColorsDark.primaryContainer,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: thumbnail != null && thumbnail.url.isValidImageUrl
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: thumbnail.url,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColorsDark.primary,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.music_note,
                            size: 60,
                            color: AppColorsDark.primary,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.music_note,
                          size: 60,
                          color: AppColorsDark.primary,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: AppColorsDark.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.artists.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.artists.map((a) => a.name).join(', '),
                      style: TextStyle(
                        color: AppColorsDark.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para mostrar una playlist en formato card horizontal

/// Widget para mostrar un álbum en formato lista vertical
class AlbumListItemWidget extends StatelessWidget {
  final HomeContentItem item;
  final VoidCallback? onTap;

  const AlbumListItemWidget({required this.item, super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final thumbnail = item.thumbnails.isNotEmpty ? item.thumbnails.last : null;
    final artistsNames = item.artists.map((a) => a.name).join(', ');

    return GestureDetector(
      onTap: onTap,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: thumbnail != null && thumbnail.url.isValidImageUrl
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: thumbnail.url,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 56,
                    height: 56,
                    color: AppColorsDark.primaryContainer,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColorsDark.primary,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColorsDark.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.album,
                      color: AppColorsDark.primary,
                    ),
                  ),
                ),
              )
            : Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColorsDark.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.album, color: AppColorsDark.primary),
              ),
        title: Text(
          item.title,
          style: const TextStyle(
            color: AppColorsDark.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Álbum • ${artistsNames.isNotEmpty ? artistsNames : "Various Artists"}',
          style: TextStyle(
            color: AppColorsDark.onSurface.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.more_vert,
            color: AppColorsDark.onSurface.withValues(alpha: 0.6),
          ),
          onPressed: () {
            final thumb = item.thumbnails.isNotEmpty
                ? item.thumbnails.last
                : null;
            SongOptionsBottomSheet.show(
              context: context,
              song: SongOptionsData(
                videoId: item.videoId ?? '',
                title: item.title,
                artist: artistsNames.isNotEmpty
                    ? artistsNames
                    : 'Various Artists',
                thumbnail: thumb?.url,
                streamUrl: item.streamUrl,
                isFavorite: false,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Widget para mostrar una canción en formato lista vertical
class SongListItemWidget extends StatelessWidget {
  final HomeContentItem item;
  final VoidCallback onTap;

  const SongListItemWidget({
    required this.item,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final artistsNames = item.artists.map((a) => a.name).join(', ');

    return SharedSongListTile(
      title: item.title,
      artist: artistsNames,
      thumbnail: item.bestThumbnailUrl,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FavoriteButton(
            videoId: item.videoId ?? '',
            size: 22,
            metadata: SongMetadata(
              title: item.title,
              artist: artistsNames,
              thumbnail: item.bestThumbnailUrl,
              streamUrl: item.streamUrl,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: AppColorsDark.onSurface.withValues(alpha: 0.6),
            ),
            onPressed: () {
              SongOptionsBottomSheet.show(
                context: context,
                song: SongOptionsData(
                  videoId: item.videoId ?? '',
                  title: item.title,
                  artist: artistsNames,
                  thumbnail: item.bestThumbnailUrl,
                  streamUrl: item.streamUrl,
                  isFavorite: false,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar una playlist en formato lista vertical
class PlaylistListItemWidget extends StatelessWidget {
  final HomeContentItem item;
  final VoidCallback? onTap;

  const PlaylistListItemWidget({required this.item, super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Usar .last para obtener el thumbnail de mejor calidad
    final thumbnail = item.thumbnails.isNotEmpty ? item.thumbnails.last : null;

    return GestureDetector(
      onTap: onTap,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: thumbnail != null && thumbnail.url.isValidImageUrl
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: thumbnail.url,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 56,
                    height: 56,
                    color: AppColorsDark.primaryContainer,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColorsDark.primary,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColorsDark.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.playlist_play,
                      color: AppColorsDark.primary,
                    ),
                  ),
                ),
              )
            : Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColorsDark.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.playlist_play,
                  color: AppColorsDark.primary,
                ),
              ),
        title: Text(
          item.title,
          style: const TextStyle(
            color: AppColorsDark.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          item.description ?? '',
          style: TextStyle(
            color: AppColorsDark.onSurface.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.more_vert,
            color: AppColorsDark.onSurface.withValues(alpha: 0.6),
          ),
          onPressed: () {
            final thumb = item.thumbnails.isNotEmpty
                ? item.thumbnails.last
                : null;
            SongOptionsBottomSheet.show(
              context: context,
              song: SongOptionsData(
                videoId: item.videoId ?? '',
                title: item.title,
                artist: item.artists.map((a) => a.name).join(', '),
                thumbnail: thumb?.url,
                streamUrl: item.streamUrl,
                isFavorite: false,
              ),
            );
          },
        ),
      ),
    );
  }
}
