import 'package:equatable/equatable.dart';
import 'package:music_app/core/domain/entities/playable_audio.dart';

/// Entidad de dominio unificada para un álbum.
///
/// Esta es la entidad canónica que debe usarse en toda la app.
class Album extends Equatable {
  /// ID único del álbum
  final String id;

  /// Título del álbum
  final String title;

  /// URL de la miniatura
  final String? thumbnail;

  /// URL de la miniatura de alta calidad
  final String? highThumbnail;

  /// Lista de miniaturas en diferentes tamaños
  final List<AlbumThumbnail> thumbnails;

  /// Nombre del artista principal
  final String? artistName;

  /// ID del artista principal
  final String? artistId;

  /// Lista de artistas
  final List<AlbumArtist> artists;

  /// Año de lanzamiento
  final int year;

  /// Género musical
  final String? genre;

  /// Canciones del álbum
  final List<AlbumSong> songs;

  /// Tipo de lanzamiento (album, single, ep)
  final String? type;

  /// Número de Likes
  final int? likeCount;

  /// Descripción
  final String? description;

  const Album({
    required this.id,
    required this.title,
    this.thumbnail,
    this.highThumbnail,
    this.thumbnails = const [],
    this.artistName,
    this.artistId,
    this.artists = const [],
    this.year = 2024,
    this.genre,
    this.songs = const [],
    this.type,
    this.likeCount,
    this.description,
  });

  /// Obtiene la mejor URL de thumbnail disponible
  String? get bestThumbnail =>
      highThumbnail ??
      thumbnail ??
      (thumbnails.isNotEmpty ? thumbnails.last.url : null);

  /// Número de canciones
  int get songCount => songs.isNotEmpty ? songs.length : 0;

  /// Duración total en segundos
  int get totalDurationSeconds =>
      songs.fold(0, (sum, song) => sum + song.durationSeconds);

  /// Duración total formateada
  String get formattedDuration {
    final totalMinutes = totalDurationSeconds ~/ 60;
    return '$totalMinutes min';
  }

  /// Crea una copia con campos modificados
  Album copyWith({
    String? id,
    String? title,
    String? thumbnail,
    String? highThumbnail,
    List<AlbumThumbnail>? thumbnails,
    String? artistName,
    String? artistId,
    List<AlbumArtist>? artists,
    int? year,
    String? genre,
    List<AlbumSong>? songs,
    String? type,
    int? likeCount,
    String? description,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      thumbnail: thumbnail ?? this.thumbnail,
      highThumbnail: highThumbnail ?? this.highThumbnail,
      thumbnails: thumbnails ?? this.thumbnails,
      artistName: artistName ?? this.artistName,
      artistId: artistId ?? this.artistId,
      artists: artists ?? this.artists,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      songs: songs ?? this.songs,
      type: type ?? this.type,
      likeCount: likeCount ?? this.likeCount,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    thumbnail,
    highThumbnail,
    thumbnails,
    artistName,
    artistId,
    artists,
    year,
    genre,
    songs,
    type,
    likeCount,
    description,
  ];
}

/// Miniatura de álbum en diferentes tamaños
class AlbumThumbnail extends Equatable {
  final String url;
  final int width;
  final int height;

  const AlbumThumbnail({
    required this.url,
    required this.width,
    required this.height,
  });

  @override
  List<Object?> get props => [url, width, height];
}

/// Artista de un álbum
class AlbumArtist extends Equatable {
  final String id;
  final String name;

  const AlbumArtist({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

/// Canción de un álbum
class AlbumSong extends Equatable implements PlayableAudio {
  final String videoId;
  @override
  final String title;
  final String? thumbnail;
  final int durationSeconds;
  final int trackNumber;
  final String? artistName;
  final List<AlbumArtist> artists;

  const AlbumSong({
    required this.videoId,
    required this.title,
    required this.durationSeconds,
    required this.trackNumber,
    this.thumbnail,
    this.artistName,
    this.artists = const [],
  });

  /// Duración formateada
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String get id => videoId;

  @override
  String get artist => artistName ?? (artists.isNotEmpty ? artists.first.name : 'Unknown Artist');

  @override
  String? get streamUrl => null;

  @override
  Duration get audioDuration => Duration(seconds: durationSeconds);

  @override
  String? get bestThumbnail => thumbnail;

  @override
  bool get canPlay => true;

  @override
  List<Object?> get props => [
    videoId,
    title,
    thumbnail,
    durationSeconds,
    trackNumber,
    artistName,
    artists,
  ];
}
