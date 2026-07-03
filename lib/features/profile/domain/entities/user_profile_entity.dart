import 'package:equatable/equatable.dart';

/// Entity representing a user profile in the domain layer.
class UserProfileEntity extends Equatable {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? avatar;
  final String provider;
  final String role;
  final bool isEmailVerified;
  final DateTime? createdAt;

  const UserProfileEntity({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.avatar,
    this.provider = 'email',
    this.role = 'user',
    this.isEmailVerified = false,
    this.createdAt,
  });

  String get displayName {
    if (firstName != null && firstName!.isNotEmpty) {
      if (lastName != null && lastName!.isNotEmpty) {
        return '$firstName $lastName';
      }
      return firstName!;
    }
    // Fallback al email
    return email
        .split('@')[0]
        .split('.')
        .map(
          (part) => part.isEmpty
              ? ''
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String get initials {
    if (firstName != null && firstName!.isNotEmpty) {
      if (lastName != null && lastName!.isNotEmpty) {
        return '${firstName![0]}${lastName![0]}'.toUpperCase();
      }
      return firstName![0].toUpperCase();
    }
    // Fallback al email
    final parts = email.split('@')[0].split('.');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return email[0].toUpperCase();
  }

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Verifica si el usuario tiene una imagen de perfil configurada
  bool get hasAvatar => avatar != null && avatar!.trim().isNotEmpty;

  /// Indica si tiene rol estándar ('user')
  bool get isStandardUser => role.toLowerCase() == 'user';

  /// Confirma si el nombre completo del usuario fue provisto
  bool get hasFullName => firstName != null && firstName!.trim().isNotEmpty && lastName != null && lastName!.trim().isNotEmpty;

  UserProfileEntity copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? avatar,
    String? provider,
    String? role,
    bool? isEmailVerified,
    DateTime? createdAt,
  }) {
    return UserProfileEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatar: avatar ?? this.avatar,
      provider: provider ?? this.provider,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    firstName,
    lastName,
    avatar,
    provider,
    role,
    isEmailVerified,
    createdAt,
  ];
}
