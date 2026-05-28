import 'package:flutter/material.dart';

import '../../../shared/models/collection_item.dart';
import '../../../shared/models/tier_definition.dart';
import '../../../shared/models/tier_list_entry.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import 'tier_item_card.dart';

const double _kCompactBreakpoint = 500;

class TierRowMetrics {
  const TierRowMetrics({
    required this.cardWidth,
    required this.cardImageHeight,
    required this.cardLabelMinHeight,
    required this.tierLabelWidth,
    required this.tierLabelFont,
  });

  factory TierRowMetrics.of(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    return width < _kCompactBreakpoint ? compact : standard;
  }

  /// `cardLabelMinHeight: 28` is the floor for 2 lines of 10pt × 1.2 text
  /// plus 4px vertical padding — any less and the label overflows.
  static const TierRowMetrics compact = TierRowMetrics(
    cardWidth: 64,
    cardImageHeight: 86,
    cardLabelMinHeight: 28,
    tierLabelWidth: 48,
    tierLabelFont: 20,
  );

  static const TierRowMetrics standard = TierRowMetrics(
    cardWidth: kTierItemWidth,
    cardImageHeight: kTierItemImageHeight,
    cardLabelMinHeight: kTierItemMinLabelHeight,
    tierLabelWidth: 70,
    tierLabelFont: 24,
  );

  final double cardWidth;
  final double cardImageHeight;
  final double cardLabelMinHeight;
  final double tierLabelWidth;
  final double tierLabelFont;

  double get cardTotalHeight => cardImageHeight + cardLabelMinHeight;

  double get rowMinHeight => cardTotalHeight + AppSpacing.xs * 2 + 4;
}

class TierRow extends StatelessWidget {
  const TierRow({
    required this.tierListId,
    required this.definition,
    required this.entries,
    required this.itemsMap,
    required this.titleLanguage,
    required this.onDrop,
    required this.onDefinitionTap,
    this.overlayResolver,
    super.key,
  });

  final int tierListId;
  final TierDefinition definition;
  final List<TierListEntry> entries;
  final Map<int, CollectionItem> itemsMap;

  /// Resolved once in the parent so each card doesn't subscribe to settings.
  final String titleLanguage;

  final void Function(int collectionItemId) onDrop;
  final VoidCallback onDefinitionTap;
  final String? Function(CollectionItem item)? overlayResolver;

  @override
  Widget build(BuildContext context) {
    final TierRowMetrics m = TierRowMetrics.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
        GestureDetector(
          onTap: onDefinitionTap,
          onLongPress: onDefinitionTap,
          child: Container(
            width: m.tierLabelWidth,
            constraints: BoxConstraints(minHeight: m.rowMinHeight),
            decoration: BoxDecoration(
              color: definition.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusSm),
                bottomLeft: Radius.circular(AppSpacing.radiusSm),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              definition.label,
              style: AppTypography.h2.copyWith(
                color: _textColorFor(definition.color),
                fontWeight: FontWeight.bold,
                fontSize: m.tierLabelFont,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Expanded(
          child: DragTarget<int>(
            onAcceptWithDetails: (DragTargetDetails<int> details) =>
                onDrop(details.data),
            builder: (BuildContext context, List<int?> candidateData,
                List<dynamic> rejectedData) {
              return Container(
                constraints: BoxConstraints(minHeight: m.rowMinHeight),
                decoration: BoxDecoration(
                  color: definition.color.withAlpha(20),
                  border: candidateData.isNotEmpty
                      ? Border.all(color: definition.color, width: 2)
                      : Border.all(
                          color: AppColors.surfaceBorder,
                          width: 0.5,
                        ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(AppSpacing.radiusSm),
                    bottomRight: Radius.circular(AppSpacing.radiusSm),
                  ),
                ),
                padding: entries.isEmpty
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xs,
                      ),
                child: entries.isEmpty
                    ? const SizedBox.expand()
                    : Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: <Widget>[
                          for (final TierListEntry entry in entries)
                            if (itemsMap[entry.collectionItemId] != null)
                              TierItemCard(
                                key: ValueKey<int>(entry.collectionItemId),
                                item: itemsMap[entry.collectionItemId]!,
                                displayName: itemsMap[entry.collectionItemId]!
                                    .displayName(titleLanguage),
                                isDraggable: true,
                                width: m.cardWidth,
                                height: m.cardImageHeight,
                                labelHeight: m.cardLabelMinHeight,
                                platformOverlayAsset: overlayResolver
                                    ?.call(itemsMap[entry.collectionItemId]!),
                              ),
                        ],
                      ),
              );
            },
          ),
        ),
        ],
      ),
    );
  }

  Color _textColorFor(Color background) {
    final double luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
