import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';
import 'package:music_app/features/playlist/domain/entities/playlist_response.dart';
import 'package:music_app/features/playlist/presentation/widgets/atoms/playlist_backdrop_widget.dart';
import 'package:music_app/features/search/domain/entities/thumbnail.dart';

/// Widget para el header de la playlist
///
/// SOLID: Single Responsibility Principle (SRP)
/// Responsable única: Mostrar el header de la playlist
class PlaylistHeaderWidget extends StatelessWidget {
  final PlaylistResponse playlist;

  const PlaylistHeaderWidget({required this.playlist, super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener la mejor thumbnail (usar .last + loop para garantizar)
    Thumbnail? bestThumbnail;
    if (playlist.thumbnails.isNotEmpty) {
      bestThumbnail = playlist.thumbnails.last;
      for (final thumbnail in playlist.thumbnails) {
        if (thumbnail.width > bestThumbnail!.width) {
          bestThumbnail = thumbnail;
        }
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PlaylistBackdropWidget(thumbnail: bestThumbnail),
        // Gradient overlay para mejor legibilidad
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                AppColorsDark.surfaceDim.withValues(alpha: 0.3),
                AppColorsDark.surfaceDim.withValues(alpha: 0.7),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              // Imagen de la playlist centrada
              if (bestThumbnail != null && bestThumbnail.url.isValidImageUrl)
                Hero(
                  tag: 'playlist_${playlist.id}',
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColorsDark.surfaceDim.withValues(
                            alpha: 0.4,
                          ),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: bestThumbnail.url,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColorsDark.primaryContainer,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColorsDark.onSurface,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColorsDark.primaryContainer,
                          child: const Icon(
                            Icons.playlist_play,
                            size: 80,
                            color: AppColorsDark.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColorsDark.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColorsDark.surfaceDim.withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.playlist_play,
                    size: 80,
                    color: AppColorsDark.onSurface,
                  ),
                ),
              const SizedBox(height: 24),
              // Título centrado
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  playlist.title,
                  style: const TextStyle(
                    color: AppColorsDark.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              // Metadata centrada
              Text(
                '${playlist.author.name} • ${playlist.trackCount} songs',
                style: TextStyle(
                  color: AppColorsDark.onSurface.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
