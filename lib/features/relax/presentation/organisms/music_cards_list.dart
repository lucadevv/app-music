import 'package:flutter/material.dart';
import 'package:music_app/core/presentation/widgets/molecules/shared_media_card.dart';
import 'package:music_app/features/relax/presentation/atoms/app_text_styles.dart';
import 'package:music_app/l10n/app_localizations.dart';

class MusicCardsList extends StatelessWidget {
  final int itemCount;

  const MusicCardsList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Text(l10n.forYou, style: RelaxTextStyles.sectionTitle),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SharedMediaCard(
                  title: 'Calvin Harris, Martin Garrix, Dewain Whi...',
                  subtitle: '${l10n.mix} ${index + 1}',
                  width: 280,
                  placeholderIcon: Icons.music_note,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
