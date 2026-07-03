import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/app_router/app_routes.gr.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';
import 'package:music_app/core/widgets/custom_search_bar.dart';
import 'package:music_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:music_app/l10n/app_localizations.dart';

class HomeHeaderWidget extends StatelessWidget {
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;

  const HomeHeaderWidget({
    super.key,
    this.searchController,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BlocBuilder<ProfileCubit, ProfileState>(
                builder: (context, state) {
                  final userName = state.firstName?.isNotEmpty == true
                      ? state.firstName!
                      : 'User';
                  return Text(
                    l10n.hello(userName),
                    style: const TextStyle(
                      color: AppColorsDark.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  );
                },
              ),
              BlocBuilder<ProfileCubit, ProfileState>(
                builder: (context, state) {
                  return GestureDetector(
                    onTap: () => context.router.push(const MyProfileRoute()),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E26),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColorsDark.onSurface.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: state.isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColorsDark.onSurface54,
                                ),
                              ),
                            )
                          : _buildAvatar(state),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          CustomSearchBar(
            hintText: l10n.searchFor,
            controller: searchController,
            onChanged: onSearchChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ProfileState state) {
    // Si tiene avatar, mostrar la imagen
    if (state.avatarUrl.isValidImageUrl) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: state.avatarUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildInitials(state),
          errorWidget: (context, url, error) => _buildInitials(state),
        ),
      );
    }
    // Si no tiene avatar, mostrar iniciales
    return _buildInitials(state);
  }

  Widget _buildInitials(ProfileState state) {
    final initials = state.initials.isNotEmpty ? state.initials : 'U';
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColorsDark.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
