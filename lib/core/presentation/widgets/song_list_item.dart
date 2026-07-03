import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_app/core/domain/entities/playable_audio.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';

class SharedSongListTile extends StatelessWidget {
  final String title;
  final String artist;
  final String? thumbnail;
  final Widget? trailing;
  final bool isCurrentTrack;
  final bool isPlaying;
  final VoidCallback? onTap;

  const SharedSongListTile({
    required this.title,
    required this.artist,
    this.thumbnail,
    this.trailing,
    this.isCurrentTrack = false,
    this.isPlaying = false,
    this.onTap,
    super.key,
  });

  factory SharedSongListTile.fromPlayable({
    required PlayableAudio playable,
    Widget? trailing,
    bool isCurrentTrack = false,
    bool isPlaying = false,
    VoidCallback? onTap,
    Key? key,
  }) {
    return SharedSongListTile(
      key: key,
      title: playable.title,
      artist: playable.artist,
      thumbnail: playable.bestThumbnail,
      trailing: trailing,
      isCurrentTrack: isCurrentTrack,
      isPlaying: isPlaying,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            // Thumbnail
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: thumbnail != null && thumbnail.isValidImageUrl
                      ? CachedNetworkImage(
                          imageUrl: thumbnail!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              const _FallbackIcon(),
                        )
                      : const _FallbackIcon(),
                ),
                if (isCurrentTrack)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isPlaying ? Icons.equalizer : Icons.play_arrow,
                      color: AppColorsDark.primary,
                      size: 24,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isCurrentTrack
                          ? AppColorsDark.primary
                          : AppColorsDark.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artist,
                    style: TextStyle(
                      color: AppColorsDark.onSurface.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      color: AppColorsDark.surfaceContainerHighest,
      child: const Icon(Icons.music_note, color: AppColorsDark.onSurface24),
    );
  }
}
