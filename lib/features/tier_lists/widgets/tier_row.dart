// Виджет одного ряда тира.

import 'package:flutter/material.dart';

import '../../../shared/models/collection_item.dart';
import '../../../shared/models/tier_definition.dart';
import '../../../shared/models/tier_list_entry.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import 'tier_item_card.dart';

/// Ширина, ниже которой тир-ряд переходит в компактный режим (узкий экран).
const double _kCompactBreakpoint = 500;

/// Размеры элементов тир-ряда, зависящие от ширины экрана.
class TierRowMetrics {
  const TierRowMetrics({
    required this.cardWidth,
    required this.cardImageHeight,
    required this.cardLabelMinHeight,
    required this.tierLabelWidth,
    required this.tierLabelFont,
  });

  /// Выбирает метрики по ширине экрана.
  factory TierRowMetrics.of(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    return width < _kCompactBreakpoint ? compact : standard;
  }

  /// Метрики для компактных экранов (телефон).
  static const TierRowMetrics compact = TierRowMetrics(
    cardWidth: 64,
    cardImageHeight: 86,
    cardLabelMinHeight: 24,
    tierLabelWidth: 48,
    tierLabelFont: 20,
  );

  /// Метрики по умолчанию (планшет / десктоп).
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

  /// Полная высота карточки (картинка + подпись).
  double get cardTotalHeight => cardImageHeight + cardLabelMinHeight;

  /// Минимальная высота ряда — чуть больше, чем карточка.
  double get rowMinHeight => cardTotalHeight + AppSpacing.xs * 2 + 4;
}

/// Виджет одного ряда тира.
///
/// Слева — цветная метка, справа — Wrap с обложками.
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
                          children: entries.map((TierListEntry entry) {
                            final CollectionItem? item =
                                itemsMap[entry.collectionItemId];
                            if (item == null) {
                              return const SizedBox.shrink();
                            }
                            return TierItemCard(
                              key: ValueKey<int>(entry.collectionItemId),
                              item: item,
                              isDraggable: true,
                              width: m.cardWidth,
                              height: m.cardImageHeight,
                              platformOverlayAsset:
                                  overlayResolver?.call(item),
                            );
                          }).toList(),
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
