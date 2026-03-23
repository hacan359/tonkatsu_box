// Диалог копирования коллекции как текста с шаблоном и preview.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/text_export_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Показывает диалог копирования коллекции как текста.
///
/// [items] — элементы коллекции для экспорта.
/// Возвращает `true` если данные были скопированы в буфер обмена.
Future<bool?> showCopyAsTextDialog({
  required BuildContext context,
  required List<CollectionItem> items,
}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) => _CopyAsTextDialog(items: items),
  );
}

class _CopyAsTextDialog extends StatefulWidget {
  const _CopyAsTextDialog({required this.items});

  final List<CollectionItem> items;

  @override
  State<_CopyAsTextDialog> createState() => _CopyAsTextDialogState();
}

class _CopyAsTextDialogState extends State<_CopyAsTextDialog> {
  final TextExportService _service = TextExportService();
  late final TextEditingController _templateController;
  TextExportSortMode _sortMode = TextExportSortMode.current;

  /// Максимальное количество строк в preview.
  static const int _previewMaxLines = 5;

  /// Ключ для сохранения шаблона в SharedPreferences.
  static const String _templatePrefKey = 'text_export_template';

  @override
  void initState() {
    super.initState();
    _templateController = TextEditingController(
      text: TextExportService.defaultTemplate,
    );
    _loadSavedTemplate();
  }

  Future<void> _loadSavedTemplate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_templatePrefKey);
    if (saved != null && saved.isNotEmpty && mounted) {
      _templateController.text = saved;
      setState(() {});
    }
  }

  Future<void> _saveTemplate(String template) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_templatePrefKey, template);
  }

  @override
  void dispose() {
    _templateController.dispose();
    super.dispose();
  }

  List<CollectionItem> get _sortedItems {
    final List<CollectionItem> sorted =
        List<CollectionItem>.of(widget.items);
    switch (_sortMode) {
      case TextExportSortMode.current:
        break;
      case TextExportSortMode.name:
        sorted.sort(
          (CollectionItem a, CollectionItem b) =>
              a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()),
        );
      case TextExportSortMode.rating:
        sorted.sort((CollectionItem a, CollectionItem b) {
          final double ra = a.apiRating ?? 0;
          final double rb = b.apiRating ?? 0;
          return rb.compareTo(ra);
        });
      case TextExportSortMode.year:
        sorted.sort((CollectionItem a, CollectionItem b) {
          final int ya = a.releaseYear ?? 0;
          final int yb = b.releaseYear ?? 0;
          return yb.compareTo(ya);
        });
      case TextExportSortMode.addedDate:
        sorted.sort(
          (CollectionItem a, CollectionItem b) =>
              b.addedAt.compareTo(a.addedAt),
        );
    }
    return sorted;
  }

  String get _preview {
    final String template = _templateController.text;
    if (template.isEmpty) return '';
    final List<CollectionItem> items = _sortedItems;
    final List<CollectionItem> previewItems = items.length > _previewMaxLines
        ? items.sublist(0, _previewMaxLines)
        : items;
    final String result = _service.applyTemplate(template, previewItems);
    if (items.length > _previewMaxLines) {
      return '$result\n…';
    }
    return result;
  }

  void _insertToken(String token) {
    final TextEditingValue value = _templateController.value;
    final int start = value.selection.baseOffset;
    final int end = value.selection.extentOffset;
    final String tokenStr = '{$token}';

    // Если курсор валидный — вставляем в позицию, иначе — в конец
    if (start >= 0 && end >= 0) {
      final String newText =
          value.text.replaceRange(start, end, tokenStr);
      _templateController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: start + tokenStr.length,
        ),
      );
    } else {
      _templateController.text += tokenStr;
      _templateController.selection = TextSelection.collapsed(
        offset: _templateController.text.length,
      );
    }
    setState(() {});
  }

  Future<void> _copy() async {
    final String template = _templateController.text;
    if (template.isEmpty) return;
    final List<CollectionItem> items = _sortedItems;
    final String text = _service.applyTemplate(template, items);
    await Clipboard.setData(ClipboardData(text: text));
    await _saveTemplate(template);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  String _sortModeLabel(S l) {
    switch (_sortMode) {
      case TextExportSortMode.current:
        return l.textExportSortCurrent;
      case TextExportSortMode.name:
        return l.textExportSortName;
      case TextExportSortMode.rating:
        return l.textExportSortRating;
      case TextExportSortMode.year:
        return l.textExportSortYear;
      case TextExportSortMode.addedDate:
        return l.textExportSortAdded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return AlertDialog(
      scrollable: true,
      title: Text(l.copyAsText, style: AppTypography.h3),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Template
            Text(l.textExportTemplate, style: AppTypography.body),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _templateController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: TextExportService.defaultTemplate,
                isDense: true,
                border: OutlineInputBorder(),
              ),
              style: AppTypography.body.copyWith(
                fontFamily: 'monospace',
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Tokens
            Text(
              l.textExportTokens,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: TextExportService.availableTokens
                  .map(
                    (String token) => ActionChip(
                      label: Text(
                        '{$token}',
                        style: AppTypography.caption.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                      onPressed: () => _insertToken(token),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: AppSpacing.md),

            // Sort by — PopupMenuButton вместо DropdownButtonFormField
            Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(l.textExportSortBy, style: AppTypography.body),
                PopupMenuButton<TextExportSortMode>(
                  initialValue: _sortMode,
                  onSelected: (TextExportSortMode mode) {
                    setState(() => _sortMode = mode);
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<TextExportSortMode>>[
                    PopupMenuItem<TextExportSortMode>(
                      value: TextExportSortMode.current,
                      child: Text(l.textExportSortCurrent),
                    ),
                    PopupMenuItem<TextExportSortMode>(
                      value: TextExportSortMode.name,
                      child: Text(l.textExportSortName),
                    ),
                    PopupMenuItem<TextExportSortMode>(
                      value: TextExportSortMode.rating,
                      child: Text(l.textExportSortRating),
                    ),
                    PopupMenuItem<TextExportSortMode>(
                      value: TextExportSortMode.year,
                      child: Text(l.textExportSortYear),
                    ),
                    PopupMenuItem<TextExportSortMode>(
                      value: TextExportSortMode.addedDate,
                      child: Text(l.textExportSortAdded),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.surfaceBorder),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          _sortModeLabel(l),
                          style: AppTypography.body,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Preview
            Text(l.textExportPreview, style: AppTypography.body),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              constraints: const BoxConstraints(
                minHeight: 60,
                maxHeight: 140,
              ),
              child: SingleChildScrollView(
                child: Text(
                  _preview.isNotEmpty
                      ? _preview
                      : l.textExportEmptyTemplate,
                  style: AppTypography.bodySmall.copyWith(
                    fontFamily: 'monospace',
                    color: _preview.isNotEmpty
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
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
          child: Text(l.cancel),
        ),
        FilledButton.icon(
          onPressed: _templateController.text.isNotEmpty
              ? _copy
              : null,
          icon: const Icon(Icons.copy, size: 16),
          label: Text(l.textExportCopy),
        ),
      ],
    );
  }
}
