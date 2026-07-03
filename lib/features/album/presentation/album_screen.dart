// ignore_for_file: deprecated_member_use_from_same_package
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:music_app/core/app_router/app_routes.gr.dart';
import 'package:music_app/core/presentation/widgets/song_list_item.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/features/album/domain/entities/album.dart';
import 'package:music_app/features/album/domain/repositories/album_repository.dart';
import 'package:music_app/features/album/domain/use_cases/get_album_songs_use_case.dart';
import 'package:music_app/features/album/domain/use_cases/get_album_use_case.dart';
import 'package:music_app/features/album/domain/use_cases/is_liked_album_use_case.dart';
import 'package:music_app/features/album/domain/use_cases/like_album_use_case.dart';
import 'package:music_app/features/album/domain/use_cases/unlike_album_use_case.dart';
import 'package:music_app/features/album/presentation/cubit/album_cubit.dart';
import 'package:music_app/features/album/presentation/widgets/molecules/molecules.dart';
import 'package:music_app/features/album/presentation/widgets/organisms/organisms.dart';
import 'package:music_app/features/dashboard/presentation/bloc/player_bloc_bloc.dart';
import 'package:music_app/features/song_options/presentation/widgets/song_options_bottom_sheet.dart';

@RoutePage()
class AlbumScreen extends StatelessWidget implements AutoRouteWrapper {
  final String albumId;

  const AlbumScreen({@PathParam('id') required this.albumId, super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final albumRepository = GetIt.I<AlbumRepository>();
    return BlocProvider(
      create: (_) => AlbumCubit(
        getAlbumUseCase: GetAlbumUseCase(albumRepository),
        getAlbumSongsUseCase: GetAlbumSongsUseCase(albumRepository),
        likeAlbumUseCase: LikeAlbumUseCase(albumRepository),
        unlikeAlbumUseCase: UnlikeAlbumUseCase(albumRepository),
        isLikedAlbumUseCase: IsLikedAlbumUseCase(albumRepository),
        playerBloc: context.read<PlayerBlocBloc>(),
      )..loadAlbum(albumId),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AlbumScreenContainer(albumId: albumId);
  }
}

/// CONTAINER WIDGET
/// Maneja la inyección, dependencias, BLoC State y Navegación (Routing).
/// No contiene UI renderizada (colores, paddings, scaffolds).
class _AlbumScreenContainer extends StatelessWidget {
  final String albumId;

  const _AlbumScreenContainer({required this.albumId});

  void _handlePlaySong(BuildContext context, AlbumSong song, List<AlbumSong> allSongs) {
    final cubit = context.read<AlbumCubit>();
    final success = cubit.playSong(song, allSongs);

    if (success) {
      final nowPlayingData = cubit.mapAlbumSongToNowPlaying(song);
      context.router.push(
        PlayerRoute(nowPlayingData: nowPlayingData, playAsSingle: true),
      );
    }
  }

  void _handlePlayAllSongs(BuildContext context, List<AlbumSong> songs) {
    if (songs.isEmpty) return;
    
    final playerBloc = context.read<PlayerBlocBloc>();
    final isPlayingAlbum = playerBloc.state.sourceId?.startsWith('album_$albumId') == true && playerBloc.state.isPlaying;
    
    if (isPlayingAlbum) {
      playerBloc.add(const PauseEvent());
      return;
    } else if (playerBloc.state.sourceId?.startsWith('album_$albumId') == true) {
      playerBloc.add(const PlayEvent());
      return;
    }

    final cubit = context.read<AlbumCubit>();
    final nowPlayingData = cubit.playAllAlbumSongs(songs);

    if (nowPlayingData != null) {
      context.router.push(
        PlayerRoute(nowPlayingData: nowPlayingData, playAsSingle: false),
      );
    }
  }

  void _handleSongOptions(BuildContext context, AlbumSong song) {
    SongOptionsBottomSheet.show(
      context: context,
      song: SongOptionsData(
        videoId: song.videoId,
        title: song.title,
        artist: '',
        thumbnail: song.thumbnail,
        durationSeconds: song.durationSeconds,
        isFavorite: false, // Update with actual state if available
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBlocBloc, PlayerBlocState>(
      builder: (context, playerState) {
        final isPlayingAlbum = playerState.sourceId?.startsWith('album_$albumId') == true && playerState.isPlaying;
        return BlocBuilder<AlbumCubit, AlbumState>(
          builder: (context, state) {
            return _AlbumPresentationalView(
              state: state,
              isPlayingAlbum: isPlayingAlbum,
              onRetry: () => context.read<AlbumCubit>().loadAlbum(albumId),
              onRefresh: () async => context.read<AlbumCubit>().loadAlbum(albumId),
              onBackPressed: () => context.router.pop(),
              onLikePressed: () => context.read<AlbumCubit>().toggleLike(),
              onPlayAllPressed: () => _handlePlayAllSongs(context, state.songs),
              onSongTap: (song) => _handlePlaySong(context, song, state.songs),
              onOptionsTap: (song) => _handleSongOptions(context, song),
            );
          },
        );
      },
    );
  }
}

/// PRESENTATIONAL VIEW
/// Componente tonto (Dumb Component). No sabe nada de Cubit, BLoC o Auth.
/// Solo recibe datos y callbacks por constructor y pinta la UI.
class _AlbumPresentationalView extends StatelessWidget {
  final AlbumState state;
  final bool isPlayingAlbum;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;
  final VoidCallback onBackPressed;
  final VoidCallback onLikePressed;
  final VoidCallback onPlayAllPressed;
  final Function(AlbumSong) onSongTap;
  final Function(AlbumSong) onOptionsTap;

  const _AlbumPresentationalView({
    required this.state,
    required this.isPlayingAlbum,
    required this.onRetry,
    required this.onRefresh,
    required this.onBackPressed,
    required this.onLikePressed,
    required this.onPlayAllPressed,
    required this.onSongTap,
    required this.onOptionsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (state.status == AlbumStatus.loading) {
      return const AlbumLoadingView();
    }

    if (state.status == AlbumStatus.failure) {
      return AlbumErrorView(
        errorMessage: state.errorMessage,
        onRetry: onRetry,
      );
    }

    final album = state.album;
    if (album == null) {
      return Center(
        child: Text(
          'Álbum no encontrado',
          style: TextStyle(
            color: AppColorsDark.onSurface.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColorsDark.primary,
      onRefresh: onRefresh,
      child: _buildContent(album),
    );
  }

  Widget _buildContent(Album album) {
    return CustomScrollView(
      slivers: [
        // App Bar
        AlbumAppBar(album: album, onBackPressed: onBackPressed),

        // Action buttons
        SliverToBoxAdapter(
          child: AlbumActionButtons(
            isLiked: state.isLiked,
            isPlayingAlbum: isPlayingAlbum,
            onPlayPressed: onPlayAllPressed,
            onLikePressed: onLikePressed,
          ),
        ),

        // Songs list
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final song = state.songs[index];
            return SharedSongListTile.fromPlayable(
              playable: song,
              onTap: () => onSongTap(song),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.formattedDuration,
                    style: TextStyle(
                      color: AppColorsDark.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: AppColorsDark.onSurface.withValues(alpha: 0.6),
                    ),
                    onPressed: () => onOptionsTap(song),
                  ),
                ],
              ),
            );
          }, childCount: state.songs.length),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}
