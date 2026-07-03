import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';
import 'package:music_app/features/player/domain/entities/now_playing_data.dart';
import '../atoms/queue_now_playing_badge.dart';

/// Molecule: Now Playing card with thumbnail, info, and play/pause button
class QueueNowPlayingCard extends StatelessWidget {
  final NowPlayingData track;
  final bool isPlaying;
  final String nowPlayingLabel;

  const QueueNowPlayingCard({
    required this.track,
    required this.isPlaying,
    required this.nowPlayingLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorsDark.onSurface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Thumbnail
          _buildThumbnail(),
          const SizedBox(width: 16),

          // Track info
          Expanded(child: _buildTrackInfo()),

          // Play/Pause button
          _buildPlayPauseButton(context),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 56,
        height: 56,
        color: AppColorsDark.primaryContainer,
        child:
            track.bestThumbnail != null && track.bestThumbnail!.isValidImageUrl
            ? CachedNetworkImage(
                imageUrl: track.bestThumbnail!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) =>
                    const Icon(Icons.music_note, color: AppColorsDark.primary),
              )
            : const Icon(Icons.music_note, color: AppColorsDark.primary),
      ),
    );
  }

  Widget _buildTrackInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QueueNowPlayingBadge(text: nowPlayingLabel),
        const SizedBox(height: 4),
        Text(
          track.title,
          style: const TextStyle(
            color: AppColorsDark.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          track.artistsNames,
          style: const TextStyle(color: AppColorsDark.onSurface, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPlayPauseButton(BuildContext context) {
    return IconButton(
      icon: Icon(
        isPlaying ? Icons.pause : Icons.play_arrow,
        color: AppColorsDark.onSurface,
      ),
      onPressed: () {
        // This will be connected via callback or bloc
      },
    );
  }
}
