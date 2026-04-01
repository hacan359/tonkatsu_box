// Виджет одного ряда тира.

import 'package:flutter/material.dart';

import '../../../shared/models/collection_item.dart';
import '../../../shared/models/tier_definition.dart';
import '../../../shared/models/tier_list_entry.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import 'tier_item_card.dart';

/// Минимальная высота ряда тира.
const double kTierRowMinHeight = kTierItemMinTotalHeight + AppSpacing.xs * 2 + 4;

/// Виджет одного ряда тира.
///
/// Слева — цветная метка, справа — горизонтальный скролл с обложками.
class TierRow extends StatelessWidget {
  /// Создаёт [TierRow].
  const TierRow({
    required this.tierListId,
    required this.definition,
    required this.entries,
    required this.itemsMap,
    required this.onDrop,
    required this.onDefinitionTap,
    this.overlayResolver,
    super.key,
  });

  /// ID тир-листа.
  final int tierListId;

  /// Определение тира.
  final TierDefinition definition;

  /// Записи в этом тире.
  final List<TierListEntry> entries;

  /// Карта всех элементов по ID.
  final Map<int, CollectionItem> itemsMap;

  /// Callback при drop элемента.
  final void Function(int collectionItemId) onDrop;

  /// Callback при нажатии на метку тира.
  final VoidCallback onDefinitionTap;

  /// Функция для резолва overlay asset (null = overlay из модели).
  final String? Function(CollectionItem item)? overlayResolver;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Метка тира
          GestureDetector(
            onTap: onDefinitionTap,
            onLongPress: onDefinitionTap,
            child: Container(
              width: 70,
              constraints: const BoxConstraints(minHeight: kTierRowMinHeight),
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
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Область с элементами + drag target
          Expanded(
            child: DragTarget<int>(
              onAcceptWithDetails: (DragTargetDetails<int> details) =>
                  onDrop(details.data),
              builder: (BuildContext context, List<int?> candidateData,
                  List<dynamic> rejectedData) {
                return Container(
                  constraints:
                      const BoxConstraints(minHeight: kTierRowMinHeight),
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
                  child: entries.isEmpty
                      ? const SizedBox.expand()
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: entries.map((TierListEntry entry) {
                              final CollectionItem? item =
                                  itemsMap[entry.collectionItemId];
                              if (item == null) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                key: ValueKey<int>(
                                    entry.collectionItemId),
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.xs,
                                ),
                                child: TierItemCard(
                                  item: item,
                                  isDraggable: true,
                                  platformOverlayAsset:
                                      overlayResolver?.call(item),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Определяет цвет текста (чёрный или белый) на основе яркости фона.
  Color _textColorFor(Color background) {
    final double luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
