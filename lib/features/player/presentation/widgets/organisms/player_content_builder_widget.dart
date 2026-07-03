import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/features/dashboard/presentation/bloc/player_bloc_bloc.dart';
import 'package:music_app/features/player/domain/entities/now_playing_data.dart';
import 'package:music_app/features/player/domain/types/player_types.dart';
import 'package:music_app/features/player/presentation/widgets/atoms/player_backdrop_widget.dart';
import 'package:music_app/features/player/presentation/widgets/atoms/player_error_widget.dart';
import 'package:music_app/features/player/presentation/widgets/molecules/player_artwork_widget.dart';
import 'package:music_app/features/player/presentation/widgets/molecules/player_controls_widget.dart';
import 'package:music_app/features/player/presentation/widgets/molecules/player_header_widget.dart';
import 'package:music_app/features/player/presentation/widgets/molecules/player_info_widget.dart';
import 'package:music_app/features/player/presentation/widgets/molecules/player_progress_bar_widget.dart';
import 'package:music_app/features/player/presentation/widgets/organisms/lyrics_widget.dart';
import 'package:music_app/features/player/presentation/widgets/organisms/player_playlist_carousel_widget.dart';
import 'package:music_app/features/player/presentation/widgets/organisms/player_shimmer_widgets.dart';
import 'package:music_app/features/player/presentation/widgets/organisms/player_similar_songs_widget.dart';

/// Widget que construye todo el contenido del PlayerScreen
class PlayerContentBuilderWidget extends StatelessWidget {
  final NowPlayingData nowPlayingData;
  final PlayerBlocState state;
  final bool playAsSingle;
  final bool showFavoriteButton;
  final bool showExtras;

  const PlayerContentBuilderWidget({
    required this.nowPlayingData,
    required this.state,
    required this.playAsSingle,
    required this.showFavoriteButton,
    required this.showExtras,
    super.key,
  });

  bool get isLoaded =>
      state.connectionState == AudioConnectionState.connected ||
      state.connectionState == AudioConnectionState.connecting;

  bool get isCurrentSong =>
      state.currentTrack?.videoId == nowPlayingData.videoId;

  NowPlayingData get currentTrack => state.currentTrack ?? nowPlayingData;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PlayerBackdropWidget(thumbnail: currentTrack.highResThumbnail),
        CustomScrollView(
          slivers: [
            _buildHeader(),
            _buildArtworkSection(),
            _buildControlsSection(context),
            if (showExtras && _shouldShowExtras) _buildExtrasSection(),
            if (state.hasError && isLoaded)
              SliverToBoxAdapter(
                child: PlayerErrorWidget(
                  message: state.error ?? 'Unknown error',
                ),
              ),
            if ((state.isLoading && isLoaded) ||
                (isLoaded && state.isBuffering))
              const SliverToBoxAdapter(child: PlayerShimmerWidget()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ],
    );
  }

  bool get _shouldShowExtras =>
      !(state.hasError && isLoaded) &&
      !((isLoaded && state.isLoading) || (isLoaded && state.isBuffering));

  SliverToBoxAdapter _buildHeader() {
    return SliverToBoxAdapter(
      child: PlayerHeaderWidget(
        playlistId: nowPlayingData.videoId,
        playlistName: nowPlayingData.title,
        currentIndex: state.currentIndex ?? 0,
        totalTracks: state.playlist.length,
        currentVideoId: nowPlayingData.videoId,
        currentTitle: nowPlayingData.title,
        currentArtist: nowPlayingData.artistsNames,
        currentThumbnail: nowPlayingData.bestThumbnail,
        currentDuration: nowPlayingData.durationSeconds,
      ),
    );
  }

  SliverToBoxAdapter _buildArtworkSection() {
    if (state.playlist.length > 1 && !playAsSingle) {
      return SliverToBoxAdapter(
        child: PlayerPlaylistCarouselWidget(
          playlist: state.playlist,
          currentIndex: state.currentIndex ?? 0,
        ),
      );
    }
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: PlayerArtworkWidget(
            thumbnail: currentTrack.highResThumbnail,
            videoId: currentTrack.videoId,
            isLoading: false,
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildControlsSection(BuildContext context) {
    final isPlaying = isLoaded && state.isPlaying;
    final canPlayNext = isLoaded && state.canPlayNext;
    final canPlayPrevious = isLoaded && state.canPlayPrevious;
    final isShuffleEnabled = isLoaded && state.isShuffleEnabled;
    final repeatMode = isLoaded ? state.loopMode : LoopModeType.off;
    final position = state.position;
    final duration = state.duration.inMilliseconds > 0
        ? state.duration
        : Duration(seconds: currentTrack.durationSeconds);
    final isLoading = isLoaded && state.isLoading;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            PlayerInfoWidget(
              track: currentTrack,
              isLoading: isLoading,
              showFavoriteButton: showFavoriteButton,
            ),
            const SizedBox(height: 16),
            PlayerProgressBarWidget(
              position: position,
              duration: duration,
              onSeek: (pos) =>
                  context.read<PlayerBlocBloc>().add(SeekEvent(pos)),
            ),
            const SizedBox(height: 16),
            PlayerControlsWidget(
              isPlaying: isPlaying,
              canPlayNext: canPlayNext,
              canPlayPrevious: canPlayPrevious,
              isShuffleEnabled: isShuffleEnabled,
              loopMode: repeatMode,
              onPlayPause: () => context.read<PlayerBlocBloc>().add(
                const PlayPauseToggleEvent(),
              ),
              onNext: () =>
                  context.read<PlayerBlocBloc>().add(const NextTrackEvent()),
              onPrevious: () => context.read<PlayerBlocBloc>().add(
                const PreviousTrackEvent(),
              ),
              onShuffle: state.playlist.length > 1
                  ? () => context.read<PlayerBlocBloc>().add(
                      const ToggleShuffleEvent(),
                    )
                  : null,
              onRepeat: () {
                final currentMode = repeatMode;
                LoopModeType nextMode;
                if (currentMode == LoopModeType.off) {
                  nextMode = LoopModeType.one;
                } else if (currentMode == LoopModeType.one) {
                  nextMode = LoopModeType.all;
                } else {
                  nextMode = LoopModeType.off;
                }
                context.read<PlayerBlocBloc>().add(SetLoopModeEvent(nextMode));
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildExtrasSection() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          PlayerSimilarSongsWidget(videoId: currentTrack.videoId),
          LyricsWidget(videoId: currentTrack.videoId),
        ],
      ),
    );
  }
}
