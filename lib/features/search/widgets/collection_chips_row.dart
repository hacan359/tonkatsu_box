import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/navigation/search_providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/filter_subfilter_bar.dart';
import '../../../shared/widgets/scrollable_row_with_arrows.dart';
import '../../../shared/widgets/selected_count_chip.dart';
import '../../collections/providers/collections_provider.dart';

/// Row height passed to [ScrollableRowWithArrows] for arrow positioning.
const double _kRowHeight = 32;

/// Horizontal, multi-select row of collection chips under the Search tab's
/// filter bar.
///
/// Nothing selected → the normal flow (tap a result to open its details and add
/// via the in-sheet picker). One or more selected → tapping a result adds it
/// straight into every selected collection, no extra dialog. A pinned counter
/// at the leading edge shows how many are selected (visible even when the
/// chips have scrolled off-screen) and clears the selection on tap. Reads and
/// writes [searchTargetCollectionsProvider].
///
/// Only real collections are offered (Uncategorized is never a target here).
/// When there are no collections the row collapses to nothing.
///
/// Visually reuses [FilterTabChip] — the same flat underline-tab chip as the
/// media-type subfilters — tinted with the brand accent.
class CollectionChipsRow extends ConsumerStatefulWidget {
  /// Creates a [CollectionChipsRow].
  const CollectionChipsRow({super.key});

  @override
  ConsumerState<CollectionChipsRow> createState() => _CollectionChipsRowState();
}

class _CollectionChipsRowState extends ConsumerState<CollectionChipsRow> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Collection> collections =
        ref.watch(collectionsProvider).valueOrNull ?? <Collection>[];
    if (collections.isEmpty) return const SizedBox.shrink();

    final Set<int> selected = ref.watch(searchTargetCollectionsProvider);

    final List<Widget> chips = <Widget>[];
    for (int i = 0; i < collections.length; i++) {
      if (i > 0) chips.add(const SizedBox(width: AppSpacing.sm));
      final Collection collection = collections[i];
      chips.add(
        FilterTabChip(
          data: SubfilterChipData(
            label: collection.name,
            accent: AppColors.brand,
            selected: selected.contains(collection.id),
            onTap: () => _toggle(collection.id),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          // Pinned (never scrolls) so the active selection stays visible even
          // when the selected chips have scrolled off-screen.
          if (selected.isNotEmpty) ...<Widget>[
            SelectedCountChip(
              count: selected.length,
              onClear: _clear,
              clearTooltip: S.of(context).bulkClearSelection,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          // Desktop scrolling, all three ways: hover arrows, mouse wheel, and
          // click-drag (ScrollableRowWithArrows bundles them). Touch swipe on mobile.
          Expanded(
            child: ScrollableRowWithArrows(
              controller: _scrollController,
              height: _kRowHeight,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(children: chips),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggle(int collectionId) {
    final Set<int> next = <int>{...ref.read(searchTargetCollectionsProvider)};
    if (!next.remove(collectionId)) next.add(collectionId);
    ref.read(searchTargetCollectionsProvider.notifier).state = next;
  }

  void _clear() =>
      ref.read(searchTargetCollectionsProvider.notifier).state = <int>{};
}
