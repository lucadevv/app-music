import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/offline_audio.dart';

/// Entity representing an offline song.
class OfflineSongEntity extends Equatable implements OfflineAudio {
  // --------- OfflineAudio / PlayableAudio Mappers ---------
  @override
  String get id => videoId;

  @override
  Duration get audioDuration => Duration(seconds: duration ?? 0);

  @override
  String? get streamUrl => null;

  @override
  String? get bestThumbnail => thumbnail;

  @override
  bool get canPlay => localPath.isNotEmpty;
  
  @override
  int get fileSize => 0; // Fallback for legacy offline entity

  @override
  bool get isDownloaded => localPath.isNotEmpty;

  @override
  final String title;
  
  @override
  final String artist;
  
  @override
  String get localPath => _localPath ?? '';
  // --------------------------------------------------------

  final String videoId;
  final String? thumbnail;
  final String? _localPath;
  final int? duration;
  final DateTime? downloadedAt;

  const OfflineSongEntity({
    required this.videoId,
    required this.title,
    required this.artist,
    this.thumbnail,
    String? localPath,
    this.duration,
    this.downloadedAt,
  }) : _localPath = localPath;

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Indica si la canción fuera de línea tiene su carátula en caché
  bool get hasValidThumbnail => thumbnail != null && thumbnail!.trim().isNotEmpty;

  /// Indica si la duración del archivo de audio es conocida y válida
  bool get isDurationKnown => duration != null && duration! > 0;

  /// Determina si la canción fue bajada recientemente para destacar en UI
  bool isRecentlyDownloaded([Duration threshold = const Duration(days: 3)]) {
    if (downloadedAt == null) return false;
    return DateTime.now().difference(downloadedAt!) <= threshold;
  }

  @override
  List<Object?> get props => [
    videoId,
    title,
    artist,
    thumbnail,
    _localPath,
    duration,
    downloadedAt,
  ];
}
