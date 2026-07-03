import 'package:flutter/material.dart';
import 'package:music_app/core/presentation/widgets/song_list_item.dart';
import 'package:music_app/features/player/domain/entities/now_playing_data.dart';

import '../atoms/queue_item_trailing.dart';

/// Molecule: Individual queue item with trailing actions
class QueueItem extends StatelessWidget {
  final NowPlayingData track;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const QueueItem({
    required this.track,
    required this.onTap,
    required this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SharedSongListTile.fromPlayable(
      playable: track,
      trailing: QueueItemTrailing(
        duration: track.formattedDuration,
        onRemove: onRemove,
      ),
      onTap: onTap,
    );
  }
}
