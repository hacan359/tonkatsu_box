import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/collection_picker_field.dart';
import '../../collections/providers/collections_provider.dart';
import '../../collections/extensions/item_display_name.dart';
import '../providers/mood_grid_picker_session_provider.dart';

/// Result of [showMoodGridItemPicker].
class MoodGridItemPickerResult {
  const MoodGridItemPickerResult({required this.item});

  final CollectionItem item;
}

/// Modal picker over all collection items with filter/search; null when
/// cancelled. State and item cache live in [moodGridPickerSessionProvider].
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
  /// Grid grows in windows of this size as the user scrolls, so a large
  /// library doesn't build (and fetch covers for) thousands of cards at once.
  static const int _pageSize = 60;

  late final TextEditingController _queryController;
  Future<List<CollectionItem>>? _itemsFuture;
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    final MoodGridPickerSession session =
        ref.read(moodGridPickerSessionProvider);
    _queryController = TextEditingController(text: session.query);
    _refreshItems();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _refreshItems({bool resetWindow = true, bool refresh = true}) {
    setState(() {
      if (resetWindow) _visibleCount = _pageSize;
      _itemsFuture = ref
          .read(moodGridPickerSessionProvider.notifier)
          .itemsForCurrentFilter(refresh: refresh);
    });
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    // A landed background refresh re-reads the cache without resetting the
    // scroll window; refresh: false breaks the reload→revision cycle.
    ref.listen(moodGridPickerSessionProvider,
        (MoodGridPickerSession? prev, MoodGridPickerSession next) {
      if (prev != null && prev.revision != next.revision) {
        _refreshItems(resetWindow: false, refresh: false);
      }
    });
    final MoodGridPickerSession session =
        ref.watch(moodGridPickerSessionProvider);
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
                    l.moodGridPickItem,
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
              data: (List<Collection> collections) => CollectionPickerField(
                value: session.collectionId,
                hint: l.collection,
                title: l.collection,
                nullLabel: l.moodGridPickerAllCollections,
                leadingIcon: Icons.folder_open_outlined,
                onChanged: (int? id) {
                  ref
                      .read(moodGridPickerSessionProvider.notifier)
                      .setCollection(id);
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
              onChanged: (String value) {
                ref
                    .read(moodGridPickerSessionProvider.notifier)
                    .setQuery(value);
                setState(() => _visibleCount = _pageSize);
              },
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
                    session.query.trim(),
                  );
                  if (items.isEmpty) {
                    return Center(child: Text(l.moodGridPickerEmpty));
                  }
                  final int visible = _visibleCount < items.length
                      ? _visibleCount
                      : items.length;
                  return NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification n) {
                      if (n.metrics.extentAfter < 400 &&
                          _visibleCount < items.length) {
                        setState(() => _visibleCount += _pageSize);
                      }
                      return false;
                    },
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 120,
                        mainAxisSpacing: AppSpacing.sm,
                        crossAxisSpacing: AppSpacing.sm,
                        // 2:3 poster + two bodySmall lines: 0.62 left ~10px
                        // for text and clipped it to half a line.
                        childAspectRatio: 0.51,
                      ),
                      itemCount: visible,
                      itemBuilder: (BuildContext c, int i) {
                        final CollectionItem item = items[i];
                        return _PickerItemCard(
                          item: item,
                          onTap: () => Navigator.of(context).pop(
                            MoodGridItemPickerResult(item: item),
                          ),
                        );
                      },
                    ),
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
            ref.currentDisplayNameOf(it).toLowerCase().contains(lowered))
        .toList();
  }
}

class _PickerItemCard extends ConsumerWidget {
  const _PickerItemCard({required this.item, required this.onTap});

  final CollectionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      imageId: item.coverImageId,
                      remoteUrl: url,
                      fit: BoxFit.cover,
                      memCacheWidth: 240,
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              ref.displayNameOf(item),
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
