import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/app_router/app_routes.gr.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';
import 'package:music_app/features/dashboard/presentation/bloc/player_bloc_bloc.dart';
import 'package:music_app/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:music_app/features/library/data/models/library_models.dart';
import 'package:music_app/features/player/domain/entities/now_playing_data.dart';

class MiniPlayer extends StatelessWidget {
  final bool showFavoriteButton;

  const MiniPlayer({super.key, this.showFavoriteButton = true});

  @override
  Widget build(BuildContext context) {
    final playerBloc = context.read<PlayerBlocBloc>();

    return BlocBuilder<PlayerBlocBloc, PlayerBlocState>(
      bloc: playerBloc,
      builder: (context, state) {
        if (state.currentTrack == null) {
          return const SizedBox.shrink();
        }

        final track = state.currentTrack!;
        final isPlaying = state.isPlaying;
        final position = state.position;
        final duration = state.duration.inSeconds > 0
            ? state.duration
            : Duration(seconds: track.durationSeconds);

        return GestureDetector(
          onTap: () => _openPlayer(context, track),
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColorsDark.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColorsDark.onSurface.withValues(alpha: 0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColorsDark.surfaceDim.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ProgressBar(position: position, duration: duration),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              _TrackThumbnail(thumbnail: track.bestThumbnail),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _TrackInfo(
                                  title: track.title,
                                  artist: track.artistsNames,
                                ),
                              ),
                              if (showFavoriteButton)
                                FavoriteButton(
                                  videoId: track.videoId,
                                  size: 22,
                                  metadata: SongMetadata(
                                    title: track.title,
                                    artist: track.artistsNames,
                                    thumbnail: track.highResThumbnail.url,
                                    duration: track.durationSeconds,
                                    streamUrl: track.streamUrl,
                                  ),
                                ),
                              _PlayerControls(
                                isPlaying: isPlaying,
                                canPlayNext: state.canPlayNext,
                                onPlayPause: () => playerBloc.add(
                                  const PlayPauseToggleEvent(),
                                ),
                                onNext: state.canPlayNext
                                    ? () =>
                                          playerBloc.add(const NextTrackEvent())
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openPlayer(BuildContext context, NowPlayingData track) {
    // Abrir el player - mantener el estado actual de playlist
    context.router.push(
      PlayerRoute(nowPlayingData: track, playAsSingle: false),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;

  const _ProgressBar({required this.position, required this.duration});

  @override
  Widget build(BuildContext context) {
    final progress = duration.inSeconds > 0
        ? position.inSeconds / duration.inSeconds
        : 0.0;

    return SizedBox(
      height: 3,
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(
          AppColorsDark.primary.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _TrackThumbnail extends StatelessWidget {
  final String? thumbnail;

  const _TrackThumbnail({required this.thumbnail});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: thumbnail != null && thumbnail!.isValidImageUrl
          ? CachedNetworkImage(
              imageUrl: thumbnail!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 48,
                height: 48,
                color: AppColorsDark.primaryContainer,
                child: const Icon(
                  Icons.music_note,
                  color: AppColorsDark.primary,
                  size: 24,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 48,
                height: 48,
                color: AppColorsDark.primaryContainer,
                child: const Icon(
                  Icons.music_note,
                  color: AppColorsDark.primary,
                  size: 24,
                ),
              ),
            )
          : Container(
              width: 48,
              height: 48,
              color: AppColorsDark.primaryContainer,
              child: const Icon(
                Icons.music_note,
                color: AppColorsDark.primary,
                size: 24,
              ),
            ),
    );
  }
}

class _TrackInfo extends StatelessWidget {
  final String title;
  final String artist;

  const _TrackInfo({required this.title, required this.artist});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColorsDark.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          artist,
          style: TextStyle(
            color: AppColorsDark.onSurface.withValues(alpha: 0.7),
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _PlayerControls extends StatelessWidget {
  final bool isPlaying;
  final bool canPlayNext;
  final VoidCallback onPlayPause;
  final VoidCallback? onNext;

  const _PlayerControls({
    required this.isPlaying,
    required this.canPlayNext,
    required this.onPlayPause,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPlayPause,
          icon: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            color: AppColorsDark.onSurface,
            size: 28,
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: Icon(
            Icons.skip_next,
            color: onNext != null
                ? AppColorsDark.onSurface
                : AppColorsDark.onSurface.withValues(alpha: 0.3),
            size: 28,
          ),
        ),
      ],
    );
  }
}
