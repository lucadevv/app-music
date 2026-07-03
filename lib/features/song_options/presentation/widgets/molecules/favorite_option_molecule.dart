import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/features/favorites/presentation/cubit/favorite_cubit.dart';
import 'package:music_app/features/library/data/models/library_models.dart';
import 'package:music_app/features/library/domain/entities/favorite_type.dart';
import 'package:music_app/features/song_options/presentation/widgets/atoms/option_tile_atom.dart';

/// Molecule: Favorite option tile with toggle logic
class FavoriteOptionMolecule extends StatelessWidget {
  final String videoId;
  final String title;
  final String artist;
  final String? thumbnail;
  final int? duration;
  final String? streamUrl;
  final bool isFavorite;

  const FavoriteOptionMolecule({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.isFavorite,
    super.key,
    this.thumbnail,
    this.duration,
    this.streamUrl,
  });

  @override
  Widget build(BuildContext context) {
    final label = isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos';
    return OptionTileAtom(
      icon: isFavorite ? Icons.heart_broken : Icons.favorite_border,
      label: label,
      onTap: () {
        context.router.maybePop();
        context.read<FavoriteCubit>().toggleFavorite(
          videoId: videoId,
          type: FavoriteType.song,
          isCurrentlyFavorite: isFavorite,
          metadata: SongMetadata(
            title: title,
            artist: artist,
            thumbnail: thumbnail,
            duration: duration,
            streamUrl: streamUrl,
          ),
        );
      },
    );
  }
}
