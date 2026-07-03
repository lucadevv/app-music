import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';
import 'package:music_app/l10n/app_localizations.dart';

class UserPlaylistHeaderMolecule extends StatelessWidget {
  final String playlistName;
  final String? thumbnail;
  final Function(String) onEdit;
  final VoidCallback onDelete;

  const UserPlaylistHeaderMolecule({
    required this.playlistName,
    required this.onEdit,
    required this.onDelete,
    this.thumbnail,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: const Color(0xFF0D0D0D),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          playlistName,
          style: const TextStyle(color: AppColorsDark.onSurface),
        ),
        background: thumbnail != null && thumbnail.isValidImageUrl
            ? CachedNetworkImage(
                imageUrl: thumbnail!,
                fit: BoxFit.cover,
                color: AppColorsDark.surfaceDim54,
                colorBlendMode: BlendMode.darken,
              )
            : Container(
                color: AppColorsDark.surfaceContainerHighest,
                child: const Icon(
                  Icons.playlist_play,
                  size: 100,
                  color: AppColorsDark.onSurface24,
                ),
              ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit(value);
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, color: AppColorsDark.onSurface),
                  const SizedBox(width: 8),
                  Text(l10n.edit),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: AppColorsDark.error),
                  const SizedBox(width: 8),
                  Text(
                    l10n.delete,
                    style: const TextStyle(color: AppColorsDark.error),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
