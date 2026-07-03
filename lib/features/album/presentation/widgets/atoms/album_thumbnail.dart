import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';

/// Átomo: Miniatura del álbum
class AlbumThumbnail extends StatelessWidget {
  final String? thumbnailUrl;
  final double size;
  final double borderRadius;

  const AlbumThumbnail({
    super.key,
    this.thumbnailUrl,
    this.size = 180,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        color: AppColorsDark.primary,
        child: thumbnailUrl != null && thumbnailUrl.isValidImageUrl
            ? CachedNetworkImage(
                imageUrl: thumbnailUrl!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Icon(Icons.album, size: size * 0.44, color: AppColorsDark.onSurface);
  }
}
