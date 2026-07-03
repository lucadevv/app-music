import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';

class ProfileAvatarAtom extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  final double size;

  const ProfileAvatarAtom({
    required this.initials,
    super.key,
    this.avatarUrl,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isValidImageUrl) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatarUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildInitials(),
            errorWidget: (context, url, error) => _buildInitials(),
          ),
        ),
      );
    }
    return _buildInitials();
  }

  Widget _buildInitials() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorsDark.primary,
            AppColorsDark.primary.withValues(alpha: 0.7),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: AppColorsDark.onSurface,
            fontSize: size * 0.36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
