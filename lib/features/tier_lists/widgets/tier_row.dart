import 'package:core/models/collection_item.dart';
import 'package:core/models/tier_definition.dart';
import 'package:core/models/tier_list_entry.dart';
import 'package:flutter/material.dart';

import '../../../shared/constants/platform_features.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import 'tier_item_card.dart';
import '../../../shared/constants/tier_definition_ui.dart';

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
    this.tierDraggable = false,
    this.overlayResolver,
    super.key,
  });

  final int tierListId;
  final TierDefinition definition;
  final List<TierListEntry> entries;
  final Map<int, CollectionItem> itemsMap;

  /// Resolved once in the parent so each card doesn't subscribe to settings.
  final String titleLanguage;

  /// Insert the dragged item at [index]; null appends to the end.
  final void Function(int collectionItemId, int? index) onDrop;

  final VoidCallback onDefinitionTap;

  /// Desktop-only drag of the whole tier by its label.
  final bool tierDraggable;

  final String? Function(CollectionItem item)? overlayResolver;

  void _handleSlotDrop(int draggedId, int slotIndex) {
    // A same-tier move from an earlier slot shifts the anchor one left.
    int insertAt = slotIndex;
    final int oldIndex = entries.indexWhere(
      (TierListEntry e) => e.collectionItemId == draggedId,
    );
    if (oldIndex != -1 && oldIndex < slotIndex) insertAt -= 1;
    onDrop(draggedId, insertAt);
  }

  @override
  Widget build(BuildContext context) {
    final TierRowMetrics m = TierRowMetrics.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
        _buildLabel(m),
        Expanded(
          child: DragTarget<int>(
            onAcceptWithDetails: (DragTargetDetails<int> details) =>
                onDrop(details.data, null),
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
                          for (int i = 0; i < entries.length; i++)
                            if (itemsMap[entries[i].collectionItemId] != null)
                              _TierCardSlot(
                                key: ValueKey<int>(
                                  entries[i].collectionItemId,
                                ),
                                indicatorHeight: m.cardTotalHeight,
                                onDrop: (int draggedId) =>
                                    _handleSlotDrop(draggedId, i),
                                child: TierItemCard(
                                  item: itemsMap[entries[i].collectionItemId]!,
                                  displayName:
                                      itemsMap[entries[i].collectionItemId]!
                                          .displayName(titleLanguage),
                                  isDraggable: true,
                                  width: m.cardWidth,
                                  height: m.cardImageHeight,
                                  labelHeight: m.cardLabelMinHeight,
                                  platformOverlayAsset: overlayResolver?.call(
                                    itemsMap[entries[i].collectionItemId]!,
                                  ),
                                ),
                              ),
                          // Empty-space hover appends — mark the end slot.
                          if (candidateData.isNotEmpty)
                            _InsertionBar(
                              visible: true,
                              height: m.cardTotalHeight,
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

  Widget _buildLabel(TierRowMetrics m) {
    final Widget label = GestureDetector(
      onTap: onDefinitionTap,
      onLongPress: onDefinitionTap,
      child: _labelBox(
        m,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusSm),
          bottomLeft: Radius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
    // Mobile long-press is taken by the options sheet. Plain Draggable, not
    // ReorderableListView: its GlobalKey reparenting during layout crashes
    // the card Tooltips (OverlayPortal) under the screen's LayoutBuilder.
    if (!tierDraggable || kIsMobile) return label;
    return Draggable<String>(
      data: definition.tierKey,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.85,
          child: _labelBox(
            m,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            height: m.rowMinHeight,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: label),
      child: label,
    );
  }

  Widget _labelBox(
    TierRowMetrics m, {
    required BorderRadius borderRadius,
    double? height,
  }) {
    return Container(
      width: m.tierLabelWidth,
      height: height,
      constraints:
          height == null ? BoxConstraints(minHeight: m.rowMinHeight) : null,
      decoration: BoxDecoration(
        color: definition.color,
        borderRadius: borderRadius,
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
    );
  }

  Color _textColorFor(Color background) {
    final double luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

/// Drop zone over a card: a drop inserts before it; hover opens an
/// insertion-bar gap at that spot.
class _TierCardSlot extends StatelessWidget {
  const _TierCardSlot({
    required this.indicatorHeight,
    required this.onDrop,
    required this.child,
    super.key,
  });

  final double indicatorHeight;
  final void Function(int draggedId) onDrop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onAcceptWithDetails: (DragTargetDetails<int> details) =>
          onDrop(details.data),
      builder: (BuildContext context, List<int?> candidateData,
          List<dynamic> rejectedData) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _InsertionBar(
              visible: candidateData.isNotEmpty,
              height: indicatorHeight,
            ),
            child,
          ],
        );
      },
    );
  }
}

/// Marks where a dragged card will land; collapses to zero width when hidden.
class _InsertionBar extends StatelessWidget {
  const _InsertionBar({
    required this.visible,
    required this.height,
  });

  final bool visible;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: visible ? 6 : 0,
      height: height,
      margin: EdgeInsets.only(right: visible ? AppSpacing.xs : 0),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
