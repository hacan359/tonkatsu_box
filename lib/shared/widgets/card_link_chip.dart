import 'package:core/models/collection_item.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'cached_image.dart';
import 'source_badge.dart';
import '../constants/collection_item_ui.dart';

/// Inline chip for a resolved cross-link: cover, source, name, year, type icon
/// and an optional subcategory (platform for games, movie/TV for animation).
class CardLinkChip extends StatelessWidget {
  const CardLinkChip({
    required this.item,
    required this.baseStyle,
    required this.onTap,
    super.key,
  });

  final CollectionItem item;
  final TextStyle baseStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final int? year = item.releaseYear;
    final String? subcategory = item.cardSubcategoryLabel(l);
    final TextStyle metaStyle = baseStyle.copyWith(
      color: AppColors.textTertiary,
      fontSize: (baseStyle.fontSize ?? 14) - 2,
    );

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.brand.withAlpha(20),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.brand.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildThumb(),
                SourceBadge(source: item.dataSource, size: SourceBadgeSize.small),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    item.itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: baseStyle.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (year != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: Text('($year)', style: metaStyle),
                  ),
                if (subcategory != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text('· $subcategory', style: metaStyle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumb() {
    final String imageId = item.coverImageId;
    if (imageId.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          width: 14,
          height: 20,
          child: CachedImage(
            imageType: item.imageType,
            imageId: imageId,
            remoteUrl: item.thumbnailUrl ?? item.coverUrl ?? '',
            fit: BoxFit.cover,
            placeholder: const SizedBox.shrink(),
            errorWidget: const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
