import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';
import 'package:music_app/features/search/domain/entities/thumbnail.dart';

/// Widget para el backdrop difuminado de la imagen de la canción
///
/// SOLID: Single Responsibility Principle (SRP)
/// Responsable única: Mostrar el backdrop difuminado de la imagen
class PlayerBackdropWidget extends StatelessWidget {
  final Thumbnail? thumbnail;

  const PlayerBackdropWidget({required this.thumbnail, super.key});

  @override
  Widget build(BuildContext context) {
    if (thumbnail == null || !thumbnail!.url.isValidImageUrl) {
      return Container(color: const Color(0xFF0D0D0D));
    }

    return Positioned.fill(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: CachedNetworkImageProvider(thumbnail!.url),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                AppColorsDark.surfaceDim.withValues(alpha: 0.7),
                BlendMode.darken,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
