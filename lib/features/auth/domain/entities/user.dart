import 'package:equatable/equatable.dart';

/// Entidad pura de dominio para el Usuario.
/// No debe contener lógica de serialización ni dependencias de frameworks externos.
class User extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final bool isEmailVerified;
  final String? avatar;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isEmailVerified,
    this.avatar,
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---
  
  /// Obtiene el nombre completo formateado
  String get fullName => '$firstName $lastName'.trim();

  /// Verifica si el usuario tiene privilegios administrativos
  bool get isAdmin => role.toLowerCase() == 'admin';

  /// Verifica si el usuario posee suscripción premium (o es admin)
  bool get isPremium => role.toLowerCase() == 'premium' || isAdmin;

  /// Verifica si el usuario tiene una foto de perfil asignada
  bool get hasAvatar => avatar != null && avatar!.trim().isNotEmpty;

  /// Genera las iniciales del usuario (ej: "Juan Doe" -> "JD")
  String get initials {
    final String firstInit = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final String lastInit = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInit$lastInit'.trim().isEmpty ? 'U' : '$firstInit$lastInit';
  }

  @override
  List<Object?> get props => [
    id,
    email,
    firstName,
    lastName,
    role,
    isEmailVerified,
    avatar,
  ];
}
