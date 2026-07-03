// ignore_for_file: unnecessary_underscores
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/app_router/app_routes.gr.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:music_app/l10n/app_localizations.dart';

import 'widgets/atoms/profile_avatar_atom.dart';
import 'widgets/atoms/settings_item_atom.dart';
import 'widgets/molecules/settings_section_molecule.dart';
import 'widgets/organisms/profile_loading_organism.dart';

@RoutePage()
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileCubit = context.read<ProfileCubit>();
      if (!profileCubit.state.isLoading && profileCubit.state.profile == null) {
        profileCubit.loadProfile();
      }
    });
    return const _ProfileContainer();
  }
}

class _ProfileContainer extends StatelessWidget {
  const _ProfileContainer();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return _ProfilePresentationalView(
          state: state,
          onBackPressed: () => context.router.pop(),
          onNavigateToSettings: () => context.router.push(const SettingsRoute()),
          onNavigateToMyProfile: () => context.router.push(const MyProfileRoute()),
        );
      },
    );
  }
}

class _ProfilePresentationalView extends StatelessWidget {
  final ProfileState state;
  final VoidCallback onBackPressed;
  final VoidCallback onNavigateToSettings;
  final VoidCallback onNavigateToMyProfile;

  const _ProfilePresentationalView({
    required this.state,
    required this.onBackPressed,
    required this.onNavigateToSettings,
    required this.onNavigateToMyProfile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.profileAndSettings,
          style: const TextStyle(
            color: AppColorsDark.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColorsDark.onSurface,
          ),
          onPressed: onBackPressed,
        ),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (state.isLoading) {
      return const ProfileLoadingOrganism();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _ProfileHeader(
          displayName: state.displayName,
          email: state.email,
          avatarUrl: state.avatarUrl,
          initials: state.initials,
          onTap: onNavigateToMyProfile,
        ),
        SettingsSectionMolecule(
          title: l10n.settings,
          items: [
            SettingsItemAtom(
              icon: Icons.settings,
              title: l10n.settings,
              onTap: onNavigateToSettings,
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String initials;
  final VoidCallback onTap;

  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.initials,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            ProfileAvatarAtom(
              avatarUrl: avatarUrl,
              initials: initials,
              size: 80,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: AppColorsDark.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      color: AppColorsDark.onSurface,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColorsDark.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
