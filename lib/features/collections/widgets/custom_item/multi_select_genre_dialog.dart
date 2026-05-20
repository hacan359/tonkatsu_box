import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';

/// Multi-select dialog with search box for genres (or other tag-style
/// strings). Returns the picked set, or `null` if the user cancels.
class MultiSelectGenreDialog extends StatefulWidget {
  const MultiSelectGenreDialog({
    required this.title,
    required this.items,
    required this.selected,
    super.key,
  });

  final String title;
  final List<String> items;
  final Set<String> selected;

  static Future<Set<String>?> show(
    BuildContext context, {
    required String title,
    required List<String> items,
    required Set<String> selected,
  }) {
    return showDialog<Set<String>>(
      context: context,
      builder: (BuildContext ctx) => MultiSelectGenreDialog(
        title: title,
        items: items,
        selected: selected,
      ),
    );
  }

  @override
  State<MultiSelectGenreDialog> createState() =>
      _MultiSelectGenreDialogState();
}

class _MultiSelectGenreDialogState extends State<MultiSelectGenreDialog> {
  final TextEditingController _searchController = TextEditingController();
  late final Set<String> _selected;
  List<String> _filtered = <String>[];

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.of(widget.selected);
    _filtered = widget.items;
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
                    final bool isSelected = _selected.contains(item);
                    return CheckboxListTile(
                      title: Text(item, style: AppTypography.bodySmall),
                      value: isSelected,
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selected.add(item);
                          } else {
                            _selected.remove(item);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
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
                        setState(() => _selected.add(text));
                        _searchController.clear();
                        _filter('');
                      }
                    },
                    child: Text(l.customItemUseCustom),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_selected),
                    child: Text(l.confirm),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
