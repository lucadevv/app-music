import 'package:equatable/equatable.dart';

/// Entity representing app initialization state.
class SplashEntity extends Equatable {
  final bool isOnboardingCompleted;
  final bool isAuthenticated;
  final bool isEmailVerified;
  final String? redirectRoute;

  const SplashEntity({
    this.isOnboardingCompleted = false,
    this.isAuthenticated = false,
    this.isEmailVerified = false,
    this.redirectRoute,
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Verifica si la configuración inicial demanda un redireccionamiento forzoso
  bool get hasRedirectRoute => redirectRoute != null && redirectRoute!.trim().isNotEmpty;

  @override
  List<Object?> get props => [
    isOnboardingCompleted,
    isAuthenticated,
    isEmailVerified,
    redirectRoute,
  ];
}
