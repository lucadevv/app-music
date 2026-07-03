import 'package:equatable/equatable.dart';

/// Entity representing onboarding state.
class OnboardingEntity extends Equatable {
  final bool isCompleted;
  final int currentPage;
  final List<OnboardingPageEntity> pages;

  const OnboardingEntity({
    this.isCompleted = false,
    this.currentPage = 0,
    this.pages = const [],
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Indica si el onboarding cuenta con contenido predeterminado
  bool get hasPages => pages.isNotEmpty;

  /// Verifica si el usuario actual se encuentra en la pantalla final del recorrido
  bool get isLastPage => pages.isNotEmpty && currentPage == pages.length - 1;

  OnboardingEntity copyWith({
    bool? isCompleted,
    int? currentPage,
    List<OnboardingPageEntity>? pages,
  }) {
    return OnboardingEntity(
      isCompleted: isCompleted ?? this.isCompleted,
      currentPage: currentPage ?? this.currentPage,
      pages: pages ?? this.pages,
    );
  }

  @override
  List<Object?> get props => [isCompleted, currentPage, pages];
}

/// Entity representing a single onboarding page.
class OnboardingPageEntity extends Equatable {
  final String title;
  final String description;
  final String? imageUrl;

  const OnboardingPageEntity({
    required this.title,
    required this.description,
    this.imageUrl,
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Verifica si la vista cuenta con un recurso visual válido (imagen / hero)
  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  @override
  List<Object?> get props => [title, description, imageUrl];
}
