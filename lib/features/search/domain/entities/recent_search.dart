// ignore_for_file: deprecated_member_use_from_same_package
import 'package:music_app/core/domain/entities/song.dart';

/// Entidad del dominio para una búsqueda reciente
class RecentSearch {
  final String id;
  final String query;
  final String videoId;
  final Song songData;
  final DateTime createdAt;
  final DateTime lastSearchedAt;

  const RecentSearch({
    required this.id,
    required this.query,
    required this.videoId,
    required this.songData,
    required this.createdAt,
    required this.lastSearchedAt,
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Determina si la búsqueda fue realizada recientemente según un umbral
  bool isRecent([Duration threshold = const Duration(days: 7)]) {
    return DateTime.now().difference(lastSearchedAt) <= threshold;
  }

  /// Indica si la búsqueda es muy antigua (creada hace más de 30 días)
  bool get isVeryOld => DateTime.now().difference(createdAt).inDays > 30;

  /// Indica si la búsqueda está ligada a un video directamente
  bool get hasDirectVideo => videoId. trim().isNotEmpty;
}
