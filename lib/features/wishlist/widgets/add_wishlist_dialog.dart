import 'package:flutter/material.dart';

import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/wishlist_item.dart';
import '../../../shared/theme/app_spacing.dart';

// Диалог добавления/редактирования элемента вишлиста.

/// Результат диалога вишлиста.
class WishlistDialogResult {
  /// Создаёт экземпляр [WishlistDialogResult].
  const WishlistDialogResult({
    required this.text,
    this.mediaTypeHint,
    this.note,
  });

  /// Текст заметки (название контента).
  final String text;

  /// Опциональный тип медиа.
  final MediaType? mediaTypeHint;

  /// Дополнительная заметка.
  final String? note;
}

/// Диалог для добавления или редактирования элемента вишлиста.
///
/// Возвращает [WishlistDialogResult] или `null` при отмене.
class AddWishlistDialog extends StatefulWidget {
  /// Создаёт [AddWishlistDialog].
  const AddWishlistDialog({
    this.existing,
    super.key,
  });

  /// Существующий элемент (для режима редактирования).
  final WishlistItem? existing;

  /// Показывает диалог и возвращает результат.
  static Future<WishlistDialogResult?> show(
    BuildContext context, {
    WishlistItem? existing,
  }) {
    return showDialog<WishlistDialogResult>(
      context: context,
      builder: (BuildContext context) {
        return AddWishlistDialog(existing: existing);
      },
    );
  }

  @override
  State<AddWishlistDialog> createState() => _AddWishlistDialogState();
}

class _AddWishlistDialogState extends State<AddWishlistDialog> {
  late final TextEditingController _textController;
  late final TextEditingController _noteController;
  MediaType? _selectedMediaType;
  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.existing?.text ?? '',
    );
    _noteController = TextEditingController(
      text: widget.existing?.note ?? '',
    );
    _selectedMediaType = widget.existing?.mediaTypeHint;
  }

  @override
  void dispose() {
    _textController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final String text = _textController.text.trim();
    if (text.isEmpty) return;

    final String noteText = _noteController.text.trim();
    Navigator.of(context).pop(
      WishlistDialogResult(
        text: text,
        mediaTypeHint: _selectedMediaType,
        note: noteText.isEmpty ? null : noteText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(_isEditing ? 'Edit Wishlist Item' : 'Add to Wishlist'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _textController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Game, movie, or TV show name...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Type (optional)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: <Widget>[
                _buildMediaTypeChip(null, 'Any', Icons.bookmark_border),
                ...MediaType.values.map(
                  (MediaType type) => _buildMediaTypeChip(
                    type,
                    type.displayLabel,
                    MediaTypeTheme.iconFor(type),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _noteController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Platform, year, who recommended...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  Widget _buildMediaTypeChip(
    MediaType? type,
    String label,
    IconData icon,
  ) {
    final bool isSelected = _selectedMediaType == type;
    final Color? chipColor =
        type != null ? MediaTypeTheme.colorFor(type) : null;

    return ChoiceChip(
      label: Text(label),
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? chipColor : null,
      ),
      selected: isSelected,
      selectedColor: chipColor?.withValues(alpha: 0.2),
      onSelected: (bool selected) {
        setState(() {
          _selectedMediaType = selected ? type : null;
        });
      },
    );
  }
}
