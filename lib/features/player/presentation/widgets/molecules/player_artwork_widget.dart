import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';
import 'package:music_app/features/search/domain/entities/thumbnail.dart';

/// Widget para mostrar el artwork del álbum con Hero animation
///
/// SOLID: Single Responsibility Principle (SRP)
/// Responsable única: Mostrar el artwork del álbum
class PlayerArtworkWidget extends StatelessWidget {
  final Thumbnail? thumbnail;
  final String videoId;
  final bool isLoading;
  final bool isBuffering;

  const PlayerArtworkWidget({
    required this.thumbnail,
    required this.videoId,
    super.key,
    this.isLoading = false,
    this.isBuffering = false,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'song_artwork_$videoId',
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 380,
            decoration: BoxDecoration(
              color: AppColorsDark.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(36),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: thumbnail != null && thumbnail!.url.isValidImageUrl
                  ? CachedNetworkImage(
                      imageUrl: thumbnail!.url,
                      width: double.infinity,
                      height: 380,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _PlaceholderWidget(),
                      errorWidget: (context, url, error) => _ErrorWidget(),
                    )
                  : _ErrorWidget(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColorsDark.primaryContainer,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColorsDark.primary),
        ),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColorsDark.primaryContainer,
      child: const Icon(
        Icons.music_note,
        size: 120,
        color: AppColorsDark.primary,
      ),
    );
  }
}
