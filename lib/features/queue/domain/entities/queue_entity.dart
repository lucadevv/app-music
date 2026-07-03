import 'package:equatable/equatable.dart';

/// Entity representing a queue item.
class QueueItemEntity extends Equatable {
  final String videoId;
  final String title;
  final String artist;
  final String? thumbnail;
  final int? duration;

  const QueueItemEntity({
    required this.videoId,
    required this.title,
    required this.artist,
    this.thumbnail,
    this.duration,
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---
  
  /// Indica si el ítem de la cola tiene información válida de artista
  bool get hasArtist => artist.trim().isNotEmpty && artist.toLowerCase() != 'unknown artist';
  
  /// Indica si el ítem posee una miniatura de carátula válida
  bool get hasValidThumbnail => thumbnail != null && thumbnail!.trim().isNotEmpty;

  @override
  List<Object?> get props => [videoId, title, artist, thumbnail, duration];
}

/// Entity representing the current queue state.
class QueueEntity extends Equatable {
  final QueueItemEntity? currentSong;
  final List<QueueItemEntity> upNext;
  final List<QueueItemEntity> history;

  const QueueEntity({
    this.currentSong,
    this.upNext = const [],
    this.history = const [],
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Indica si la cola de reproducción está vacía por completo
  bool get isEmpty => currentSong == null && upNext.isEmpty;

  /// Indica si hay canciones siguientes cargadas en la cola
  bool get hasNext => upNext.isNotEmpty;

  /// Indica si hay historial de reproducción previo
  bool get hasHistory => history.isNotEmpty;

  /// Calcula el total de elementos cargados actualmente en memoria
  int get totalItems => (currentSong != null ? 1 : 0) + upNext.length + history.length;

  QueueEntity copyWith({
    QueueItemEntity? currentSong,
    List<QueueItemEntity>? upNext,
    List<QueueItemEntity>? history,
  }) {
    return QueueEntity(
      currentSong: currentSong ?? this.currentSong,
      upNext: upNext ?? this.upNext,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props => [currentSong, upNext, history];
}
