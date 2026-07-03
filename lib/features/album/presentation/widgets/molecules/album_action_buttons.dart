import 'package:flutter/material.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/features/album/presentation/widgets/atoms/atoms.dart';
import 'package:music_app/l10n/app_localizations.dart';

/// Molécula: Botones de acción del álbum
class AlbumActionButtons extends StatelessWidget {
  final bool isLiked;
  final bool isPlayingAlbum;
  final VoidCallback? onPlayPressed;
  final VoidCallback? onLikePressed;
  final VoidCallback? onDownloadPressed;
  final VoidCallback? onShufflePressed;

  const AlbumActionButtons({
    required this.isLiked,
    this.isPlayingAlbum = false,
    super.key,
    this.onDownloadPressed,
    this.onLikePressed,
    this.onPlayPressed,
    this.onShufflePressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          // Play button
          Expanded(
            child: FilledButton.icon(
              onPressed: onPlayPressed,
              icon: Icon(isPlayingAlbum ? Icons.pause : Icons.play_arrow),
              label: Text(isPlayingAlbum ? l10n.pause : l10n.play),
              style: FilledButton.styleFrom(
                backgroundColor: AppColorsDark.primary,
                foregroundColor: AppColorsDark.onSurface,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Like button
          LikeButton(isLiked: isLiked, onPressed: onLikePressed),

          // Download button
          IconActionButton(icon: Icons.download, onPressed: onDownloadPressed),

          // Shuffle button
          IconActionButton(icon: Icons.shuffle, onPressed: onShufflePressed),
        ],
      ),
    );
  }
}
