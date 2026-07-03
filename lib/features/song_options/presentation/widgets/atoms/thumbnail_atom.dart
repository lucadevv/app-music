import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';

/// Atom: Thumbnail image with placeholder
class ThumbnailAtom extends StatelessWidget {
  final String? thumbnailUrl;
  final double size;
  final double borderRadius;
  final IconData placeholderIcon;

  const ThumbnailAtom({
    super.key,
    this.thumbnailUrl,
    this.size = 48,
    this.borderRadius = 4,
    this.placeholderIcon = Icons.music_note,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        color: AppColorsDark.primaryContainer,
        child: thumbnailUrl != null && thumbnailUrl.isValidImageUrl
            ? CachedNetworkImage(
                imageUrl: thumbnailUrl!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    Icon(placeholderIcon, color: AppColorsDark.primary),
              )
            : Icon(placeholderIcon, color: AppColorsDark.primary),
      ),
    );
  }
}
