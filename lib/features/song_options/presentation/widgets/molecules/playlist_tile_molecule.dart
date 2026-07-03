import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';
import 'package:music_app/features/library/data/models/library_models.dart';

/// Molecule: Playlist tile for playlist selection
class PlaylistTileMolecule extends StatelessWidget {
  final UserPlaylist playlist;
  final VoidCallback onTap;

  const PlaylistTileMolecule({
    required this.playlist,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColorsDark.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: playlist.thumbnail != null && playlist.thumbnail!.isValidImageUrl
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: playlist.thumbnail!,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const Icon(
                    Icons.queue_music,
                    color: AppColorsDark.primary,
                  ),
                ),
              )
            : const Icon(Icons.queue_music, color: AppColorsDark.primary),
      ),
      title: Text(
        playlist.name,
        style: const TextStyle(color: AppColorsDark.onSurface),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${playlist.songCount} canciones',
        style: TextStyle(color: AppColorsDark.onSurface.withValues(alpha: 0.6)),
      ),
      onTap: onTap,
    );
  }
}
