class MoodPlaylist {
  final String playlistId;
  final String title;
  final String? description;
  final List<String>? thumbnail;
  final String? videoCount;

  const MoodPlaylist({
    required this.playlistId,
    required this.title,
    this.description,
    this.thumbnail,
    this.videoCount,
  });

  bool get hasValidPlaylistId => playlistId.trim().isNotEmpty;

  String? get bestThumbnail =>
      thumbnail != null && thumbnail!.isNotEmpty ? thumbnail!.last : null;
}
