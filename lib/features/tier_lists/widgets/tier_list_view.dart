// Виджет отображения тир-листа с drag-and-drop.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/tier_definition.dart';
import '../../../shared/models/tier_list_entry.dart';
import '../../../shared/theme/app_colors.dart';
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
    super.key,
  });

  /// ID тир-листа.
  final int tierListId;

  /// Состояние тир-листа.
  final TierListDetailState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
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
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: TierRow(
              tierListId: tierListId,
              definition: def,
              entries: entriesByTier[def.tierKey] ?? <TierListEntry>[],
              itemsMap: itemsMap,
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
          items: state.unrankedItems,
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
              ListTile(
                leading: const Icon(Icons.add),
                title: Text(l.tierListAddTier),
                onTap: () {
                  Navigator.pop(ctx);
                  _addTier(context, ref);
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
    final Color? picked = await showDialog<Color>(
      context: context,
      builder: (BuildContext ctx) => _ColorPickerDialog(
        currentColor: def.color,
      ),
    );
    if (picked != null) {
      await ref
          .read(tierListDetailProvider(tierListId).notifier)
          .updateTierDefinition(def.tierKey, color: picked);
    }
  }

  Future<void> _addTier(BuildContext context, WidgetRef ref) async {
    final TextEditingController controller = TextEditingController();
    final S l = S.of(context);
    final String? label = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.tierListAddTier),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l.tierListNameHint),
          onSubmitted: (String value) =>
              Navigator.of(ctx).pop(value.trim()),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l.create),
          ),
        ],
      ),
    );
    if (label != null && label.isNotEmpty) {
      final String key = 'custom_${DateTime.now().millisecondsSinceEpoch}';
      await ref
          .read(tierListDetailProvider(tierListId).notifier)
          .addTier(key, label, AppColors.textTertiary);
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
                    return TierItemCard(item: item, isDraggable: true);
                  }).toList(),
                ),
        );
      },
    );
  }
}

/// Диалог выбора цвета для тира.
class _ColorPickerDialog extends StatelessWidget {
  const _ColorPickerDialog({required this.currentColor});

  final Color currentColor;

  static const List<Color> _colors = <Color>[
    Color(0xFFFF4444), // Red
    Color(0xFFFF8C00), // Orange
    Color(0xFFFFD700), // Yellow
    Color(0xFF44BB44), // Green
    Color(0xFF4488FF), // Blue
    Color(0xFF8844FF), // Purple
    Color(0xFFFF44BB), // Pink
    Color(0xFF44DDDD), // Cyan
    Color(0xFF888888), // Gray
    Color(0xFFBB8844), // Brown
    Color(0xFFFFFFFF), // White
    Color(0xFF333333), // Dark
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).tierListChangeColor),
      content: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: _colors.map((Color color) {
          final bool isSelected = color.toARGB32() == currentColor.toARGB32();
          return InkWell(
            onTap: () => Navigator.of(context).pop(color),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: isSelected
                    ? Border.all(color: AppColors.textPrimary, width: 3)
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
