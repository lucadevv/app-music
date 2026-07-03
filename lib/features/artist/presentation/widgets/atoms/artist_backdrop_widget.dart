import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';

class ArtistBackdropWidget extends StatelessWidget {
  final String? thumbnail;

  const ArtistBackdropWidget({required this.thumbnail, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColorsDark.primaryContainer, Color(0xFF0D0D0D)],
        ),
      ),
      child: thumbnail != null && thumbnail.isValidImageUrl
          ? CachedNetworkImage(
              imageUrl: thumbnail!,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => _buildDefaultImage(),
            )
          : _buildDefaultImage(),
    );
  }

  Widget _buildDefaultImage() {
    return Center(
      child: Container(
        width: 150,
        height: 150,
        decoration: const BoxDecoration(
          color: AppColorsDark.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person,
          size: 80,
          color: AppColorsDark.onSurface,
        ),
      ),
    );
  }
}
