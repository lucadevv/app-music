import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:music_app/core/app_router/app_routes.gr.dart';
import 'package:music_app/core/domain/entities/artist.dart';
import 'package:music_app/core/presentation/widgets/molecules/shared_media_card.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';

class ArtistAlbumsOrganism extends StatelessWidget {
  final List<ArtistAlbum> albums;
  final StackRouter router;

  const ArtistAlbumsOrganism({
    required this.albums,
    required this.router,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(),
          const SizedBox(height: 16),
          _buildAlbumsRow(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Text(
        'Albums',
        style: TextStyle(
          color: AppColorsDark.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAlbumsRow() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SharedMediaCard(
              title: album.title,
              subtitle: '${album.year} • ${album.songCount} songs',
              imageUrl: album.thumbnail,
              placeholderIcon: Icons.album,
              width: 140,
              imageHeight: 130,
              onTap: () => router.push(AlbumRoute(albumId: album.id)),
            ),
          );
        },
      ),
    );
  }
}
