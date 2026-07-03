import 'package:flutter/material.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/features/playlist/domain/entities/playlist_response.dart';
import 'package:music_app/features/playlist/domain/entities/playlist_track.dart';
import 'package:music_app/features/playlist/presentation/cubit/playlist_state.dart';
import 'package:music_app/features/playlist/presentation/widgets/molecules/playlist_loading_more_section.dart';
import 'package:music_app/features/playlist/presentation/widgets/molecules/playlist_search_bar.dart';
import 'package:music_app/features/playlist/presentation/widgets/organisms/playlist_actions_widget.dart';
import 'package:music_app/features/playlist/presentation/widgets/organisms/playlist_sliver_app_bar.dart';
import 'package:music_app/features/playlist/presentation/widgets/organisms/playlist_track_list.dart';

class PlaylistScrollContent extends StatelessWidget {
  final PlaylistResponse playlist;
  final PlaylistState playlistState;
  final ScrollController scrollController;
  final TextEditingController searchController;
  final bool showSearch;
  final VoidCallback onToggleSearch;
  final VoidCallback onSearchChanged;
  final VoidCallback onLoadMore;
  final VoidCallback onRefresh;
  final Function(BuildContext, dynamic) onShowMenu;
  final String? currentTrackId;
  final bool isPlaying;
  final Function(PlaylistTrack) onSongTap;
  final Function(PlaylistTrack) onOptionsTap;

  const PlaylistScrollContent({
    required this.playlist,
    required this.playlistState,
    required this.scrollController,
    required this.searchController,
    required this.showSearch,
    required this.onToggleSearch,
    required this.onSearchChanged,
    required this.onLoadMore,
    required this.onRefresh,
    required this.onShowMenu,
    required this.onSongTap, required this.onOptionsTap, this.currentTrackId,
    this.isPlaying = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColorsDark.onSurface,
      backgroundColor: AppColorsDark.surfaceDim54,
      child: CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          PlaylistSliverAppBar(
            playlist: playlist,
            showSearch: showSearch,
            onSearchPressed: onToggleSearch,
            onMorePressed: () => onShowMenu(context, playlist),
          ),
          if (showSearch)
            SliverToBoxAdapter(
              child: PlaylistSearchBar(
                controller: searchController,
                onChanged: (_) => onSearchChanged(),
              ),
            ),
          SliverToBoxAdapter(child: PlaylistActionsWidget(playlist: playlist)),
          PlaylistTrackList(
            tracks: playlistState.filteredResponseTracks,
            searchQuery: searchController.text,
            playlistId: playlist.id,
            currentTrackId: currentTrackId,
            isPlaying: isPlaying,
            onSongTap: onSongTap,
            onOptionsTap: onOptionsTap,
          ),
          PlaylistLoadingMoreSection(
            status: playlistState.status,
            hasMore: playlistState.hasMore,
            loadedCount: playlistState.allTracks.length,
            totalCount: playlistState.response?.trackCount ?? 0,
            onLoadMore: onLoadMore,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
