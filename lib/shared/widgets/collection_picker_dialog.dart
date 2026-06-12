import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../models/collection.dart';
import '../models/collection_list_sort_mode.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../../features/collections/providers/collections_provider.dart';

sealed class CollectionChoice {
  const CollectionChoice();
}

class ChosenCollection extends CollectionChoice {
  const ChosenCollection(this.collection);

  final Collection collection;
}

/// Choice to add the item without any collection (Uncategorized).
class WithoutCollection extends CollectionChoice {
  const WithoutCollection();
}

/// Returns the chosen [CollectionChoice], or null if cancelled.
///
/// [excludeCollectionId] hides that collection from the list.
/// [alreadyInCollectionIds] are disabled; a `null` entry disables the
/// Uncategorized option too.
Future<CollectionChoice?> showCollectionPickerDialog({
  required BuildContext context,
  required WidgetRef ref,
  int? excludeCollectionId,
  bool showUncategorized = true,
  String? title,
  Set<int?> alreadyInCollectionIds = const <int?>{},
  String? uncategorizedLabel,
  String? uncategorizedSubtitle,
  IconData? uncategorizedIcon,
}) async {
  final String resolvedTitle = title ?? S.of(context).chooseCollection;
  final AsyncValue<List<Collection>> collectionsAsync =
      ref.read(collectionsProvider);

  final CollectionListSortMode initialSortMode =
      ref.read(collectionListSortProvider);
  final bool initialDescending = ref.read(collectionListSortDescProvider);

  final List<Collection> collections =
      collectionsAsync.valueOrNull ?? <Collection>[];
  final List<Collection> editableCollections = collections
      .where(
        (Collection c) =>
            c.isEditable && c.id != excludeCollectionId,
      )
      .toList();

  return showDialog<CollectionChoice>(
    context: context,
    builder: (BuildContext context) => Dialog(
      child: _CollectionPickerContent(
        title: resolvedTitle,
        collections: editableCollections,
        showUncategorized: showUncategorized,
        alreadyInCollectionIds: alreadyInCollectionIds,
        initialSortMode: initialSortMode,
        initialDescending: initialDescending,
        uncategorizedLabel: uncategorizedLabel,
        uncategorizedSubtitle: uncategorizedSubtitle,
        uncategorizedIcon: uncategorizedIcon,
      ),
    ),
  );
}

class _CollectionPickerContent extends StatefulWidget {
  const _CollectionPickerContent({
    required this.title,
    required this.collections,
    required this.showUncategorized,
    required this.alreadyInCollectionIds,
    required this.initialSortMode,
    required this.initialDescending,
    this.uncategorizedLabel,
    this.uncategorizedSubtitle,
    this.uncategorizedIcon,
  });

  final String title;
  final List<Collection> collections;
  final bool showUncategorized;
  final Set<int?> alreadyInCollectionIds;
  final CollectionListSortMode initialSortMode;
  final bool initialDescending;
  final String? uncategorizedLabel;
  final String? uncategorizedSubtitle;
  final IconData? uncategorizedIcon;

  @override
  State<_CollectionPickerContent> createState() =>
      _CollectionPickerContentState();
}

class _CollectionPickerContentState extends State<_CollectionPickerContent> {
  final TextEditingController _filterController = TextEditingController();
  String _filterQuery = '';
  late CollectionListSortMode _sortMode;
  late bool _descending;

  @override
  void initState() {
    super.initState();
    _sortMode = widget.initialSortMode;
    _descending = widget.initialDescending;
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  List<Collection> get _filteredCollections {
    if (_filterQuery.isEmpty) return widget.collections;
    final String q = _filterQuery.toLowerCase();
    return widget.collections
        .where((Collection c) => c.name.toLowerCase().contains(q))
        .toList();
  }

  List<Collection> get _sortedCollections {
    final List<Collection> filtered = List<Collection>.of(_filteredCollections);

    filtered.sort((Collection a, Collection b) {
      final int result;
      switch (_sortMode) {
        case CollectionListSortMode.alphabetical:
          result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case CollectionListSortMode.createdDate:
          result = a.createdAt.compareTo(b.createdAt);
      }
      return _descending ? -result : result;
    });

    // Already-added collections sink to the bottom of the list.
    final List<Collection> available = filtered
        .where(
            (Collection c) => !widget.alreadyInCollectionIds.contains(c.id))
        .toList();
    final List<Collection> already = filtered
        .where(
            (Collection c) => widget.alreadyInCollectionIds.contains(c.id))
        .toList();
    return <Collection>[...available, ...already];
  }

  void _toggleSort() {
    setState(() {
      // Cycle: A-Z -> Z-A -> date desc -> date asc -> A-Z.
      if (_sortMode == CollectionListSortMode.alphabetical) {
        if (_descending) {
          _sortMode = CollectionListSortMode.createdDate;
          _descending = false;
        } else {
          _descending = true;
        }
      } else {
        if (_descending) {
          _sortMode = CollectionListSortMode.alphabetical;
          _descending = false;
        } else {
          _descending = true;
        }
      }
    });
  }

  String _sortLabel(S l) {
    return _sortMode.localizedDescription(l, descending: _descending);
  }

  int get _alreadyCount => widget.alreadyInCollectionIds.length;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final List<Collection> sorted = _sortedCollections;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Title + sort
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTypography.h3,
                  ),
                ),
                InkWell(
                  onTap: _toggleSort,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          _descending
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          size: 14,
                          color: AppColors.brand,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _sortLabel(l),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.brand,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter field - only if >= 5 collections
          if (widget.collections.length >= 5)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _filterController,
                onChanged: (String v) => setState(() => _filterQuery = v),
                decoration: InputDecoration(
                  hintText: l.collectionPickerFilter,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  suffixIcon: _filterQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            _filterController.clear();
                            setState(() => _filterQuery = '');
                          },
                        )
                      : null,
                ),
              ),
            ),

          const SizedBox(height: 8),

          // List
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: sorted.length + (widget.showUncategorized ? 1 : 0),
              itemBuilder: (BuildContext context, int index) {
                if (widget.showUncategorized && index == 0) {
                  return _buildUncategorizedTile(l);
                }
                final int collectionIndex =
                    widget.showUncategorized ? index - 1 : index;
                final Collection collection = sorted[collectionIndex];
                final bool isAlreadyAdded =
                    widget.alreadyInCollectionIds.contains(collection.id);
                return _buildCollectionTile(collection, isAlreadyAdded, l);
              },
            ),
          ),

          // Divider + Footer
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: <Widget>[
                if (_alreadyCount > 0)
                  Expanded(
                    child: Text(
                      l.collectionPickerAlreadyInCount(_alreadyCount),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.cancel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUncategorizedTile(S l) {
    final bool isAlreadyAdded =
        widget.alreadyInCollectionIds.contains(null);
    final bool customised = widget.uncategorizedLabel != null;
    final String title = widget.uncategorizedLabel ?? l.withoutCollection;
    final String? subtitle = widget.uncategorizedSubtitle ??
        (customised ? null : l.collectionsUncategorized);
    return ListTile(
      enabled: !isAlreadyAdded,
      leading: _buildIconBox(
        widget.uncategorizedIcon ?? Icons.inbox_outlined,
        isAlreadyAdded,
      ),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: isAlreadyAdded ? _buildAlreadyAddedBadge(l) : null,
      onTap: isAlreadyAdded
          ? null
          : () => Navigator.of(context).pop(const WithoutCollection()),
    );
  }

  Widget _buildCollectionTile(
    Collection collection,
    bool isAlreadyAdded,
    S l,
  ) {
    return ListTile(
      enabled: !isAlreadyAdded,
      leading: _buildLeadingIcon(collection, isAlreadyAdded),
      title: Text(collection.name),
      subtitle: Text(collection.author),
      trailing: isAlreadyAdded ? _buildAlreadyAddedBadge(l) : null,
      onTap: isAlreadyAdded
          ? null
          : () => Navigator.of(context).pop(ChosenCollection(collection)),
    );
  }

  Widget _buildAlreadyAddedBadge(S l) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        l.collectionPickerAlreadyAdded,
        style: AppTypography.caption.copyWith(
          color: AppColors.success,
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(Collection? collection, bool disabled) {
    final IconData icon = collection == null
        ? Icons.inbox_outlined
        : collection.type == CollectionType.own
            ? Icons.folder_rounded
            : Icons.fork_right;
    return _buildIconBox(icon, disabled);
  }

  Widget _buildIconBox(IconData icon, bool disabled) {
    final Color color = disabled ? AppColors.textTertiary : AppColors.brand;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
