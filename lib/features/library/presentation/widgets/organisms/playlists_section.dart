import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:music_app/core/app_router/app_routes.gr.dart';
import 'package:music_app/core/presentation/widgets/molecules/shared_media_card.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/features/library/presentation/cubit/library_cubit.dart';
import 'package:music_app/l10n/app_localizations.dart';

/// Sección de playlists en la biblioteca.
class PlaylistsSection extends StatelessWidget {
  final List<PlaylistItem> playlists;
  final int totalPlaylists;
  final bool showViewAll;
  final bool useSliver;

  const PlaylistsSection({
    required this.playlists,
    required this.totalPlaylists,
    this.showViewAll = true,
    this.useSliver = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.playlists,
                style: const TextStyle(
                  color: AppColorsDark.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              if (showViewAll && totalPlaylists > 5)
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SharedMediaCard(
                  title: playlist.name,
                  subtitle: playlist.songCount > 0
                      ? '${playlist.songCount} songs'
                      : null,
                  imageUrl: playlist.thumbnail,
                  placeholderIcon: Icons.playlist_play,
                  onTap: () {
                    if (playlist.isUserCreated) {
                      context.router.push(
                        UserPlaylistDetailRoute(playlistId: playlist.id),
                      );
                    } else if (playlist.externalPlaylistId != null) {
                      context.router.push(
                        PlaylistRoute(id: playlist.externalPlaylistId!),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );

    if (useSliver) {
      return SliverToBoxAdapter(child: content);
    }
    return content;
  }
}
