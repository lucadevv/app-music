import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';

class GridImage extends StatelessWidget {
  final String url;
  final double height;
  final double width;

  const GridImage({
    required this.url,
    required this.height,
    super.key,
    this.width = 110,
  });

  @override
  Widget build(BuildContext context) {
    if (!url.isValidImageUrl) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColorsDark.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.music_note,
          color: AppColorsDark.onSurfaceVariant,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColorsDark.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColorsDark.surfaceDim.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              Container(color: AppColorsDark.surfaceContainerHigh),
          errorWidget: (context, url, error) => const Icon(
            Icons.music_note,
            color: AppColorsDark.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
