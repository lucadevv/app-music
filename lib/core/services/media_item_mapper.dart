import 'package:audio_service/audio_service.dart';
import '../../features/player/domain/entities/now_playing_data.dart';

/// Mapper de infraestructura para transformar entidades puras de dominio
/// a entidades del sistema operativo (audio_service / notificaciones).
///
/// Principio: Soluciona la fuga de abstracción que ocurría cuando 
/// la entidad puramente de negocio [NowPlayingData] importaba librerías de hardware.
class MediaItemMapper {
  /// Convierte NowPlayingData a MediaItem para notificaciones y lock screen.
  static MediaItem fromNowPlayingData(NowPlayingData data) {
    return MediaItem(
      id: data.videoId,
      album: data.album.name,
      title: data.title,
      artist: data.artistsNames,
      duration: data.durationSeconds > 0 ? Duration(seconds: data.durationSeconds) : null,
      artUri: Uri.tryParse(data.highResThumbnail.url),
      extras: {'videoId': data.videoId, 'streamUrl': data.streamUrl},
    );
  }
}
