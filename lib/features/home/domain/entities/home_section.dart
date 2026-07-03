import 'home_content_item.dart';

/// Entidad para secciones del home
class HomeSection {
  final String title;
  final List<HomeContentItem> contents;

  const HomeSection({required this.title, required this.contents});

  HomeSection copyWith({String? title, List<HomeContentItem>? contents}) {
    return HomeSection(
      title: title ?? this.title,
      contents: contents ?? this.contents,
    );
  }

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Indica si el título de la sección se renderizará limpiamente
  bool get hasValidTitle => title.trim().isNotEmpty && title.toLowerCase() != 'unknown';

  /// Garantiza que la sección contenga elementos curados
  bool get hasContents => contents.isNotEmpty;
}
