import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/app_router/app_routes.gr.dart';
import 'package:music_app/core/presentation/widgets/song_list_item.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/features/dashboard/presentation/bloc/player_bloc_bloc.dart';
import 'package:music_app/features/library/data/models/library_models.dart';
import 'package:music_app/features/library/presentation/cubit/library_cubit.dart';
import 'package:music_app/l10n/app_localizations.dart';

/// Sección de canciones en la biblioteca.
class SongsSection extends StatelessWidget {
  final List<FavoriteSong> songs;
  final bool showViewAll;
  final void Function(FavoriteSong song, AppLocalizations l10n) onShowOptions;
  final bool usePlayAllFromIndex;

  const SongsSection({
    required this.songs,
    required this.onShowOptions,
    this.showViewAll = true,
    this.usePlayAllFromIndex = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.likedSongs,
                style: const TextStyle(
                  color: AppColorsDark.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              if (showViewAll && songs.length > 5)
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
        BlocBuilder<PlayerBlocBloc, PlayerBlocState>(
          builder: (context, playerState) {
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                final isCurrentTrack = playerState.currentTrack?.videoId == song.videoId;

                return SharedSongListTile.fromPlayable(
                  playable: song,
                  isCurrentTrack: isCurrentTrack,
                  isPlaying: playerState.isPlaying && isCurrentTrack,
                  onTap: () => _onSongTap(context, song, index, playerState),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => onShowOptions(song, l10n),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _onSongTap(BuildContext context, FavoriteSong song, int index, PlayerBlocState playerState) {
    final playerBloc = context.read<PlayerBlocBloc>();
    
    if (playerState.currentTrack?.videoId == song.videoId) {
      playerBloc.add(const PlayPauseToggleEvent());
      return;
    }

    final cubit = context.read<LibraryCubit>();

    final nowPlayingData = usePlayAllFromIndex
        ? cubit.playAllFavoriteSongsFromIndex(songs, index)
        : cubit.playSong(song);

    if (nowPlayingData != null) {
      context.router.push(
        PlayerRoute(
          nowPlayingData: nowPlayingData,
          playAsSingle: !usePlayAllFromIndex,
        ),
      );
    }
  }
}
