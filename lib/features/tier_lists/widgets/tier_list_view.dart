// Виджет отображения тир-листа с drag-and-drop.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/tier_definition.dart';
import '../../../shared/models/tier_list_entry.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/color_picker_dialog.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/tier_list_detail_provider.dart';
import 'tier_item_card.dart';
import 'tier_row.dart';

/// Виджет отображения тир-листа.
///
/// Показывает тиры с drag-and-drop и пул Unranked.
class TierListView extends ConsumerWidget {
  /// Создаёт [TierListView].
  const TierListView({
    required this.tierListId,
    required this.state,
    this.filterQuery = '',
    super.key,
  });

  /// ID тир-листа.
  final int tierListId;

  /// Состояние тир-листа.
  final TierListDetailState state;

  /// Текстовый фильтр для Unranked pool.
  final String filterQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final SettingsState settings = ref.watch(settingsNotifierProvider);
    final Map<String, List<TierListEntry>> entriesByTier =
        state.entriesByTier;
    final Map<int, CollectionItem> itemsMap = <int, CollectionItem>{
      for (final CollectionItem item in state.items) item.id: item,
    };

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.sm),
      children: <Widget>[
        // Тиры
        for (final TierDefinition def in state.definitions)
          Padding(
            key: ValueKey<String>('tier_${def.tierKey}'),
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: TierRow(
              tierListId: tierListId,
              definition: def,
              entries: entriesByTier[def.tierKey] ?? <TierListEntry>[],
              itemsMap: itemsMap,
              overlayResolver: settings.resolveOverlayFor,
              onDrop: (int collectionItemId) {
                ref
                    .read(tierListDetailProvider(tierListId).notifier)
                    .moveToTier(collectionItemId, def.tierKey);
              },
              onDefinitionTap: () =>
                  _showTierOptions(context, ref, def),
            ),
          ),

        // Разделитель + Unranked
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            const Expanded(child: Divider(color: AppColors.surfaceBorder)),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
              ),
              child: Text(
                l.tierListUnranked,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.surfaceBorder)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Unranked pool
        _UnrankedPool(
          tierListId: tierListId,
          items: filterQuery.isEmpty
              ? state.unrankedItems
              : state.unrankedItems
                    .where((CollectionItem item) => item.itemName
                        .toLowerCase()
                        .contains(filterQuery.toLowerCase()))
                    .toList(),
        ),
      ],
    );
  }

  void _showTierOptions(
    BuildContext context,
    WidgetRef ref,
    TierDefinition def,
  ) {
    final S l = S.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(l.tierListRename),
                onTap: () {
                  Navigator.pop(ctx);
                  _renameTier(context, ref, def);
                },
              ),
              ListTile(
                leading: const Icon(Icons.palette),
                title: Text(l.tierListChangeColor),
                onTap: () {
                  Navigator.pop(ctx);
                  _changeColor(context, ref, def);
                },
              ),
              if (state.definitions.length > 1)
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.error),
                  title: Text(
                    l.tierListDeleteTier,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref
                        .read(tierListDetailProvider(tierListId).notifier)
                        .removeTier(def.tierKey);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _renameTier(
    BuildContext context,
    WidgetRef ref,
    TierDefinition def,
  ) async {
    final TextEditingController controller =
        TextEditingController(text: def.label);
    final String? newLabel = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(S.of(context).tierListRename),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (String value) =>
              Navigator.of(ctx).pop(value.trim()),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(S.of(context).save),
          ),
        ],
      ),
    );
    if (newLabel != null && newLabel.isNotEmpty) {
      await ref
          .read(tierListDetailProvider(tierListId).notifier)
          .updateTierDefinition(def.tierKey, label: newLabel);
    }
  }

  Future<void> _changeColor(
    BuildContext context,
    WidgetRef ref,
    TierDefinition def,
  ) async {
    final Color? picked = await ColorPickerDialog.show(
      context: context,
      currentColor: def.color,
    );
    if (picked != null) {
      await ref
          .read(tierListDetailProvider(tierListId).notifier)
          .updateTierDefinition(def.tierKey, color: picked);
    }
  }

}

class _UnrankedPool extends ConsumerWidget {
  const _UnrankedPool({
    required this.tierListId,
    required this.items,
  });

  final int tierListId;
  final List<CollectionItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsState overlaySettings =
        ref.watch(settingsNotifierProvider);
    final TierRowMetrics m = TierRowMetrics.of(context);
    return DragTarget<int>(
      onAcceptWithDetails: (DragTargetDetails<int> details) {
        ref
            .read(tierListDetailProvider(tierListId).notifier)
            .removeFromTier(details.data);
      },
      builder: (BuildContext context, List<int?> candidateData,
          List<dynamic> rejectedData) {
        return Container(
          constraints: const BoxConstraints(minHeight: 80),
          decoration: BoxDecoration(
            border: candidateData.isNotEmpty
                ? Border.all(color: AppColors.brand, width: 2)
                : null,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      S.of(context).tierListAllRanked,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                )
              : Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: items.map((CollectionItem item) {
                    return TierItemCard(
                      key: ValueKey<int>(item.id),
                      item: item,
                      isDraggable: true,
                      width: m.cardWidth,
                      height: m.cardImageHeight,
                      platformOverlayAsset:
                          overlaySettings.resolveOverlayFor(item),
                    );
                  }).toList(),
                ),
        );
      },
    );
  }
}
