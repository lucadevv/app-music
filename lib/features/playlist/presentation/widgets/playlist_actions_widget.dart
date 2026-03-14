import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/features/dashboard/presentation/bloc/player_bloc_bloc.dart';
import 'package:music_app/features/favorites/presentation/cubit/favorite_cubit.dart';
import 'package:music_app/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:music_app/features/library/library_service.dart';
import 'package:music_app/features/playlist/domain/entities/playlist_response.dart';
import 'package:music_app/features/playlist/presentation/cubit/playlist_cubit.dart';
import 'package:music_app/features/playlist/presentation/cubit/playlist_state.dart';

/// Widget para los botones de acción de la playlist
class PlaylistActionsWidget extends StatelessWidget {
  final PlaylistResponse playlist;

  const PlaylistActionsWidget({required this.playlist, super.key});

  /// Obtiene la mejor thumbnail disponible
  String? _getBestThumbnail() {
    if (playlist.thumbnails.isEmpty) return null;

    // Ordenar por ancho y obtener la más grande
    final sortedThumbnails = List.of(playlist.thumbnails)
      ..sort((a, b) => b.width.compareTo(a.width));

    return sortedThumbnails.first.url;
  }

   /// Verifica si la playlist actual es la que está reproduciéndose
   bool _isCurrentPlaylistPlaying(PlayerBlocState playerState) {
     // Compare sourceId with this playlist's ID
     // This ensures we show PLAY even if the song is in multiple playlists
     return playerState.sourceId == playlist.id && playerState.isPlaying;
   }

  @override
  Widget build(BuildContext context) {
    final playerBloc = context.read<PlayerBlocBloc>();
    final playlistCubit = context.read<PlaylistCubit>();

    return BlocBuilder<PlaylistCubit, PlaylistState>(
      builder: (context, playlistState) {
        return BlocListener<PlayerBlocBloc, PlayerBlocState>(
          listenWhen: (previous, current) {
            // Llamar completeLoading cuando:
            // - Esta playlist estaba cargando
            // - El player confirma reproducción (posición >= 5s o reproduciendo)
            final wasLoading = playlistState.loadingPlaylistId == playlist.id;
            final isNowPlaying = current.position.inSeconds >= 5 || current.isPlaying;
            return wasLoading && isNowPlaying;
          },
          listener: (context, state) {
            playlistCubit.completeLoading();
          },
          child: BlocBuilder<PlayerBlocBloc, PlayerBlocState>(
            builder: (context, playerState) {
              // Estado de carga del cubit
            final isLoadingForPlay = playlistState.isLoadingForPlay;
            final loadingPlaylistId = playlistState.loadingPlaylistId;
            final isThisPlaylistLoading = loadingPlaylistId == playlist.id;

            // Verificar si la playlist actual está reproduciéndose
            final isCurrentPlaylist = _isCurrentPlaylistPlaying(playerState);
            final isPlaying = playerState.isPlaying;
            
            // DEBUG: Verificar valores
            print('DEBUG playlist_actions: sourceId=${playerState.sourceId}, playlist.id=${playlist.id}, isCurrentPlaylist=$isCurrentPlaylist, isPlaying=$isPlaying');

            // El botón muestra:
            // - Loading solo la primera vez que se inicia playAll de ESTA playlist
            // - Play si no hay canción reproduciéndose O si es otra playlist
            // - Pause si es la misma playlist y está reproduciéndose
            final showPause = isCurrentPlaylist && isPlaying;

            // Mostrar loading solo si:
            // - Es esta playlist la que está cargando, Y
            // - El player no ha confirmado reproducción (posición < 5s o buffering)
            final showLoading = isThisPlaylistLoading && 
                !showPause && 
                (playerState.position.inSeconds < 5 || playerState.isBuffering);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  // Botón de play/pause
                  GestureDetector(
                    onTap: showLoading
                        ? null
                        : () {
                            // Si es la misma playlist y hay algo reproducido, togglear
                            if (isCurrentPlaylist && playerState.hasCurrentTrack) {
                              playerBloc.add(const PlayPauseToggleEvent());
                            } else {
                              // Es otra playlist o no hay nada - cargar esta playlist
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
                            color: AppColorsDark.primary.withValues(alpha: 0.4),
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
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(
                              showPause ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 36,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Botón de favorito
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
                  // Botón de shuffle
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: playerState.isShuffleEnabled 
                          ? AppColorsDark.primary 
                          : Colors.white,
                      size: 28,
                    ),
                    onPressed: playlist.tracks.length > 1
                        ? () => playerBloc.add(const ToggleShuffleEvent())
                        : null,
                  ),
                  const SizedBox(width: 8),
                  // Botón de loop
                  IconButton(
                    icon: Icon(
                      playerState.loopMode == LoopMode.one 
                          ? Icons.repeat_one 
                          : Icons.repeat,
                      color: playerState.loopMode != LoopMode.off
                          ? AppColorsDark.primary
                          : Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      // Cycle: off -> one -> all -> off
                      final currentMode = playerState.loopMode;
                      LoopMode nextMode;
                      if (currentMode == LoopMode.off) {
                        nextMode = LoopMode.one;
                      } else if (currentMode == LoopMode.one) {
                        nextMode = LoopMode.all;
                      } else {
                        nextMode = LoopMode.off;
                      }
                      playerBloc.add(SetLoopModeEvent(nextMode));
                    },
                  ),
                  const SizedBox(width: 8),
                  // Botón de descarga (solo visual por ahora)
                  const IconButton(
                    icon: Icon(
                      Icons.download_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: null, // Sin funcionalidad por ahora
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
}
