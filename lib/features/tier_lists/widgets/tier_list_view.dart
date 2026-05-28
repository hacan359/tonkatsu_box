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

/// Tiers stacked over the Unranked pool, with a vertical drag handle between
/// them so the user can resize the two regions.
class TierListView extends ConsumerStatefulWidget {
  const TierListView({
    required this.tierListId,
    required this.state,
    this.filterQuery = '',
    super.key,
  });

  final int tierListId;
  final TierListDetailState state;
  final String filterQuery;

  @override
  ConsumerState<TierListView> createState() => _TierListViewState();
}

class _TierListViewState extends ConsumerState<TierListView> {
  static const double _minTopHeight = 80;
  static const double _minBottomHeight = 120;
  static const double _dividerThickness = 24;

  double? _topHeight;

  void _handleDragUpdate(DragUpdateDetails details, double maxAllowed) {
    setState(() {
      final double current = _topHeight ?? maxAllowed / 3;
      _topHeight = (current + details.delta.dy).clamp(
        _minTopHeight,
        maxAllowed,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final WidgetRef ref = this.ref;
    final TierListDetailState state = widget.state;
    final int tierListId = widget.tierListId;
    final String filterQuery = widget.filterQuery;
    final S l = S.of(context);
    // Granular select avoids rebuilding on every unrelated settings change.
    final String titleLanguage = ref.watch(settingsNotifierProvider
        .select((SettingsState s) => s.animeMangaTitleLanguage));
    final String? Function(CollectionItem) overlayResolver = ref.watch(
      settingsNotifierProvider
          .select((SettingsState s) => s.resolveOverlayFor),
    );

    final Map<String, List<TierListEntry>> entriesByTier = state.entriesByTier;
    final Map<int, CollectionItem> itemsMap = state.itemsById;

    final List<CollectionItem> unranked = filterQuery.isEmpty
        ? state.unrankedItems
        : <CollectionItem>[
            for (final CollectionItem item in state.unrankedItems)
              if (item
                  .displayName(titleLanguage)
                  .toLowerCase()
                  .contains(filterQuery.toLowerCase()))
                item,
          ];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double total = constraints.maxHeight;
          final double maxTop = total - _minBottomHeight - _dividerThickness;
          final double defaultTop = total / 3;
          final double topH = (_topHeight ?? defaultTop)
              .clamp(_minTopHeight, maxTop > _minTopHeight ? maxTop : _minTopHeight);
          final double bottomH = total - topH - _dividerThickness;

          return Column(
            children: <Widget>[
              SizedBox(
                height: topH,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    for (final TierDefinition def in state.definitions)
                      Padding(
                        key: ValueKey<String>('tier_${def.tierKey}'),
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: TierRow(
                          tierListId: tierListId,
                          definition: def,
                          entries: entriesByTier[def.tierKey] ??
                              const <TierListEntry>[],
                          itemsMap: itemsMap,
                          titleLanguage: titleLanguage,
                          overlayResolver: overlayResolver,
                          onDrop: (int collectionItemId) {
                            ref
                                .read(
                                  tierListDetailProvider(tierListId).notifier,
                                )
                                .moveToTier(collectionItemId, def.tierKey);
                          },
                          onDefinitionTap: () =>
                              _showTierOptions(context, ref, def),
                        ),
                      ),
                  ],
                ),
              ),
              _SplitterHandle(
                label: l.tierListUnranked,
                thickness: _dividerThickness,
                onDragUpdate: (DragUpdateDetails d) =>
                    _handleDragUpdate(d, maxTop),
              ),
              SizedBox(
                height: bottomH,
                child: _UnrankedPool(
                  tierListId: tierListId,
                  items: unranked,
                  titleLanguage: titleLanguage,
                  overlayResolver: overlayResolver,
                ),
              ),
            ],
          );
        },
      ),
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
              if (widget.state.definitions.length > 1)
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.error),
                  title: Text(
                    l.tierListDeleteTier,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref
                        .read(
                          tierListDetailProvider(widget.tierListId).notifier,
                        )
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
          .read(tierListDetailProvider(widget.tierListId).notifier)
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
          .read(tierListDetailProvider(widget.tierListId).notifier)
          .updateTierDefinition(def.tierKey, color: picked);
    }
  }

}

class _UnrankedPool extends ConsumerWidget {
  const _UnrankedPool({
    required this.tierListId,
    required this.items,
    required this.titleLanguage,
    required this.overlayResolver,
  });

  final int tierListId;
  final List<CollectionItem> items;
  final String titleLanguage;
  final String? Function(CollectionItem) overlayResolver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              // GridView.builder lazy-renders only visible cards — keeps
              // large Unranked pools cheap to scroll and filter.
              : GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: m.cardWidth + AppSpacing.xs,
                    mainAxisExtent: m.cardImageHeight + m.cardLabelMinHeight,
                    crossAxisSpacing: AppSpacing.xs,
                    mainAxisSpacing: AppSpacing.xs,
                  ),
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int index) {
                    final CollectionItem item = items[index];
                    return TierItemCard(
                      key: ValueKey<int>(item.id),
                      item: item,
                      displayName: item.displayName(titleLanguage),
                      isDraggable: true,
                      width: m.cardWidth,
                      height: m.cardImageHeight,
                      labelHeight: m.cardLabelMinHeight,
                      platformOverlayAsset: overlayResolver(item),
                    );
                  },
                ),
        );
      },
    );
  }
}

/// Vertical drag handle between tiers and Unranked; resize math lives in
/// the parent.
class _SplitterHandle extends StatelessWidget {
  const _SplitterHandle({
    required this.label,
    required this.thickness,
    required this.onDragUpdate,
  });

  final String label;
  final double thickness;
  final void Function(DragUpdateDetails details) onDragUpdate;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: onDragUpdate,
        child: SizedBox(
          height: thickness,
          child: Row(
            children: <Widget>[
              const Expanded(child: Divider(color: AppColors.surfaceBorder)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.drag_handle,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(child: Divider(color: AppColors.surfaceBorder)),
            ],
          ),
        ),
      ),
    );
  }
}
