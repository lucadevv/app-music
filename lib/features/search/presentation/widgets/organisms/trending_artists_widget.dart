import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/app_router/app_routes.gr.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';
import 'package:music_app/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:music_app/features/library/data/models/library_models.dart';
import 'package:music_app/features/player/domain/entities/now_playing_data.dart';
import 'package:music_app/features/search/domain/entities/recent_search.dart';
import 'package:music_app/features/search/presentation/cubit/orquestador_search_cubit.dart';
import 'package:music_app/features/search/presentation/cubit/recent_searches_cubit.dart'
    show RecentSearchesStatus;
import 'package:music_app/features/song_options/presentation/widgets/song_options_bottom_sheet.dart';

class RecentSearchesWidget extends StatelessWidget {
  const RecentSearchesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrquestadorSearchCubit, OrquestadorSearchState>(
      builder: (context, orquestadorState) {
        final recentSearchesState = orquestadorState.recentSearchesState;
        final isLoading =
            recentSearchesState.status == RecentSearchesStatus.loading;
        final hasResults =
            recentSearchesState.status == RecentSearchesStatus.success &&
            recentSearchesState.recentSearches.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                'Búsquedas recientes',
                style: TextStyle(
                  color: AppColorsDark.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColorsDark.onSurface,
                    ),
                  ),
                ),
              )
            else if (hasResults)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Builder(
                  builder: (context) {
                    final validRecentSearches =
                        recentSearchesState.recentSearches;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: validRecentSearches.length,
                      itemBuilder: (context, index) {
                        final recentSearch = validRecentSearches[index];
                        return _RecentSearchItem(recentSearch: recentSearch);
                      },
                    );
                  },
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text(
                  'No hay búsquedas recientes',
                  style: TextStyle(
                    color: AppColorsDark.onSurface54,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RecentSearchItem extends StatelessWidget {
  final RecentSearch recentSearch;

  const _RecentSearchItem({required this.recentSearch});

  @override
  Widget build(BuildContext context) {
    final song = recentSearch.songData;

    // Obtener la mejor thumbnail (la más grande disponible)
    final thumbnailUrl = song.bestThumbnail;

    // Obtener nombres de artistas
    final artistsNames = song.artistNames.isNotEmpty
        ? song.artistNames.join(', ')
        : song.artist;

    return GestureDetector(
      onTap: () async {
        // ✅ Save the selected song first to update search state
        context.read<OrquestadorSearchCubit>().saveSelectedSong(
          song,
          recentSearch.query,
        );

        // Crear NowPlayingData con streamUrl actualizado usando fromBasic
        final onTapArtistNames = song.artistNames.isNotEmpty
            ? song.artistNames
            : [song.artist];
        final onTapThumbnailUrl = song.bestThumbnail;

        final nowPlayingData = NowPlayingData.fromBasic(
          videoId: song.videoId,
          title: song.title,
          artistNames: onTapArtistNames,
          albumName: song.album ?? '',
          duration: song.duration,
          durationSeconds: song.durationSeconds,
          views: song.views ?? '0',
          isExplicit: song.isExplicit,
          inLibrary: song.inLibrary,
          thumbnailUrl: onTapThumbnailUrl,
          streamUrl: song.streamUrl,
        );

        // Navegar al player y reproducir la canción - es individual
        if (context.mounted) {
          unawaited(
            context.router.push(
              PlayerRoute(nowPlayingData: nowPlayingData, playAsSingle: true),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            // Thumbnail con Hero animation
            Hero(
              tag: 'song_artwork_${song.videoId}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: thumbnailUrl != null && thumbnailUrl.isValidImageUrl
                    ? CachedNetworkImage(
                        imageUrl: thumbnailUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 60,
                          height: 60,
                          color: AppColorsDark.primaryContainer,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColorsDark.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 60,
                          color: AppColorsDark.primaryContainer,
                          child: const Icon(
                            Icons.music_note,
                            color: AppColorsDark.primary,
                          ),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: AppColorsDark.primaryContainer,
                        child: const Icon(
                          Icons.music_note,
                          color: AppColorsDark.primary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Información de la canción
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: AppColorsDark.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$artistsNames • ${song.album ?? ''}',
                    style: TextStyle(
                      color: AppColorsDark.onSurface.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${song.duration} • ${song.views}',
                    style: TextStyle(
                      color: AppColorsDark.onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Botón de favorito y más opciones
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FavoriteButton(
                  videoId: song.videoId,
                  size: 22,
                  metadata: SongMetadata(
                    title: song.title,
                    artist: artistsNames,
                    thumbnail: thumbnailUrl,
                    duration: song.durationSeconds,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: AppColorsDark.onSurface.withValues(alpha: 0.5),
                  ),
                  onPressed: () {
                    SongOptionsBottomSheet.show(
                      context: context,
                      song: SongOptionsData(
                        videoId: song.videoId,
                        title: song.title,
                        artist: artistsNames,
                        thumbnail: thumbnailUrl,
                        streamUrl: song.streamUrl,
                        durationSeconds: song.durationSeconds,
                        isFavorite: song.inLibrary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
