// Offscreen виджет для рендеринга тир-листа в картинку.

import 'package:flutter/material.dart';

import '../../../shared/models/collection_item.dart';
import '../../../shared/models/tier_definition.dart';
import '../../../shared/models/tier_list_entry.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_assets.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/tier_list_detail_provider.dart';
import 'tier_item_card.dart';

/// Размеры обложки в экспорте.
const double _kExportItemWidth = 80;
const double _kExportItemHeight = 110;

/// Offscreen виджет для экспорта тир-листа как PNG.
///
/// Рендерит только тиры (без Unranked, без UI-кнопок).
class TierListExportView extends StatelessWidget {
  /// Создаёт [TierListExportView].
  const TierListExportView({
    required this.repaintKey,
    required this.state,
    this.overlayResolver,
    super.key,
  });

  /// Ключ для RepaintBoundary.
  final GlobalKey repaintKey;

  /// Состояние тир-листа.
  final TierListDetailState state;

  /// Функция для резолва overlay asset.
  final String? Function(CollectionItem item)? overlayResolver;

  @override
  Widget build(BuildContext context) {
    final Map<String, List<TierListEntry>> entriesByTier =
        state.entriesByTier;
    final Map<int, CollectionItem> itemsMap = <int, CollectionItem>{
      for (final CollectionItem item in state.items) item.id: item,
    };

    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        color: AppColors.background,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Заголовок
              Text(
                state.tierList.name,
                style: AppTypography.h2.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Тиры
              for (final TierDefinition def in state.definitions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: _ExportTierRow(
                    definition: def,
                    entries: entriesByTier[def.tierKey] ?? <TierListEntry>[],
                    itemsMap: itemsMap,
                    overlayResolver: overlayResolver,
                  ),
                ),

              // Подпись
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: AppColors.surfaceBorder),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Image.asset(AppAssets.logo, width: 16, height: 16),
                  const SizedBox(width: 4),
                  Text(
                    'made by Tonkatsu Box',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportTierRow extends StatelessWidget {
  const _ExportTierRow({
    required this.definition,
    required this.entries,
    required this.itemsMap,
    this.overlayResolver,
  });

  final TierDefinition definition;
  final List<TierListEntry> entries;
  final Map<int, CollectionItem> itemsMap;
  final String? Function(CollectionItem item)? overlayResolver;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Метка тира
          Container(
            width: 70,
            constraints: const BoxConstraints(
              minHeight: _kExportItemHeight + kTierItemMinLabelHeight + 8,
            ),
            decoration: BoxDecoration(
              color: definition.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              definition.label,
              style: AppTypography.h3.copyWith(
                color: definition.color.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Элементы
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: _kExportItemHeight + kTierItemMinLabelHeight + 8,
              ),
              decoration: BoxDecoration(
                color: definition.color.withAlpha(20),
                border: Border.all(
                  color: AppColors.surfaceBorder,
                  width: 0.5,
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: entries.map((TierListEntry entry) {
                  final CollectionItem? item =
                      itemsMap[entry.collectionItemId];
                  if (item == null) return const SizedBox.shrink();
                  return TierItemCard(
                    item: item,
                    width: _kExportItemWidth,
                    height: _kExportItemHeight,
                    platformOverlayAsset:
                        overlayResolver?.call(item),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
