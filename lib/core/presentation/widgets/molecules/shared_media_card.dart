import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';

/// Componente centralizado para Cards de contenido multimedia (Álbumes, Playlists, Artistas)
///
/// Reemplaza a: PlaylistCard, AlbumCardWidget, MusicCard, ArtistAlbumCardMolecule, etc.
class SharedMediaCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? subtitle2;
  final String? imageUrl;
  final VoidCallback? onTap;

  /// El ancho total de la card.
  final double width;

  /// La altura fija de la imagen.
  /// Si es null, la imagen ocupará el espacio restante (usando Expanded)
  final double? imageHeight;

  /// Icono por defecto a mostrar si no hay imagen o falla la carga
  final IconData placeholderIcon;

  /// Si la imagen debe ser circular (e.g. para artistas)
  final bool isCircularImage;

  /// El radio de los bordes
  final double borderRadius;

  const SharedMediaCard({
    required this.title,
    this.subtitle,
    this.subtitle2,
    this.imageUrl,
    this.onTap,
    this.width = 150,
    this.imageHeight,
    this.placeholderIcon = Icons.album,
    this.isCircularImage = false,
    this.borderRadius = 12,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          // Si usa Expanded (imageHeight == null), solemos usar un fondo para la card completa
          color: imageHeight == null
              ? AppColorsDark.onSurface.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageHeight == null)
              Expanded(child: _buildImage())
            else
              _buildImage(),

            Padding(
              padding: imageHeight == null
                  ? const EdgeInsets.all(12)
                  : const EdgeInsets.only(top: 8, left: 4, right: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColorsDark.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: AppColorsDark.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (subtitle2 != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle2!,
                      style: TextStyle(
                        color: AppColorsDark.onSurface.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final shapeRadius = isCircularImage ? 1000.0 : borderRadius;
    final decorationRadius = isCircularImage
        ? BorderRadius.circular(shapeRadius)
        : imageHeight == null
        ? BorderRadius.vertical(top: Radius.circular(shapeRadius))
        : BorderRadius.circular(shapeRadius);

    final Widget imagePlaceholder = Container(
      color: AppColorsDark.primaryContainer,
      height: imageHeight,
      width: width,
      child: Center(
        child: Icon(placeholderIcon, size: 48, color: AppColorsDark.primary),
      ),
    );

    return Container(
      height: imageHeight,
      width: width,
      decoration: BoxDecoration(
        color: AppColorsDark.primaryContainer,
        borderRadius: decorationRadius,
      ),
      child: ClipRRect(
        borderRadius: decorationRadius,
        child: imageUrl.isValidImageUrl
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                width: width,
                height: imageHeight,
                fit: BoxFit.cover,
                placeholder: (context, url) => imagePlaceholder,
                errorWidget: (context, url, error) => imagePlaceholder,
              )
            : imagePlaceholder,
      ),
    );
  }
}
