import 'package:flutter/foundation.dart';

import '../../domain/entities/home_response.dart';
import 'chart_playlist_model.dart';
import 'home_section_model.dart';
import 'mood_genre_model.dart';

/// Modelo para HomeResponse
///
/// Actualizado según nueva estructura de API:
/// - moods: Array de moods
/// - genres: Array de géneros
/// - charts: Objeto con top_songs y trending (cada uno con stream_url y thumbnail)
/// - sections: Array opcional de secciones de contenido
class HomeResponseModel extends HomeResponse {
  HomeResponseModel({
    required super.moods,
    required super.genres,
    required super.charts,
    super.sections,
  });

  factory HomeResponseModel.fromJson(Map<String, dynamic> json) {
    // La API retorna 'moods_genres' como array combinado
    final dynamic moodsGenresListRaw = json['moods_genres'] ?? [];
    final moodsGenresList = moodsGenresListRaw is List
        ? moodsGenresListRaw
        : [];

    // Parse models cleanly without traditional loops, dropping invalid items
    final parsedMoodsGenres = moodsGenresList
        .whereType<Map<String, dynamic>>()
        .map((item) {
          try {
            return MoodGenreModel.fromJson(item);
          } catch (_) {
            return null; // Ignore errors, resilience
          }
        })
        .where(
          (model) => model != null && model.params.isNotEmpty,
        ) // Drop empty params
        .cast<MoodGenreModel>()
        .toList();

    // Separar moods (primeros 12 aproximado) y genres
    final extractMoods = parsedMoodsGenres.take(12).toList();
    final extractGenres = parsedMoodsGenres.skip(12).toList();

    // Parsear charts
    final chartsData = json['charts'] as Map<String, dynamic>? ?? {};
    final topSongsData = chartsData['top_songs'] as List<dynamic>? ?? [];
    final trendingData = chartsData['trending'] as List<dynamic>? ?? [];

    final topSongs = topSongsData
        .whereType<Map<String, dynamic>>()
        .map((item) {
          try {
            return ChartPlaylistModel.fromJson(item);
          } catch (_) {
            return null;
          }
        })
        .whereType<ChartPlaylistModel>()
        .toList();

    final trending = trendingData
        .whereType<Map<String, dynamic>>()
        .map((item) {
          try {
            return ChartPlaylistModel.fromJson(item);
          } catch (_) {
            return null;
          }
        })
        .whereType<ChartPlaylistModel>()
        .toList();

    // Sections
    final dynamic sectionsListRaw = json['home'] ?? [];
    final sectionsList = sectionsListRaw is List ? sectionsListRaw : [];

    final sections = sectionsList
        .whereType<Map<String, dynamic>>()
        .map((item) {
          try {
            return HomeSectionModel.fromJson(item);
          } catch (_) {
            return null;
          }
        })
        .whereType<HomeSectionModel>()
        .toList();

    if (kDebugMode) {
      debugPrint(
        'HomeResponseModel: Parseado - moods: ${extractMoods.length}, genres: ${extractGenres.length}, sections: ${sections.length}',
      );
    }

    return HomeResponseModel(
      moods: extractMoods,
      genres: extractGenres,
      charts: Charts(topSongs: topSongs, trending: trending),
      sections: sections,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moods_genres': [
        ...moods,
        ...genres,
      ].map((e) => (e as MoodGenreModel).toJson()).toList(),
      'charts': {
        'top_songs': charts.topSongs
            .map((e) => (e as ChartPlaylistModel).toJson())
            .toList(),
        'trending': charts.trending
            .map((e) => (e as ChartPlaylistModel).toJson())
            .toList(),
      },
      'home': sections.map((e) => (e as HomeSectionModel).toJson()).toList(),
    };
  }
}
