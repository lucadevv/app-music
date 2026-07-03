import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:music_app/core/app_router/app_routes.gr.dart';
import 'package:music_app/core/presentation/widgets/molecules/shared_media_card.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';
import 'package:music_app/features/mood_genre/domain/use_cases/get_mood_playlists_use_case.dart';

import 'cubit/mood_genre_cubit.dart';
import 'widgets/mood_genre_error_widget.dart';
import 'widgets/mood_genre_listeners.dart';
import 'widgets/mood_genre_loading_widget.dart';

@RoutePage()
class MoodGenreScreen extends StatefulWidget implements AutoRouteWrapper {
  final String params;

  const MoodGenreScreen({required this.params, super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider<MoodGenreCubit>(
      create: (_) => MoodGenreCubit(GetIt.I<GetMoodPlaylistsUseCase>()),
      child: this,
    );
  }

  @override
  State<MoodGenreScreen> createState() => _MoodGenreScreenState();
}

class _MoodGenreScreenState extends State<MoodGenreScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar playlists al iniciar
    context.read<MoodGenreCubit>().loadMoodPlaylists(widget.params);
  }

  @override
  Widget build(BuildContext context) {
    return MoodGenreListeners(
      child: Scaffold(
        body: BlocBuilder<MoodGenreCubit, MoodGenreState>(
          builder: (context, state) {
            // Obtener thumbnail para el fondo (de la primera playlist)
            String? backgroundImageUrl;
            if (state.response != null &&
                state.response!.playlists.isNotEmpty) {
              final firstPlaylist = state.response!.playlists.first;
              if (firstPlaylist.thumbnail != null &&
                  firstPlaylist.thumbnail!.isNotEmpty &&
                  firstPlaylist.thumbnail!.first.isValidImageUrl) {
                backgroundImageUrl = firstPlaylist.thumbnail!.first;
              }
            }

            return Stack(
              children: [
                // Fondo difuminado
                if (backgroundImageUrl != null)
                  Positioned.fill(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(
                              backgroundImageUrl,
                            ),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              AppColorsDark.surfaceDim.withValues(alpha: 0.7),
                              BlendMode.darken,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Positioned.fill(
                    child: Container(color: const Color(0xFF0D0D0D)),
                  ),

                // Contenido principal
                SafeArea(child: _buildContent(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MoodGenreState state) {
    // Mostrar loading cuando está cargando o en estado inicial
    if (state.status == MoodGenreStatus.loading ||
        state.status == MoodGenreStatus.initial) {
      return const MoodGenreLoadingWidget();
    }

    // Mostrar error si falló
    if (state.status == MoodGenreStatus.failure) {
      return MoodGenreErrorWidget(
        errorMessage: state.errorMessage,
        params: widget.params,
      );
    }

    // Mostrar contenido si fue exitoso
    final response = state.response;
    if (response == null) {
      return const SizedBox.shrink();
    }

    return CustomScrollView(
      slivers: [
        // Header con título del género
        SliverAppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColorsDark.onSurface,
            ),
            onPressed: () => context.router.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              response.genreName,
              style: const TextStyle(
                color: AppColorsDark.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
          ),
        ),

        // Lista de playlists
        if (response.playlists.isEmpty)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No hay playlists disponibles',
                  style: TextStyle(color: AppColorsDark.onSurface),
                ),
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text(
                'Playlists de la comunidad',
                style: TextStyle(
                  color: AppColorsDark.onSurface.withValues(alpha: 0.8),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        // Grid de playlists
        if (response.playlists.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final playlist = response.playlists[index];
                return SharedMediaCard(
                  title: playlist.title,
                  subtitle: playlist.description,
                  subtitle2:
                      playlist.videoCount != null &&
                          playlist.videoCount!.isNotEmpty
                      ? '${playlist.videoCount} videos'
                      : null,
                  imageUrl:
                      playlist.thumbnail != null &&
                          playlist.thumbnail!.isNotEmpty
                      ? playlist.thumbnail!.last
                      : null,
                  placeholderIcon: Icons.playlist_play,
                  onTap: () {
                    if (playlist.hasValidPlaylistId) {
                      context.router.push(
                        PlaylistRoute(id: playlist.playlistId),
                      );
                    }
                  },
                  width: double.infinity,
                );
              }, childCount: response.playlists.length),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}
