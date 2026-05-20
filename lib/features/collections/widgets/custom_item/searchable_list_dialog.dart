import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';

/// Searchable single-select dialog returning the picked string (or the
/// typed custom value when [allowCustom] is true and the user taps
/// "use custom").
class SearchableListDialog extends StatefulWidget {
  const SearchableListDialog({
    required this.title,
    required this.items,
    required this.allowCustom,
    this.currentValue,
    super.key,
  });

  final String title;
  final List<String> items;
  final bool allowCustom;
  final String? currentValue;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required List<String> items,
    required bool allowCustom,
    String? currentValue,
  }) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => SearchableListDialog(
        title: title,
        items: items,
        allowCustom: allowCustom,
        currentValue: currentValue,
      ),
    );
  }

  @override
  State<SearchableListDialog> createState() => _SearchableListDialogState();
}

class _SearchableListDialogState extends State<SearchableListDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filtered = <String>[];

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    if (widget.currentValue != null) {
      _searchController.text = widget.currentValue!;
      _filter(widget.currentValue!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    if (query.isEmpty) {
      _filtered = widget.items;
    } else {
      final String lower = query.toLowerCase();
      _filtered = widget.items
          .where((String item) => item.toLowerCase().contains(lower))
          .toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(widget.title,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l.customItemSearchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                ),
                onChanged: _filter,
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filtered.length,
                  itemBuilder: (BuildContext ctx, int index) {
                    final String item = _filtered[index];
                    return ListTile(
                      title: Text(item, style: AppTypography.bodySmall),
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      onTap: () => Navigator.of(ctx).pop(item),
                    );
                  },
                ),
              ),
              if (widget.allowCustom) ...<Widget>[
                const Divider(),
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  spacing: AppSpacing.sm,
                  children: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l.cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        final String text = _searchController.text.trim();
                        if (text.isNotEmpty) {
                          Navigator.of(context).pop(text);
                        }
                      },
                      child: Text(l.customItemUseCustom),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
