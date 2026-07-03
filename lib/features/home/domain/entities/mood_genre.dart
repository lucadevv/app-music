/// Entidad para categorías de moods y géneros
///
/// La API retorna 'title' - se mantiene esa estructura
///
/// SOLID: Single Responsibility Principle (SRP)
/// Responsable única: Representar un mood o género
class MoodGenre {
  final String title;
  final String params;

  const MoodGenre({required this.title, required this.params});

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Verifica si tiene parámetros de navegación válidos para que la UI los use
  bool get hasValidParams => params.trim().isNotEmpty;
}
