import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/offline_audio.dart';

/// Entidad que representa una canción descargada
///
/// SOLID: Single Responsibility Principle (SRP)
/// Responsable única: Representar los datos de una canción descargada
class DownloadedSong extends Equatable implements OfflineAudio {
  // --------- OfflineAudio / PlayableAudio Mappers ---------
  @override
  String get id => videoId;

  @override
  Duration get audioDuration => duration;

  @override
  String? get streamUrl => null; // Offline songs strictly use localPath

  @override
  String? get bestThumbnail => thumbnail;

  @override
  bool get canPlay => localPath.isNotEmpty;

  @override
  bool get isDownloaded => localPath.isNotEmpty;

  @override
  final String title;

  @override
  final String artist;

  @override
  final String localPath;

  @override
  final int fileSize;
  // --------------------------------------------------------

  final String videoId;
  final String? album;
  final String? thumbnail;
  final Duration duration;
  final DateTime downloadedAt;

  const DownloadedSong({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.localPath,
    required this.fileSize,
    required this.duration,
    required this.downloadedAt,
    this.album,
    this.thumbnail,
  });

  /// Tamaño formateado en MB
  String get fileSizeFormatted {
    final mb = fileSize / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Duración formateada
  String get durationFormatted {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Indica si el archivo pertenece a un álbum legítimo
  bool get hasAlbum => album != null && album!.trim().isNotEmpty && album!.toLowerCase() != 'unknown';

  /// Verifica si la canción supera el umbral arbitrario de "Archivo Pesado" (ej: >50MB) 
  bool get isLargeFile => fileSize > 50 * 1024 * 1024;

  /// Determina si fue recién descargada en la ventana de tiempo dada
  bool isRecentlyDownloaded([Duration threshold = const Duration(days: 3)]) {
    return DateTime.now().difference(downloadedAt) <= threshold;
  }

  @override
  List<Object?> get props => [
    videoId,
    title,
    artist,
    album,
    thumbnail,
    localPath,
    fileSize,
    duration,
    downloadedAt,
  ];
}
