import 'package:flutter/material.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/features/liked/presentation/widgets/atoms/play_icon.dart';

class PlayControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback? onPlayTap;
  final VoidCallback? onShuffleTap;

  const PlayControls({
    super.key, 
    this.isPlaying = false,
    this.onPlayTap, 
    this.onShuffleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          PlayIcon(
            isPlaying: isPlaying,
            onTap: onPlayTap,
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.shuffle, color: AppColorsDark.onSurface),
            onPressed: onShuffleTap,
          ),
        ],
      ),
    );
  }
}
