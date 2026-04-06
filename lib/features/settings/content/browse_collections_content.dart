// UI для каталога онлайн-коллекций: фильтры, список, скачивание.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/collection_browser_service.dart';
import '../../../core/services/import_service.dart';
import '../../../core/services/xcoll_file.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../collections/models/collections_index.dart';
import '../../collections/providers/canvas_provider.dart';
import '../../collections/providers/collection_browser_provider.dart';
import '../../collections/providers/collection_covers_provider.dart';
import '../../collections/providers/collections_provider.dart';
import '../../home/providers/all_items_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';

/// Контент экрана каталога онлайн-коллекций.
class BrowseCollectionsContent extends ConsumerStatefulWidget {
  /// Создаёт [BrowseCollectionsContent].
  const BrowseCollectionsContent({super.key});

  /// Обновляет индекс коллекций (вызывается из AppBar).
  static void refresh(BuildContext context) {
    final ProviderContainer container = ProviderScope.containerOf(context);
    container.read(collectionsIndexProvider.notifier).refresh();
  }

  @override
  ConsumerState<BrowseCollectionsContent> createState() =>
      _BrowseCollectionsContentState();
}

class _BrowseCollectionsContentState
    extends ConsumerState<BrowseCollectionsContent> {
  final Set<String> _downloadingIds = <String>{};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final AsyncValue<CollectionsIndex> indexAsync =
        ref.watch(collectionsIndexProvider);

    return indexAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) => _buildError(l, error),
      data: (CollectionsIndex index) => _buildBody(l, index),
    );
  }

  Widget _buildError(S l, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.browseCollectionsLoadError,
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(collectionsIndexProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: Text(l.browseCollectionsRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(S l, CollectionsIndex index) {
    final List<RemoteCollection> collections =
        ref.watch(filteredRemoteCollectionsProvider);

    return Column(
      children: <Widget>[
        // Summary
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: Text(
            l.browseCollectionsSummary(
              index.totalCollections,
              index.totalItems,
            ),
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l.browseCollectionsSearch,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(browserSearchQueryProvider.notifier).state =
                            '';
                      },
                    )
                  : null,
              isDense: true,
            ),
            onChanged: (String value) {
              ref.read(browserSearchQueryProvider.notifier).state = value;
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Filters row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: <Widget>[
              _FilterButton(
                label: _platformLabel(l, index),
                isActive: ref.watch(browserPlatformFilterProvider) != null,
                onTap: () => _showPlatformPicker(l, index),
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterButton(
                label: _categoryLabel(l, index),
                isActive: ref.watch(browserCategoryFilterProvider) != null,
                onTap: () => _showCategoryPicker(l, index),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Collection list
        Expanded(
          child: collections.isEmpty
              ? Center(
                  child: Text(
                    l.browseCollectionsEmpty,
                    style: AppTypography.body
                        .copyWith(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  itemCount: collections.length,
                  itemBuilder: (BuildContext context, int i) =>
                      _buildCollectionTile(l, collections[i]),
                ),
        ),
      ],
    );
  }

  String _platformLabel(S l, CollectionsIndex index) {
    final String? selected = ref.watch(browserPlatformFilterProvider);
    if (selected == null) return l.browseCollectionsAllPlatforms;
    for (final RemotePlatform p in index.platforms) {
      if (p.id == selected) return p.shortName;
    }
    for (final RemoteMediaType m in index.mediaTypes) {
      if (m.id == selected) return m.shortName;
    }
    return selected;
  }

  String _categoryLabel(S l, CollectionsIndex index) {
    final String? selected = ref.watch(browserCategoryFilterProvider);
    if (selected == null) return l.browseCollectionsAllCategories;
    for (final CollectionCategory c in index.categories) {
      if (c.id == selected) return c.name;
    }
    return selected;
  }

  Future<void> _showPlatformPicker(S l, CollectionsIndex index) async {
    final List<_PickerItem> items = <_PickerItem>[
      ...index.platforms.map(
        (RemotePlatform p) => _PickerItem(
          id: p.id,
          label: '${p.shortName} — ${p.name}',
        ),
      ),
      ...index.mediaTypes.map(
        (RemoteMediaType m) => _PickerItem(id: m.id, label: m.name),
      ),
    ];

    final String? result = await _showSearchablePicker(
      title: l.browseCollectionsAllPlatforms,
      items: items,
      current: ref.read(browserPlatformFilterProvider),
    );

    if (!mounted) return;
    ref.read(browserPlatformFilterProvider.notifier).state = result;
  }

  Future<void> _showCategoryPicker(S l, CollectionsIndex index) async {
    final List<_PickerItem> items = index.categories
        .map(
          (CollectionCategory c) => _PickerItem(id: c.id, label: c.name),
        )
        .toList();

    final String? result = await _showSearchablePicker(
      title: l.browseCollectionsAllCategories,
      items: items,
      current: ref.read(browserCategoryFilterProvider),
    );

    if (!mounted) return;
    ref.read(browserCategoryFilterProvider.notifier).state = result;
  }

  /// Показывает диалог с поиском для выбора одного значения.
  ///
  /// Возвращает выбранный id или null (сброс).
  Future<String?> _showSearchablePicker({
    required String title,
    required List<_PickerItem> items,
    required String? current,
  }) async {
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _SearchablePickerDialog(
        title: title,
        items: items,
        currentId: current,
      ),
    );
    if (result == null) return current; // Dialog dismissed — keep current
    if (result == _resetSentinel) return null; // "All" selected — reset
    return result;
  }

  Widget _buildCollectionTile(S l, RemoteCollection collection) {
    final bool isDownloading = _downloadingIds.contains(collection.id);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text(collection.name, style: AppTypography.body),
        subtitle: Text(
          <String>[
            if (collection.platformName != null) collection.platformName!,
            l.browseCollectionsItems(collection.itemsCount),
            collection.sizeFormatted,
            collection.isFull
                ? l.browseCollectionsFormatFull
                : l.browseCollectionsFormatLight,
          ].join(' · '),
          style: AppTypography.bodySmall
              .copyWith(color: AppColors.textSecondary),
        ),
        trailing: isDownloading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => _download(l, collection),
              ),
      ),
    );
  }

  Future<void> _download(S l, RemoteCollection collection) async {
    if (_downloadingIds.contains(collection.id)) return;

    // Показываем диалог выбора целевой коллекции.
    final _ImportTarget? target = await showDialog<_ImportTarget>(
      context: context,
      builder: (BuildContext context) => _ImportTargetDialog(
        collectionName: collection.name,
      ),
    );
    if (target == null || !mounted) return;

    setState(() => _downloadingIds.add(collection.id));

    try {
      final CollectionBrowserService service =
          ref.read(collectionBrowserServiceProvider);
      final XcollFile xcoll = await service.downloadCollection(collection);

      if (!mounted) return;

      final ImportService importService = ref.read(importServiceProvider);
      final ImportResult result = await importService.importFromXcoll(
        xcoll,
        collectionId: target.collectionId,
      );

      if (!mounted) return;

      if (result.success && result.collection != null) {
        final int cid = result.collection!.id;
        ref.invalidate(collectionsProvider);
        ref.invalidate(collectionStatsProvider(cid));
        ref.invalidate(collectionCoversProvider(cid));
        ref.invalidate(collectionItemsNotifierProvider(cid));
        ref.invalidate(canvasNotifierProvider(cid));
        ref.invalidate(allItemsNotifierProvider);
        ref.invalidate(wishlistProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l.browseCollectionsImportSuccess(collection.name),
            ),
          ),
        );
      } else if (result.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l.browseCollectionsDownloadError(result.error!),
            ),
          ),
        );
      }
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.browseCollectionsDownloadError(e.toString())),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _downloadingIds.remove(collection.id));
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Вспомогательные виджеты
// ---------------------------------------------------------------------------

/// Результат выбора целевой коллекции для импорта.
class _ImportTarget {
  const _ImportTarget({this.collectionId});

  /// null — создать новую коллекцию, иначе ID существующей.
  final int? collectionId;
}

/// Диалог выбора: создать новую коллекцию или импортировать в существующую.
class _ImportTargetDialog extends ConsumerStatefulWidget {
  const _ImportTargetDialog({required this.collectionName});

  final String collectionName;

  @override
  ConsumerState<_ImportTargetDialog> createState() =>
      _ImportTargetDialogState();
}

class _ImportTargetDialogState extends ConsumerState<_ImportTargetDialog> {
  bool _useNew = true;
  int? _selectedId;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final AsyncValue<List<Collection>> collectionsAsync =
        ref.watch(collectionsProvider);

    return AlertDialog(
      title: Text(widget.collectionName, style: AppTypography.h3),
      contentPadding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: 0,
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                l.browseCollectionsImportTarget,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            RadioGroup<bool>(
              groupValue: _useNew,
              onChanged: (bool? value) {
                if (value == null) return;
                setState(() {
                  _useNew = value;
                  if (value) _selectedId = null;
                });
              },
              child: Column(
                children: <Widget>[
                  RadioListTile<bool>(
                    title: Text(l.browseCollectionsNewCollection),
                    value: true,
                    dense: true,
                  ),
                  RadioListTile<bool>(
                    title: Text(l.browseCollectionsExistingCollection),
                    value: false,
                    dense: true,
                  ),
                ],
              ),
            ),
            if (!_useNew)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                child: collectionsAsync.when(
                  data: (List<Collection> collections) {
                    if (collections.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          l.browseCollectionsNoCollections,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }
                    final bool selectedExists = _selectedId != null &&
                        collections.any(
                          (Collection c) => c.id == _selectedId,
                        );
                    return DropdownButtonFormField<int>(
                      initialValue: selectedExists ? _selectedId : null,
                      hint: Text(l.browseCollectionsSelectCollection),
                      isExpanded: true,
                      items: collections.map((Collection c) {
                        return DropdownMenuItem<int>(
                          value: c.id,
                          child:
                              Text(c.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (int? value) {
                        setState(() => _selectedId = value);
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (Object e, StackTrace _) => Text(
                    e.toString(),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.statusDropped,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _useNew || _selectedId != null
              ? () => Navigator.of(context).pop(
                    _ImportTarget(
                      collectionId: _useNew ? null : _selectedId,
                    ),
                  )
              : null,
          child: Text(l.importStartButton),
        ),
      ],
    );
  }
}

/// Sentinel для сброса фильтра (отличает "All" от закрытия диалога).
const String _resetSentinel = '__browse_reset__';

/// Кнопка-дропдаун для фильтра.
class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.brand.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: isActive ? AppColors.brand : AppColors.surfaceBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: AppTypography.body.copyWith(
                color: isActive ? AppColors.brand : AppColors.textTertiary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: isActive ? AppColors.brand : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Элемент для searchable picker.
class _PickerItem {
  const _PickerItem({required this.id, required this.label});

  final String id;
  final String label;
}

/// Диалог с полем поиска для выбора платформы/категории.
class _SearchablePickerDialog extends StatefulWidget {
  const _SearchablePickerDialog({
    required this.title,
    required this.items,
    required this.currentId,
  });

  final String title;
  final List<_PickerItem> items;
  final String? currentId;

  @override
  State<_SearchablePickerDialog> createState() =>
      _SearchablePickerDialogState();
}

class _SearchablePickerDialogState extends State<_SearchablePickerDialog> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_PickerItem> get _filtered {
    if (_query.isEmpty) return widget.items;
    final String lower = _query.toLowerCase();
    return widget.items
        .where((_PickerItem item) => item.label.toLowerCase().contains(lower))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<_PickerItem> filtered = _filtered;

    return AlertDialog(
      title: Text(widget.title, style: AppTypography.h3),
      contentPadding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      content: SizedBox(
        width: 300,
        height: 400,
        child: Column(
          children: <Widget>[
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.title,
                    hintStyle: AppTypography.body.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.textTertiary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            onPressed: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (String value) =>
                      setState(() => _query = value),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Options list
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                // +1 for "All" option when no search query
                itemCount:
                    _query.isEmpty ? filtered.length + 1 : filtered.length,
                itemBuilder: (BuildContext context, int index) {
                  // "All" option — reset via sentinel
                  if (_query.isEmpty && index == 0) {
                    return _buildOption(
                      label: widget.title,
                      isSelected: widget.currentId == null,
                      onTap: () =>
                          Navigator.of(context).pop(_resetSentinel),
                    );
                  }

                  final int itemIndex =
                      _query.isEmpty ? index - 1 : index;
                  final _PickerItem item = filtered[itemIndex];
                  return _buildOption(
                    label: item.label,
                    isSelected: item.id == widget.currentId,
                    onTap: () => Navigator.of(context).pop(item.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          label,
          style: AppTypography.body.copyWith(
            color: isSelected ? AppColors.brand : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
