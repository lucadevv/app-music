import 'package:equatable/equatable.dart';

/// Entity representing a user playlist.
class UserPlaylistEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? thumbnail;
  final int trackCount;
  final bool isOwner;

  const UserPlaylistEntity({
    required this.id,
    required this.name,
    this.description,
    this.thumbnail,
    this.trackCount = 0,
    this.isOwner = true,
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Verifica si la lista cuenta con descripción personalizada
  bool get hasDescription => description != null && description!.trim().isNotEmpty;

  /// Verifica si la lista tiene miniatura asignada
  bool get hasThumbnail => thumbnail != null && thumbnail!.trim().isNotEmpty;

  /// Indica si la lista de reproducción propia no posee canciones
  bool get isEmpty => trackCount == 0;

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    thumbnail,
    trackCount,
    isOwner,
  ];
}
