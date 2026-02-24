import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/wishlist_item.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/breadcrumb_scope.dart';

// Экран-форма для добавления/редактирования элемента вишлиста.

/// Результат формы вишлиста.
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

/// Экран-форма для добавления или редактирования элемента вишлиста.
///
/// Открывается как полноценная страница через [Navigator.push].
/// Возвращает [WishlistDialogResult] или `null` при отмене (back).
class AddWishlistForm extends StatefulWidget {
  /// Создаёт [AddWishlistForm].
  const AddWishlistForm({
    this.existing,
    super.key,
  });

  /// Существующий элемент (для режима редактирования).
  final WishlistItem? existing;

  /// Открывает экран формы и возвращает результат.
  static Future<WishlistDialogResult?> show(
    BuildContext context, {
    WishlistItem? existing,
  }) {
    final S l = S.of(context);
    final bool isEditing = existing != null;
    return Navigator.of(context).push<WishlistDialogResult>(
      MaterialPageRoute<WishlistDialogResult>(
        builder: (BuildContext context) => BreadcrumbScope(
          label: isEditing ? l.wishlistEditTitle : l.wishlistAddTitle,
          child: AddWishlistForm(existing: existing),
        ),
      ),
    );
  }

  @override
  State<AddWishlistForm> createState() => _AddWishlistFormState();
}

class _AddWishlistFormState extends State<AddWishlistForm> {
  late final TextEditingController _textController;
  late final TextEditingController _noteController;
  MediaType? _selectedMediaType;
  String? _titleError;
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
    if (text.length < 2) {
      setState(() {
        _titleError = S.of(context).wishlistTitleMinChars;
      });
      return;
    }

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
    final S l = S.of(context);

    return Scaffold(
      appBar: AutoBreadcrumbAppBar(
        actions: <Widget>[
          TextButton(
            onPressed: _submit,
            child: Text(_isEditing ? l.save : l.add),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Title field.
            TextField(
              controller: _textController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.wishlistTitleLabel,
                hintText: l.wishlistTitleHint,
                border: const OutlineInputBorder(),
                errorText: _titleError,
              ),
              onChanged: (_) {
                if (_titleError != null) {
                  setState(() {
                    _titleError = null;
                  });
                }
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Media type chips.
            Text(
              l.wishlistTypeOptional,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                _buildMediaTypeChip(null, l.wishlistTypeAny, Icons.collections_bookmark_outlined),
                ...MediaType.values.map(
                  (MediaType type) => _buildMediaTypeChip(
                    type,
                    type.localizedLabel(l),
                    MediaTypeTheme.iconFor(type),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Note field.
            TextField(
              controller: _noteController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.wishlistNoteOptional,
                hintText: l.wishlistNoteHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
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
      showCheckmark: false,
      selectedColor: chipColor?.withValues(alpha: 0.2),
      onSelected: (bool selected) {
        setState(() {
          _selectedMediaType = selected ? type : null;
        });
      },
    );
  }
}
