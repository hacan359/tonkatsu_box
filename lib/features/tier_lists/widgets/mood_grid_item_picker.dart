import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../collections/providers/collections_provider.dart';

/// Result of [showMoodGridItemPicker].
class MoodGridItemPickerResult {
  /// Creates a [MoodGridItemPickerResult].
  const MoodGridItemPickerResult({required this.item});

  /// The picked collection item.
  final CollectionItem item;
}

/// Opens a modal picker that lists all items across all collections with
/// optional collection / search filtering. Returns null if cancelled.
Future<MoodGridItemPickerResult?> showMoodGridItemPicker(
  BuildContext context,
) {
  return showModalBottomSheet<MoodGridItemPickerResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext ctx) => const _MoodGridItemPicker(),
  );
}

class _MoodGridItemPicker extends ConsumerStatefulWidget {
  const _MoodGridItemPicker();

  @override
  ConsumerState<_MoodGridItemPicker> createState() =>
      _MoodGridItemPickerState();
}

class _MoodGridItemPickerState extends ConsumerState<_MoodGridItemPicker> {
  final TextEditingController _queryController = TextEditingController();
  int? _filterCollectionId; // null = all collections
  Future<List<CollectionItem>>? _itemsFuture;

  @override
  void initState() {
    super.initState();
    _refreshItems();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _refreshItems() {
    final DatabaseService db = ref.read(databaseServiceProvider);
    setState(() {
      _itemsFuture = _filterCollectionId == null
          ? db.getAllCollectionItemsWithData()
          : db.getCollectionItemsWithData(_filterCollectionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final AsyncValue<List<Collection>> collectionsAsync =
        ref.watch(collectionsProvider);
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.8;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l.moodGridPickerTitle,
                    style: AppTypography.h3,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            collectionsAsync.when(
              data: (List<Collection> collections) =>
                  DropdownButtonFormField<int?>(
                initialValue: _filterCollectionId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l.moodGridPickerCollection,
                ),
                items: <DropdownMenuItem<int?>>[
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(l.moodGridPickerAllCollections),
                  ),
                  ...collections.map(
                    (Collection c) => DropdownMenuItem<int?>(
                      value: c.id,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (int? value) {
                  _filterCollectionId = value;
                  _refreshItems();
                },
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace s) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.moodGridPickerSearchHint,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: FutureBuilder<List<CollectionItem>>(
                future: _itemsFuture,
                builder: (BuildContext ctx,
                    AsyncSnapshot<List<CollectionItem>> snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final List<CollectionItem> items = _filterItems(
                    snap.data ?? <CollectionItem>[],
                    _queryController.text.trim(),
                  );
                  if (items.isEmpty) {
                    return Center(child: Text(l.moodGridPickerEmpty));
                  }
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 120,
                      mainAxisSpacing: AppSpacing.sm,
                      crossAxisSpacing: AppSpacing.sm,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: items.length,
                    itemBuilder: (BuildContext c, int i) {
                      final CollectionItem item = items[i];
                      return _PickerItemCard(
                        item: item,
                        onTap: () => Navigator.of(context).pop(
                          MoodGridItemPickerResult(item: item),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<CollectionItem> _filterItems(List<CollectionItem> all, String query) {
    if (query.isEmpty) return all;
    final String lowered = query.toLowerCase();
    return all
        .where((CollectionItem it) =>
            it.itemName.toLowerCase().contains(lowered))
        .toList();
  }
}

class _PickerItemCard extends StatelessWidget {
  const _PickerItemCard({required this.item, required this.onTap});

  final CollectionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String? url = item.thumbnailUrl;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Column(
        children: <Widget>[
          AspectRatio(
            aspectRatio: 2 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: url == null
                  ? Container(color: AppColors.surfaceLight)
                  : CachedImage(
                      imageType: item.imageType,
                      imageId: item.externalId.toString(),
                      remoteUrl: url,
                      fit: BoxFit.cover,
                      memCacheWidth: 240,
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              item.itemName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
