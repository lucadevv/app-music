import 'playable_audio.dart';

/// Interfaz para entidades de audio que han sido persistidas localmente.
///
/// Principio: Liskov Substitution (SOLID)
/// Al extender [PlayableAudio], cualquier clase que implemente [OfflineAudio]
/// también es un [PlayableAudio] válido para el motor de reproducción, 
/// pero añade las capacidades estrictas de almacenamiento local.
abstract interface class OfflineAudio implements PlayableAudio {
  /// Ruta absoluta del archivo en el sistema de archivos local
  String get localPath;

  /// Tamaño en bytes del archivo de audio
  int get fileSize;

  /// Devuelve true si el archivo existe y es accesible
  bool get isDownloaded;
}
