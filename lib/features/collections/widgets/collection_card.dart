// Dispatches to [ClassicCollectionCard] (3+3 mosaic) or [RichCollectionCard]
// (full-card hero image) depending on the rich-mode setting and whether the
// collection has a hero. Public API stays [CollectionCard]/[UncategorizedCard].

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/collection_hero_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/rich_collections_provider.dart';
import 'classic/classic_collection_card.dart';
import 'collection_card_shell.dart';
import 'rich/rich_collection_card.dart';

class CollectionCard extends ConsumerWidget {
  const CollectionCard({
    required this.collection,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.onFocusChanged,
    super.key,
  });

  final Collection collection;

  final VoidCallback? onTap;

  final VoidCallback? onLongPress;

  /// Right-click callback; the position is global, ready for showMenu.
  final void Function(Offset globalPosition)? onSecondaryTap;

  final ValueChanged<bool>? onFocusChanged;

  /// Card corner radius, exposed so outer decorations can align with it.
  static const double mosaicRadius = CollectionCardShell.radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool richEnabled = ref.watch(richCollectionsEnabledProvider);
    final String? heroFile = collection.heroImagePath;

    String? heroAbsPath;
    if (richEnabled && heroFile != null) {
      try {
        heroAbsPath =
            ref.watch(collectionHeroServiceProvider).resolve(heroFile);
      } on Object {
        heroAbsPath = null;
      }
    }

    if (heroAbsPath != null) {
      return RichCollectionCard(
        collection: collection,
        heroAbsolutePath: heroAbsPath,
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTap: onSecondaryTap,
        onFocusChanged: onFocusChanged,
      );
    }
    // Rich mode without a hero: classic card with the description shown.
    return ClassicCollectionCard(
      collection: collection,
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTap: onSecondaryTap,
      onFocusChanged: onFocusChanged,
      showDescription: richEnabled,
    );
  }
}

class UncategorizedCard extends StatelessWidget {
  const UncategorizedCard({
    required this.count,
    this.onTap,
    super.key,
  });

  final int count;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CollectionCard.mosaicRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius:
                    BorderRadius.circular(CollectionCard.mosaicRadius),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.5),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              // scaleDown keeps the icon + label from overflowing the image
              // area on small/narrow grid cards (no scaling at normal sizes).
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.uncategorizedDeprecationBadge,
                        style: AppTypography.h3.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.collectionsUncategorized,
            style: AppTypography.h3,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            l.collectionsUncategorizedItems(count),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
