import 'package:flutter/material.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';

class PlayIcon extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback? onTap;
  final double size;

  const PlayIcon({super.key, this.isPlaying = false, this.onTap, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColorsDark.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: AppColorsDark.onSurface,
          size: 32,
        ),
      ),
    );
  }
}
