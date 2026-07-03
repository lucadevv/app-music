import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/app_router/app_routes.gr.dart';
import 'package:music_app/features/dashboard/presentation/bloc/player_bloc_bloc.dart';
import 'package:music_app/features/library/data/models/library_models.dart';
import 'package:music_app/features/liked/domain/use_cases/add_liked_song_use_case.dart';
import 'package:music_app/features/liked/domain/use_cases/get_liked_songs_use_case.dart';
import 'package:music_app/features/liked/domain/use_cases/is_song_liked_use_case.dart';
import 'package:music_app/features/liked/domain/use_cases/remove_liked_song_use_case.dart';
import 'package:music_app/features/liked/presentation/cubit/liked_songs_cubit.dart';
import 'package:music_app/features/liked/presentation/widgets/widgets.dart';
import 'package:music_app/features/player/domain/entities/now_playing_data.dart';
import 'package:music_app/l10n/app_localizations.dart';
import 'package:music_app/main.dart';

@RoutePage()
class LikedSongsScreen extends StatelessWidget {
  const LikedSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LikedSongsCubit(
        getLikedSongsUseCase: getIt<GetLikedSongsUseCase>(),
        addLikedSongUseCase: getIt<AddLikedSongUseCase>(),
        removeLikedSongUseCase: getIt<RemoveLikedSongUseCase>(),
        isSongLikedUseCase: getIt<IsSongLikedUseCase>(),
      )..loadLikedSongs(),
      child: const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: _LikedSongsScreenView(),
      ),
    );
  }
}

class _LikedSongsScreenView extends StatefulWidget {
  const _LikedSongsScreenView();

  @override
  State<_LikedSongsScreenView> createState() => _LikedSongsScreenViewState();
}

class _LikedSongsScreenViewState extends State<_LikedSongsScreenView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      context.read<LikedSongsCubit>().loadMoreSongs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<LikedSongsCubit, LikedSongsState>(
      builder: (context, state) {
        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildHeader(context, state, l10n),
            if (state.status == LikedSongsStatus.loading)
              const SliverFillRemaining(child: LikedSongsLoading())
            else if (state.status == LikedSongsStatus.failure)
              SliverFillRemaining(
                child: ErrorState(
                  message: state.errorMessage ?? l10n.errorLoadingSongs,
                  retryText: l10n.retry,
                  onRetry: () =>
                      context.read<LikedSongsCubit>().loadLikedSongs(),
                ),
              )
            else ...[
              _buildPlayButton(context, state),
              BlocBuilder<PlayerBlocBloc, PlayerBlocState>(
                builder: (context, playerState) {
                  return _buildSongsList(context, state, l10n, playerState);
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    LikedSongsState state,
    AppLocalizations l10n,
  ) {
    final totalText = state.totalSongs > 0
        ? '${state.totalSongs} ${l10n.likedSongsCount}'
        : l10n.likedSongs;

    return LikedSongsHeader(
      title: l10n.likedSongs,
      subtitle: totalText,
      onBackTap: () => context.router.maybePop(),
      onSearchTap: () {},
      onMoreTap: () {},
    );
  }

  Widget _buildPlayButton(BuildContext context, LikedSongsState state) {
    if (state.songs.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: BlocBuilder<PlayerBlocBloc, PlayerBlocState>(
        builder: (context, playerState) {
          final isPlayingLikedSongs = playerState.sourceId == 'liked_songs' && playerState.isPlaying;
          
          return PlayControls(
            isPlaying: isPlayingLikedSongs,
            onPlayTap: () => _playAll(context, state.songs),
            onShuffleTap: () {},
          );
        },
      ),
    );
  }

  Widget _buildSongsList(
    BuildContext context,
    LikedSongsState state,
    AppLocalizations l10n,
    PlayerBlocState playerState,
  ) {
    if (state.songs.isEmpty) {
      return SliverFillRemaining(
        child: EmptyLikedSongs(
          title: l10n.noLikedSongsYet,
          subtitle: l10n.songsYouLikeWillAppearHere,
        ),
      );
    }

    return LikedSongsList(
      songs: state.songs,
      isLoadingMore: state.isLoadingMore,
      hasMore: state.hasMoreSongs,
      currentTrackId: playerState.currentTrack?.videoId,
      isPlaying: playerState.isPlaying,
      onSongTap: (song, index) => _playSong(context, song, index, state.songs),
      onRemove: (song) => _removeSong(context, song),
    );
  }

  void _playAll(BuildContext context, List<FavoriteSong> songs) {
    if (songs.isEmpty) return;

    final playerBloc = context.read<PlayerBlocBloc>();
    
    // Check if we are already playing liked songs
    if (playerBloc.state.sourceId == 'liked_songs') {
      if (playerBloc.state.isPlaying) {
        playerBloc.add(const PauseEvent());
        return;
      } else if (playerBloc.state.hasCurrentTrack) {
        playerBloc.add(const PlayEvent());
        return;
      }
    }

    final playlist = songs.map(_mapFavoriteSongToNowPlaying).toList();

    playerBloc.add(
      LoadPlaylistEvent(
        playlist: playlist,
        startIndex: 0,
        sourceId: 'liked_songs',
      ),
    );

    context.router.push(
      PlayerRoute(nowPlayingData: playlist[0], playAsSingle: false),
    );
  }

  void _playSong(BuildContext context, FavoriteSong song, int index, List<FavoriteSong> songs) {
    final playerBloc = context.read<PlayerBlocBloc>();
    final nowPlayingData = _mapFavoriteSongToNowPlaying(song);

    if (playerBloc.state.currentTrack?.videoId == song.videoId) {
      playerBloc.add(const PlayPauseToggleEvent());
      return;
    }

    final playlist = songs.map(_mapFavoriteSongToNowPlaying).toList();

    playerBloc.add(
      LoadPlaylistEvent(
        playlist: playlist,
        startIndex: index,
        sourceId: 'liked_songs',
      ),
    );

    context.router.push(
      PlayerRoute(nowPlayingData: nowPlayingData, playAsSingle: false),
    );
  }

  void _removeSong(BuildContext context, FavoriteSong song) {
    context.read<LikedSongsCubit>().removeSong(song.videoId);
  }

  NowPlayingData _mapFavoriteSongToNowPlaying(FavoriteSong song) {
    return NowPlayingData.fromBasic(
      videoId: song.videoId,
      title: song.title,
      artistNames: song.artist.split(', '),
      albumName: '',
      duration: song.duration != null
          ? _formatDuration(song.duration!)
          : '0:00',
      durationSeconds: song.duration,
      thumbnailUrl: song.thumbnail,
      streamUrl: song.streamUrl,
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}
