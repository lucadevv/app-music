/// Interfaz base para cualquier entidad de audio que pueda ser reproducida por el motor.
///
/// Principio: Interface Segregation (SOLID)
/// Cualquier feature (Search, Library, Downloads) que tenga entidades reproducibles 
/// debe implementar este contrato orgánico en lugar de depender de una God Class.
abstract interface class PlayableAudio {
  /// Identificador único de la pista (ej. YouTube videoId)
  String get id;

  /// Título de la obra
  String get title;

  /// Artista(s) principal(es) de la obra
  String get artist;

  /// URL de streaming remoto (opcional si es offline)
  String? get streamUrl;

  /// Duración total de la pista
  Duration get audioDuration;

  /// URL o path local de la mejor miniatura (thumbnail) disponible
  String? get bestThumbnail;

  /// Devuelve true si la pista contiene metadata completa y está lista para sonar
  bool get canPlay;
}
