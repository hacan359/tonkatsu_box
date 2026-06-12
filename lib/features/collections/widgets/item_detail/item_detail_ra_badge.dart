import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/ra_api.dart';
import '../../../../core/services/ra_to_igdb_mapper.dart';
import '../../../../shared/models/collection_item.dart';
import '../../../../shared/models/media_type.dart';
import '../../../../shared/models/tracker_game_data.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../providers/tracker_provider.dart';
import 'pulsing_ra_link.dart';

class ItemDetailRaBadge extends ConsumerWidget {
  const ItemDetailRaBadge({
    required this.item,
    required this.onLink,
    super.key,
  });

  final CollectionItem item;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (item.mediaType != MediaType.game) return const SizedBox.shrink();

    final TrackerGameData? raData = ref
        .watch(trackerDetailProvider(
            (gameId: item.externalId, platformId: item.platformId)))
        .valueOrNull
        ?.gameData;

    if (raData != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => launchUrl(
            Uri.parse(raData.raGameUrl),
            mode: LaunchMode.externalApplication,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            child: Image.asset(
              'assets/images/ra_logo.png',
              width: 18,
              height: 18,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      );
    }

    final bool hasRaCreds = ref.watch(raApiProvider).hasCredentials;
    if (!hasRaCreds || item.platformId == null) {
      return const SizedBox.shrink();
    }
    if (RaToIgdbMapper.igdbToRaConsoleIds(item.platformId!).isEmpty) {
      return const SizedBox.shrink();
    }

    return PulsingRaLink(onTap: onLink);
  }
}
