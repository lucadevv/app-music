import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';
import 'package:music_app/features/downloads/domain/entities/downloaded_song.dart';

/// Widget para mostrar una canción descargada en la lista
///
/// SOLID: Single Responsibility Principle (SRP)
/// Responsable única: Mostrar información de una canción descargada
class DownloadedSongItemWidget extends StatelessWidget {
  final DownloadedSong song;
  final bool isDownloading;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const DownloadedSongItemWidget({
    required this.song,
    required this.isDownloading,
    required this.progress,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      leading: _buildAlbumArt(context),
      title: Text(
        song.title,
        style: Theme.of(context).textTheme.bodyLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            song.artist,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.download_done, size: 14, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                song.fileSizeFormatted,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colorScheme.primary),
              ),
              const SizedBox(width: 8),
              Text(
                song.durationFormatted,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete_outline, color: colorScheme.error),
        onPressed: onDelete,
      ),
    );
  }

  Widget _buildAlbumArt(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surfaceContainerHighest,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: song.thumbnail != null && song.thumbnail!.isValidImageUrl
            ? CachedNetworkImage(
                imageUrl: song.thumbnail!,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.music_note,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                errorWidget: (_, _, _) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.music_note,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : Icon(Icons.music_note, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
