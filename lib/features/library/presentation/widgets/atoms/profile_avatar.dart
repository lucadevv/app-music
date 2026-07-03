import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';

class ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String initials;

  const ProfileAvatar({required this.initials, super.key, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl.isValidImageUrl) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColorsDark.onSurface.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatarUrl!,
            fit: BoxFit.cover,
            placeholder: (_, _) => _buildInitials(40),
            errorWidget: (_, _, _) => _buildInitials(40),
          ),
        ),
      );
    }
    return _buildInitials(40);
  }

  Widget _buildInitials(double size) {
    return Container(
      width: size,
      height: size,
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
        border: Border.all(
          color: AppColorsDark.onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColorsDark.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials.isNotEmpty ? initials : 'U',
          style: TextStyle(
            color: AppColorsDark.onSurface,
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}
