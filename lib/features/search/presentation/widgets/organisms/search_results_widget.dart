// ignore_for_file: deprecated_member_use_from_same_package, unawaited_futures
import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/app_router/app_routes.gr.dart';
import 'package:music_app/core/domain/mappers/song_mapper.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';
import 'package:music_app/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:music_app/features/library/data/models/library_models.dart';
import 'package:music_app/features/player/domain/entities/now_playing_data.dart';
import 'package:music_app/features/search/domain/entities/song.dart';
import 'package:music_app/features/search/presentation/cubit/orquestador_search_cubit.dart';
import 'package:music_app/features/song_options/presentation/widgets/song_options_bottom_sheet.dart';

class SearchResultsWidget extends StatefulWidget {
  final List<Song> results;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;
  final String query;

  const SearchResultsWidget({
    required this.results,
    required this.query,
    this.hasMore = false,
    this.onLoadMore,
    this.isLoadingMore = false,
    super.key,
  });

  @override
  State<SearchResultsWidget> createState() => _SearchResultsWidgetState();
}

class _SearchResultsWidgetState extends State<SearchResultsWidget> {
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
        _scrollController.position.maxScrollExtent - 200) {
      if (widget.hasMore &&
          !widget.isLoadingMore &&
          widget.onLoadMore != null) {
        widget.onLoadMore!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No se encontraron resultados',
            style: TextStyle(color: AppColorsDark.onSurface, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: widget.results.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Mostrar indicador de carga al final
        if (index == widget.results.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColorsDark.primary,
                ),
              ),
            ),
          );
        }

        final song = widget.results[index];
        return _SongItem(song: song, query: widget.query);
      },
    );
  }
}

class _SongItem extends StatelessWidget {
  final Song song;
  final String query;

  const _SongItem({required this.song, required this.query});

  Future<void> _onSongSelected(BuildContext context) async {
    // Actualizar la búsqueda reciente con la canción seleccionada
    // Fire and forget - no bloqueamos la navegación
    context.read<OrquestadorSearchCubit>().saveSelectedSong(
      SongMapper.fromSearchSong(song),
      query,
    );

    // Crear NowPlayingData con streamUrl actualizado usando fromBasic
    final artistsNames = song.artists.map((a) => a.name).toList();
    final thumbnailUrl = song.thumbnails.isNotEmpty
        ? song.thumbnails.last.url
        : null;

    final nowPlayingData = NowPlayingData.fromBasic(
      videoId: song.videoId,
      title: song.title,
      artistNames: artistsNames,
      albumName: song.album.name,
      duration: song.duration,
      durationSeconds: song.durationSeconds,
      views: song.views,
      isExplicit: song.isExplicit,
      inLibrary: song.inLibrary,
      thumbnailUrl: thumbnailUrl,
      streamUrl: song.streamUrl,
    );

    if (context.mounted) {
      context.router.push(
        PlayerRoute(nowPlayingData: nowPlayingData, playAsSingle: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final thumbnail = song.thumbnails.isNotEmpty ? song.thumbnails.last : null;
    final artistsNames = song.artists.map((a) => a.name).join(', ');

    return GestureDetector(
      onTap: () => _onSongSelected(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Hero(
              tag: 'song_artwork_${song.videoId}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: thumbnail != null && thumbnail.url.isValidImageUrl
                    ? CachedNetworkImage(
                        imageUrl: thumbnail.url,
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
                    '$artistsNames • ${song.album.name}',
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FavoriteButton(
                  videoId: song.videoId,
                  size: 22,
                  metadata: SongMetadata(
                    title: song.title,
                    artist: artistsNames,
                    thumbnail: thumbnail?.url,
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
                        thumbnail: thumbnail?.url,
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
