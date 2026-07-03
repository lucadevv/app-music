import 'package:equatable/equatable.dart';

/// Entity representing a relax/mood playlist.
class RelaxPlaylistEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? thumbnail;
  final String category; // e.g., "morning", "evening", "focus", "sleep"

  const RelaxPlaylistEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.thumbnail,
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Verifica si la categoría es válida para el enrutamiento visual
  bool get hasValidCategory => category.trim().isNotEmpty;

  /// Indica si tiene un cover configurado
  bool get hasThumbnail => thumbnail != null && thumbnail!.trim().isNotEmpty;

  @override
  List<Object?> get props => [id, title, description, thumbnail, category];
}
