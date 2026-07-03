import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:music_app/core/app_router/app_routes.gr.dart';
import 'package:music_app/core/presentation/widgets/molecules/shared_media_card.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/features/library/domain/repositories/library_repository.dart';
import 'package:music_app/features/library/domain/use_cases/create_user_playlist_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/get_favorite_playlists_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/get_user_playlists_use_case.dart';
import 'package:music_app/features/user_playlists/presentation/cubit/user_playlists_cubit.dart';
import 'package:music_app/features/user_playlists/presentation/cubit/user_playlists_state.dart';
import 'package:music_app/features/user_playlists/presentation/widgets/molecules/user_playlists_empty_molecule.dart';
import 'package:music_app/features/user_playlists/presentation/widgets/organisms/create_playlist_dialog_organism.dart';
import 'package:music_app/features/user_playlists/presentation/widgets/organisms/user_playlists_loading_organism.dart';
import 'package:music_app/l10n/app_localizations.dart';

@RoutePage()
class UserPlaylistsScreen extends StatelessWidget {
  const UserPlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryRepository = GetIt.I<LibraryRepository>();
    return BlocProvider(
      create: (context) => UserPlaylistsCubit(
        getUserPlaylistsUseCase: GetUserPlaylistsUseCase(libraryRepository),
        getFavoritePlaylistsUseCase: GetFavoritePlaylistsUseCase(
          libraryRepository,
        ),
        createUserPlaylistUseCase: CreateUserPlaylistUseCase(libraryRepository),
      )..loadAllPlaylists(),
      child: const _UserPlaylistsView(),
    );
  }
}

class _UserPlaylistsView extends StatelessWidget {
  const _UserPlaylistsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.myPlaylists,
          style: const TextStyle(
            color: AppColorsDark.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColorsDark.onSurface,
          ),
          onPressed: () => context.router.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColorsDark.onSurface),
            onPressed: () => _createPlaylist(context, l10n),
          ),
        ],
      ),
      body: BlocBuilder<UserPlaylistsCubit, UserPlaylistsState>(
        builder: (context, state) {
          return _buildBody(context, state, l10n);
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    UserPlaylistsState state,
    AppLocalizations l10n,
  ) {
    switch (state.status) {
      case UserPlaylistsStatus.initial:
      case UserPlaylistsStatus.loading:
        return const UserPlaylistsLoadingOrganism();
      case UserPlaylistsStatus.failure:
        return _buildErrorState(context, state, l10n);
      case UserPlaylistsStatus.success:
        if (state.playlists.isEmpty) {
          return const UserPlaylistsEmptyMolecule();
        }
        return _buildPlaylistGrid(context, state.playlists);
    }
  }

  Widget _buildErrorState(
    BuildContext context,
    UserPlaylistsState state,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            state.errorMessage ?? l10n.errorUnknown,
            style: const TextStyle(color: AppColorsDark.onSurface),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<UserPlaylistsCubit>().loadAllPlaylists();
            },
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistGrid(
    BuildContext context,
    List<PlaylistItem> playlists,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return SharedMediaCard(
          title: playlist.name,
          subtitle: '${playlist.songCount} songs',
          imageUrl: playlist.thumbnail,
          placeholderIcon: Icons.playlist_play,
          onTap: () {
            if (playlist.type == PlaylistType.user) {
              context.router.push(
                UserPlaylistDetailRoute(playlistId: playlist.id),
              );
            } else {
              context.router.push(
                PlaylistRoute(id: playlist.externalId ?? playlist.id),
              );
            }
          },
          width: double.infinity,
        );
      },
    );
  }

  Future<void> _createPlaylist(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final result = await CreatePlaylistDialogOrganism.show(context);

    if (result != null && result.isNotEmpty && context.mounted) {
      await context.read<UserPlaylistsCubit>().createPlaylist(result);
    }
  }
}
