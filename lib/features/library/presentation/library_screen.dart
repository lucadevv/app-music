// ignore_for_file: dead_code, dead_null_aware_expression, unused_element
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/features/dashboard/presentation/bloc/player_bloc_bloc.dart';
import 'package:music_app/features/library/data/models/library_models.dart';
import 'package:music_app/features/library/domain/use_cases/add_favorite_song_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/create_user_playlist_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/get_aggregated_library_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/get_favorite_songs_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/remove_favorite_song_use_case.dart';
import 'package:music_app/features/library/presentation/cubit/library_cubit.dart';
import 'package:music_app/features/library/presentation/widgets/molecules/library_error_view.dart';
import 'package:music_app/features/library/presentation/widgets/organisms/create_playlist_dialog.dart';
import 'package:music_app/features/library/presentation/widgets/organisms/library_filtered_content.dart';
import 'package:music_app/features/library/presentation/widgets/organisms/library_header.dart';
import 'package:music_app/features/library/presentation/widgets/organisms/library_loading_view.dart';
import 'package:music_app/features/library/presentation/widgets/organisms/quick_access_section.dart';
import 'package:music_app/features/library/presentation/widgets/templates/library_empty_state.dart';
import 'package:music_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:music_app/features/song_options/presentation/widgets/song_options_bottom_sheet.dart';
import 'package:music_app/l10n/app_localizations.dart';

@RoutePage()
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileCubit = context.read<ProfileCubit>();
      if (!profileCubit.state.isLoading && profileCubit.state.profile == null) {
        profileCubit.loadProfile();
      }
    });
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (ctx) => LibraryCubit(
            getAggregatedLibraryUseCase: GetIt.I<GetAggregatedLibraryUseCase>(),
            getFavoriteSongsUseCase: GetIt.I<GetFavoriteSongsUseCase>(),
            addFavoriteSongUseCase: GetIt.I<AddFavoriteSongUseCase>(),
            removeFavoriteSongUseCase: GetIt.I<RemoveFavoriteSongUseCase>(),
            createUserPlaylistUseCase: GetIt.I<CreateUserPlaylistUseCase>(),
            playerBloc: ctx.read<PlayerBlocBloc>(),
          )..loadLibrary(),
        ),
      ],
      child: const _LibraryContainer(),
    );
  }
}

class _LibraryContainer extends StatefulWidget {
  const _LibraryContainer();

  @override
  State<_LibraryContainer> createState() => _LibraryContainerState();
}

class _LibraryContainerState extends State<_LibraryContainer> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      context.read<LibraryCubit>().loadMoreSongs();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.toLowerCase();
    });
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await CreatePlaylistDialog.show(context);

    if (result != null && result.isNotEmpty && context.mounted) {
      await context.read<LibraryCubit>().createPlaylist(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.createPlaylist}: $result'),
            backgroundColor: AppColorsDark.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showSongOptions(BuildContext context, FavoriteSong song, AppLocalizations l10n) {
    SongOptionsBottomSheet.show(
      context: context,
      song: SongOptionsData(
        videoId: song.videoId,
        title: song.title,
        artist: song.artist,
        thumbnail: song.thumbnail,
        durationSeconds: song.duration ?? 0,
        isFavorite: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        return _LibraryPresentationalView(
          state: state,
          searchQuery: _searchQuery,
          searchController: _searchController,
          scrollController: _scrollController,
          onRefresh: () async => context.read<LibraryCubit>().loadLibrary(),
          onRetry: () => context.read<LibraryCubit>().loadLibrary(),
          onSearchChanged: _onSearchChanged,
          onCreatePlaylist: () => _showCreatePlaylistDialog(context),
          onShowOptions: (song, l10n) => _showSongOptions(context, song, l10n),
          onExplore: () => context.tabsRouter.setActiveIndex(0),
        );
      },
    );
  }
}

class _LibraryPresentationalView extends StatelessWidget {
  final LibraryState state;
  final String searchQuery;
  final TextEditingController searchController;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final Function(String) onSearchChanged;
  final VoidCallback onCreatePlaylist;
  final Function(FavoriteSong, AppLocalizations) onShowOptions;
  final VoidCallback onExplore;

  const _LibraryPresentationalView({
    required this.state,
    required this.searchQuery,
    required this.searchController,
    required this.scrollController,
    required this.onRefresh,
    required this.onRetry,
    required this.onSearchChanged,
    required this.onCreatePlaylist,
    required this.onShowOptions,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsDark.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColorsDark.onSurface,
          backgroundColor: AppColorsDark.surfaceDim54,
          onRefresh: onRefresh,
          child: CustomScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              LibraryHeader(
                searchController: searchController,
                onSearchChanged: onSearchChanged,
                onCreatePlaylist: onCreatePlaylist,
              ),
              if (state.status == LibraryStatus.loading)
                const SliverFillRemaining(child: LibraryLoadingView())
              else if (state.status == LibraryStatus.failure)
                SliverFillRemaining(
                  child: LibraryErrorView(
                    errorMessage: state.errorMessage,
                    onRetry: onRetry,
                  ),
                )
              else ...[
                QuickAccessSection(
                  totalSongs: state.totalSongs,
                  totalPlaylists: state.totalPlaylists,
                  totalGenres: state.totalGenres,
                ),
                if (state.favoritePlaylists.isNotEmpty || state.favoriteSongs.isNotEmpty)
                  LibraryFilteredContent(
                    searchQuery: searchQuery,
                    allPlaylists: state.allPlaylists,
                    favoriteSongs: state.favoriteSongs,
                    onShowOptions: onShowOptions,
                  ),
                if (state.isEmpty && state.status == LibraryStatus.success)
                  SliverFillRemaining(
                    child: LibraryEmptyState(
                      message: 'Your library is empty',
                      onExplore: onExplore,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
