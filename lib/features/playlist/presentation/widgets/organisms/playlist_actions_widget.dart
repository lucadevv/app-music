import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/features/dashboard/presentation/bloc/player_bloc_bloc.dart';
import 'package:music_app/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:music_app/features/library/data/models/library_models.dart';
import 'package:music_app/features/library/domain/entities/favorite_type.dart';
import 'package:music_app/features/player/domain/entities/now_playing_data.dart';
import 'package:music_app/features/player/domain/types/player_types.dart';
import 'package:music_app/features/playlist/domain/entities/playlist_response.dart';
import 'package:music_app/features/playlist/presentation/cubit/playlist_cubit.dart';
import 'package:music_app/features/playlist/presentation/cubit/playlist_state.dart';

class PlaylistActionsWidget extends StatelessWidget {
  final PlaylistResponse playlist;

  const PlaylistActionsWidget({required this.playlist, super.key});

  String? _getBestThumbnail() {
    if (playlist.thumbnails.isEmpty) return null;
    final sortedThumbnails = List.of(playlist.thumbnails)
      ..sort((a, b) => b.width.compareTo(a.width));
    return sortedThumbnails.first.url;
  }

  bool _isCurrentPlaylist(PlayerBlocState playerState) {
    return playerState.sourceId == playlist.id;
  }

  @override
  Widget build(BuildContext context) {
    final playerBloc = context.read<PlayerBlocBloc>();
    final playlistCubit = context.read<PlaylistCubit>();

    return BlocBuilder<PlaylistCubit, PlaylistState>(
      builder: (context, playlistState) {
        return BlocListener<PlayerBlocBloc, PlayerBlocState>(
          listenWhen: (previous, current) {
            final wasLoading = playlistState.loadingPlaylistId == playlist.id;
            final isNowPlaying =
                current.position.inSeconds >= 5 || current.isPlaying;
            return wasLoading && isNowPlaying;
          },
          listener: (context, state) {
            playlistCubit.completeLoading();
          },
          child: BlocBuilder<PlayerBlocBloc, PlayerBlocState>(
            builder: (context, playerState) {
              final loadingPlaylistId = playlistState.loadingPlaylistId;
              final isThisPlaylistLoading = loadingPlaylistId == playlist.id;
              final isCurrentPlaylist = _isCurrentPlaylist(playerState);
              final isPlaying = playerState.isPlaying;

              final showPause = isCurrentPlaylist && isPlaying;

              final showLoading =
                  isThisPlaylistLoading &&
                  !showPause &&
                  (playerState.position.inSeconds < 5 ||
                      playerState.isBuffering);

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: showLoading
                          ? null
                          : () {
                              if (isCurrentPlaylist &&
                                  playerState.hasCurrentTrack) {
                                playerBloc.add(const PlayPauseToggleEvent());
                              } else {
                                playlistCubit.playAll();
                              }
                            },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColorsDark.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColorsDark.primary.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: showLoading
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColorsDark.onSurface,
                                  ),
                                ),
                              )
                            : Icon(
                                showPause ? Icons.pause : Icons.play_arrow,
                                color: AppColorsDark.onSurface,
                                size: 36,
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FavoriteButton(
                      videoId: playlist.id,
                      type: FavoriteType.playlist,
                      size: 28,
                      playlistMetadata: PlaylistMetadata(
                        name: playlist.title,
                        thumbnail: _getBestThumbnail(),
                        description: playlist.description.isNotEmpty
                            ? playlist.description
                            : null,
                        trackCount: playlist.trackCount,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: playerState.isShuffleEnabled
                            ? AppColorsDark.primary
                            : AppColorsDark.onSurface,
                        size: 28,
                      ),
                      onPressed: playlist.tracks.length > 1
                          ? () => _onShufflePlay(
                              context,
                              playlistCubit,
                              playerBloc,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        playerState.loopMode == LoopModeType.one
                            ? Icons.repeat_one
                            : Icons.repeat,
                        color: playerState.loopMode != LoopModeType.off
                            ? AppColorsDark.primary
                            : AppColorsDark.onSurface,
                        size: 28,
                      ),
                      onPressed: () {
                        final currentMode = playerState.loopMode;
                        LoopModeType nextMode;
                        if (currentMode == LoopModeType.off) {
                          nextMode = LoopModeType.one;
                        } else if (currentMode == LoopModeType.one) {
                          nextMode = LoopModeType.all;
                        } else {
                          nextMode = LoopModeType.off;
                        }
                        playerBloc.add(SetLoopModeEvent(nextMode));
                      },
                    ),
                    const SizedBox(width: 8),
                    const IconButton(
                      icon: Icon(
                        Icons.download_outlined,
                        color: AppColorsDark.onSurface,
                        size: 28,
                      ),
                      onPressed: null,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _onShufflePlay(
    BuildContext context,
    PlaylistCubit playlistCubit,
    PlayerBlocBloc playerBloc,
  ) {
    final allTracks = playlistCubit.state.allTracks.isNotEmpty
        ? playlistCubit.state.allTracks
        : playlist.tracks;

    if (allTracks.isEmpty) return;

    final validTracks = allTracks
        .where(
          (track) =>
              track.videoId != null &&
              track.videoId!.isNotEmpty &&
              track.isAvailable &&
              track.streamUrl != null &&
              track.streamUrl!.isNotEmpty,
        )
        .toList();

    if (validTracks.isEmpty) return;

    validTracks.shuffle();

    final nowPlayingTracks = validTracks.map((track) {
      return NowPlayingData.fromPlaylistTrack(track);
    }).toList();

    playerBloc.add(
      LoadPlaylistEvent(
        playlist: nowPlayingTracks,
        startIndex: 0,
        sourceId: 'shuffle:${playlist.id}',
      ),
    );
  }
}
