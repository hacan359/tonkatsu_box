import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';

class SeasonsInfo extends StatelessWidget {
  const SeasonsInfo({
    required this.totalSeasons,
    required this.totalEpisodes,
    required this.accentColor,
    super.key,
  });

  final int? totalSeasons;
  final int? totalEpisodes;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (totalSeasons == null && totalEpisodes == null) {
      return const SizedBox.shrink();
    }
    final S l = S.of(context);
    final StringBuffer buf = StringBuffer();
    if (totalSeasons != null) {
      buf.write(l.totalSeasons(totalSeasons!));
    }
    if (totalSeasons != null && totalEpisodes != null) {
      buf.write(' • ');
    }
    if (totalEpisodes != null) {
      buf.write(l.totalEpisodes(totalEpisodes!));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Icon(Icons.video_library_outlined, color: accentColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            buf.toString(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
