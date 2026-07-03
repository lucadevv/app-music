// ignore_for_file: unused_element
import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/app_router/app_routes.gr.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';
import 'package:music_app/features/dashboard/presentation/bloc/player_bloc_bloc.dart';
import 'package:music_app/features/player/domain/entities/now_playing_data.dart';
import 'package:music_app/l10n/app_localizations.dart';

import 'widgets/atoms/atoms.dart';
import 'widgets/molecules/molecules.dart';
import 'widgets/organisms/organisms.dart';

@RoutePage()
class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: _buildAppBar(context, l10n),
      body: BlocBuilder<PlayerBlocBloc, PlayerBlocState>(
        builder: (context, state) {
          return Column(
            children: [
              // Now playing
              _buildNowPlaying(context, state, l10n),

              // Up Next
              QueueUpNextHeader(
                upNextLabel: l10n.upNext,
                autoRecommendationsLabel: l10n.autoRecommendations,
                onAutoRecommendationsTap: () {},
              ),

              // Queue list
              Expanded(
                child: QueueList(
                  playlist: state.playlist,
                  currentIndex: state.currentIndex ?? -1,
                  emptyLabel: 'La cola está vacía',
                  onTrackTap: (track, index) {
                    context.read<PlayerBlocBloc>().add(
                      PlayTrackAtIndexEvent(index),
                    );
                    context.router.push(
                      PlayerRoute(nowPlayingData: track, playAsSingle: false),
                    );
                  },
                  onTrackRemove: (index) {
                    context.read<PlayerBlocBloc>().add(
                      RemoveFromPlaylistEvent(index),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  QueueAppBar _buildAppBar(BuildContext context, AppLocalizations l10n) {
    return QueueAppBar(
      title: l10n.queue,
      clearLabel: l10n.clear,
      onClear: () {
        final state = context.read<PlayerBlocBloc>().state;
        if (state.playlist.isNotEmpty) {
          context.read<PlayerBlocBloc>().add(
            const LoadPlaylistEvent(
              playlist: [],
              startIndex: 0,
              sourceId: 'queue',
            ),
          );
        }
      },
      onBack: () => context.router.pop(),
    );
  }

  Widget _buildNowPlaying(
    BuildContext context,
    PlayerBlocState state,
    AppLocalizations l10n,
  ) {
    final track = state.currentTrack;
    if (track == null) return const SizedBox.shrink();

    return _NowPlayingCard(
      track: track,
      isPlaying: state.isPlaying,
      nowPlayingLabel: l10n.nowPlaying,
      onPlayPause: () {
        context.read<PlayerBlocBloc>().add(const PlayPauseToggleEvent());
      },
    );
  }
}

/// Now Playing card widget (kept inline for bloc integration)
class _NowPlayingCard extends StatelessWidget {
  final NowPlayingData track;
  final bool isPlaying;
  final String nowPlayingLabel;
  final VoidCallback onPlayPause;

  const _NowPlayingCard({
    required this.track,
    required this.isPlaying,
    required this.nowPlayingLabel,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorsDark.onSurface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 56,
              height: 56,
              color: AppColorsDark.primaryContainer,
              child:
                  track.bestThumbnail != null &&
                      track.bestThumbnail!.isValidImageUrl
                  ? CachedNetworkImage(
                      imageUrl: track.bestThumbnail!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const Icon(
                        Icons.music_note,
                        color: AppColorsDark.primary,
                      ),
                    )
                  : const Icon(Icons.music_note, color: AppColorsDark.primary),
            ),
          ),
          const SizedBox(width: 16),

          // Track info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QueueNowPlayingBadge(text: nowPlayingLabel),
                const SizedBox(height: 4),
                Text(
                  track.title,
                  style: const TextStyle(
                    color: AppColorsDark.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  track.artistsNames,
                  style: const TextStyle(
                    color: AppColorsDark.onSurface,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Play/Pause button
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: AppColorsDark.onSurface,
            ),
            onPressed: onPlayPause,
          ),
        ],
      ),
    );
  }
}
