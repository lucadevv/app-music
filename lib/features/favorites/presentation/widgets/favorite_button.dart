import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/features/favorites/presentation/cubit/favorite_cubit.dart';
import 'package:music_app/features/library/data/models/library_models.dart';
import 'package:music_app/features/library/domain/entities/favorite_type.dart';

class FavoriteButton extends StatefulWidget {
  final String videoId;
  final String? songId;
  final FavoriteType type;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showBackground;
  final VoidCallback? onToggle;
  final SongMetadata? metadata;
  final PlaylistMetadata? playlistMetadata;

  const FavoriteButton({
    required this.videoId,
    super.key,
    this.songId,
    this.type = FavoriteType.song,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
    this.showBackground = false,
    this.onToggle,
    this.metadata,
    this.playlistMetadata,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(FavoriteCubit cubit, bool isCurrentlyFavorite) {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    _controller.forward().then((_) => _controller.reverse());

    cubit.toggleFavorite(
      videoId: widget.videoId,
      songId: widget.songId,
      type: widget.type,
      isCurrentlyFavorite: isCurrentlyFavorite,
      metadata: widget.metadata,
      playlistMetadata: widget.playlistMetadata,
    );

    widget.onToggle?.call();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // FavoriteCubit está provisto en app.dart, usamos context.watch directamente
    return BlocBuilder<FavoriteCubit, FavoriteState>(
      builder: (context, state) {
        final isFavorite = _checkIsFavorite(state);

        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(scale: _scaleAnimation.value, child: child);
          },
          child: GestureDetector(
            onTap: _isProcessing
                ? null
                : () => _handleTap(context.read<FavoriteCubit>(), isFavorite),
            child: Container(
              padding: widget.showBackground ? const EdgeInsets.all(8) : null,
              decoration: widget.showBackground
                  ? BoxDecoration(
                      color: AppColorsDark.onSurface.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite
                    ? (widget.activeColor ?? AppColorsDark.primary)
                    : (widget.inactiveColor ??
                          AppColorsDark.onSurface.withValues(alpha: 0.6)),
                size: widget.size,
              ),
            ),
          ),
        );
      },
    );
  }

  bool _checkIsFavorite(FavoriteState state) {
    switch (widget.type) {
      case FavoriteType.song:
        return state.favoriteSongs.contains(widget.videoId);
      case FavoriteType.playlist:
        return state.favoritePlaylists.contains(widget.videoId);
      case FavoriteType.genre:
        return state.favoriteGenres.contains(widget.videoId);
    }
  }
}
