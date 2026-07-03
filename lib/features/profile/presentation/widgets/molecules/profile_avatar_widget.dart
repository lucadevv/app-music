// ignore_for_file: unnecessary_underscores
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';

/// Molécula que muestra la imagen de perfil del usuario o sus iniciales si no tiene foto.
class ProfileAvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String initials;

  const ProfileAvatarWidget({
    required this.avatarUrl,
    required this.initials,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isValidImageUrl) {
      return _buildNetworkImage();
    }
    return _buildInitialsAvatar();
  }

  Widget _buildNetworkImage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColorsDark.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildInitialsAvatar(),
          errorWidget: (_, __, ___) => _buildInitialsAvatar(),
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColorsDark.primary,
            AppColorsDark.primary.withValues(alpha: 0.7),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColorsDark.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColorsDark.onSurface,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
