import 'dart:async';

import 'package:core/models/collection_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_service.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'cached_image.dart';
import 'source_badge.dart';
import '../constants/collection_item_ui.dart';

/// Opens the card picker and returns the chosen item, or `null` if dismissed.
Future<CollectionItem?> showCardLinkPicker(
  BuildContext context,
  WidgetRef ref,
) {
  return showModalBottomSheet<CollectionItem>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) => _CardLinkPickerSheet(ref: ref),
  );
}

class _CardLinkPickerSheet extends StatefulWidget {
  const _CardLinkPickerSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_CardLinkPickerSheet> createState() => _CardLinkPickerSheetState();
}

class _CardLinkPickerSheetState extends State<_CardLinkPickerSheet> {
  static const int _maxResults = 50;
  static const Duration _debounceDelay = Duration(milliseconds: 250);

  final TextEditingController _query = TextEditingController();
  List<CollectionItem> _all = <CollectionItem>[];
  // Lowercased names aligned with [_all], computed once instead of on
  // every keystroke over the whole library.
  List<String> _namesLower = <String>[];
  List<CollectionItem> _results = <CollectionItem>[];
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _query.addListener(_onQueryChanged);
    _load();
  }

  Future<void> _load() async {
    final DatabaseService db = widget.ref.read(databaseServiceProvider);
    final List<CollectionItem> items = await db.getAllCollectionItemsWithData();
    if (mounted) {
      setState(() {
        _all = items;
        _namesLower = <String>[
          for (final CollectionItem item in items) item.itemName.toLowerCase(),
        ];
        _loading = false;
      });
      _applyFilter();
    }
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, _applyFilter);
  }

  void _applyFilter() {
    if (!mounted) return;
    final String q = _query.text.trim().toLowerCase();
    final List<CollectionItem> results = <CollectionItem>[];
    if (q.isNotEmpty) {
      for (int i = 0;
          i < _all.length && results.length < _maxResults;
          i++) {
        if (_namesLower[i].contains(q)) results.add(_all[i]);
      }
    }
    setState(() => _results = results);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final List<CollectionItem> items = _results;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(l.cardLinkSearchTitle, style: AppTypography.h3),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                controller: _query,
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l.cardLinkSearchHint,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _query.text.trim().isEmpty
                      ? Center(
                          child: Text(
                            l.cardLinkSearchHint,
                            style: AppTypography.body
                                .copyWith(color: AppColors.textTertiary),
                          ),
                        )
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (BuildContext context, int index) =>
                              _CardLinkPickerTile(
                            item: items[index],
                            onTap: () => Navigator.of(context).pop(items[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardLinkPickerTile extends StatelessWidget {
  const _CardLinkPickerTile({required this.item, required this.onTap});

  final CollectionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final int? year = item.releaseYear;
    final String? subcategory = item.cardSubcategoryLabel(l);
    final String subtitle = <String>[
      item.dataSource.label,
      if (year != null) '$year',
      ?subcategory,
    ].join(' · ');

    return ListTile(
      leading: SizedBox(
        width: 32,
        height: 46,
        child: item.coverImageId.isEmpty
            ? Icon(item.placeholderIcon, color: AppColors.textTertiary)
            : ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: CachedImage(
                  imageType: item.imageType,
                  imageId: item.coverImageId,
                  remoteUrl: item.thumbnailUrl ?? item.coverUrl ?? '',
                  fit: BoxFit.cover,
                  memCacheHeight: 92,
                ),
              ),
      ),
      title: Text(item.itemName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Row(
        children: <Widget>[
          SourceBadge(source: item.dataSource, size: SourceBadgeSize.small),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
      trailing: Icon(item.placeholderIcon, size: 16),
      onTap: onTap,
    );
  }
}
