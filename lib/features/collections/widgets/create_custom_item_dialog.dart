// Прототип диалога создания кастомного элемента коллекции.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Результат диалога создания кастомного элемента (прототип).
class CustomItemData {
  /// Создаёт экземпляр [CustomItemData].
  const CustomItemData({
    required this.title,
    required this.mediaType,
    this.altTitle,
    this.description,
    this.year,
    this.coverUrl,
    this.genres,
    this.platform,
  });

  /// Основное название.
  final String title;

  /// Альтернативное название (оригинальный язык).
  final String? altTitle;

  /// Тип медиа.
  final MediaType mediaType;

  /// Описание.
  final String? description;

  /// Год выпуска.
  final int? year;

  /// URL обложки.
  final String? coverUrl;

  /// Жанры (через запятую).
  final String? genres;

  /// Платформа (для игр).
  final String? platform;
}

/// Диалог создания кастомного элемента коллекции (прототип).
///
/// Макет повторяет layout карточки деталей (MediaDetailView):
/// постер слева, метаданные справа, секции ниже.
class CreateCustomItemDialog extends StatefulWidget {
  /// Создаёт [CreateCustomItemDialog].
  const CreateCustomItemDialog({super.key});

  /// Открывает полноэкранную форму создания кастомного элемента.
  static Future<CustomItemData?> show(BuildContext context) {
    return Navigator.of(context).push<CustomItemData>(
      MaterialPageRoute<CustomItemData>(
        builder: (BuildContext context) => const CreateCustomItemDialog(),
      ),
    );
  }

  @override
  State<CreateCustomItemDialog> createState() =>
      _CreateCustomItemDialogState();
}

class _CreateCustomItemDialogState extends State<CreateCustomItemDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _altTitleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _coverUrlController = TextEditingController();
  final TextEditingController _genresController = TextEditingController();
  final TextEditingController _platformController = TextEditingController();

  MediaType _selectedType = MediaType.game;
  String? _titleError;
  int? _userRating;

  @override
  void dispose() {
    _titleController.dispose();
    _altTitleController.dispose();
    _descriptionController.dispose();
    _yearController.dispose();
    _coverUrlController.dispose();
    _genresController.dispose();
    _platformController.dispose();
    super.dispose();
  }

  void _submit() {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = S.of(context).customItemErrorEmptyTitle);
      return;
    }

    final String yearText = _yearController.text.trim();
    final int? year = yearText.isNotEmpty ? int.tryParse(yearText) : null;

    Navigator.of(context).pop(CustomItemData(
      title: title,
      mediaType: _selectedType,
      altTitle: _altTitleController.text.trim().isNotEmpty
          ? _altTitleController.text.trim()
          : null,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      year: year,
      coverUrl: _coverUrlController.text.trim().isNotEmpty
          ? _coverUrlController.text.trim()
          : null,
      genres: _genresController.text.trim().isNotEmpty
          ? _genresController.text.trim()
          : null,
      platform: _platformController.text.trim().isNotEmpty
          ? _platformController.text.trim()
          : null,
    ));
  }

  Color get _accentColor => MediaTypeTheme.colorFor(_selectedType);

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        title: Text(l.customItemCreate, style: AppTypography.h2),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              onPressed: _submit,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brand,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: Text(l.customItemCreateButton),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          // === HEADER: обложка + мета (как MediaDetailView) ===
          _buildHeader(l),
          const SizedBox(height: AppSpacing.md),

          // === Тип медиа ===
          _buildMediaTypeChips(l),
          const SizedBox(height: AppSpacing.md),

          // === Рейтинг ===
          _buildRatingSection(l),

          // === Разделитель ===
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(
              color: AppColors.surfaceBorder.withAlpha(80),
              height: 1,
            ),
          ),

          // === Описание ===
          _buildDescriptionSection(l),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  /// Шапка: постер-плейсхолдер + название/год/жанры/платформа.
  Widget _buildHeader(S l) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Обложка (100×150, как в MediaDetailView)
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Container(
            width: 100,
            height: 150,
            color: AppColors.surfaceLight,
            child: _coverUrlController.text.trim().isNotEmpty
                ? Image.network(
                    _coverUrlController.text.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, Object e, StackTrace? s) =>
                        _buildCoverPlaceholder(),
                  )
                : _buildCoverPlaceholder(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),

        // Мета-поля
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Бейдж типа
              Row(
                children: <Widget>[
                  Icon(
                    MediaTypeTheme.iconFor(_selectedType),
                    size: 16,
                    color: _accentColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _selectedType.localizedLabel(S.of(context)),
                    style: AppTypography.bodySmall.copyWith(
                      color: _accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Название
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: l.customItemTitleHint,
                  errorText: _titleError,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: AppTypography.h2,
                onChanged: (_) {
                  if (_titleError != null) {
                    setState(() => _titleError = null);
                  }
                },
              ),

              // Альтернативное название
              TextField(
                controller: _altTitleController,
                decoration: InputDecoration(
                  hintText: l.customItemAltTitleHint,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Чипы: год, жанры, платформа
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: <Widget>[
                  // Год
                  _buildEditableChip(
                    icon: Icons.calendar_today,
                    controller: _yearController,
                    hint: l.customItemYear,
                    width: 60,
                    keyboardType: TextInputType.number,
                  ),
                  // Жанры
                  _buildEditableChip(
                    icon: Icons.category_outlined,
                    controller: _genresController,
                    hint: l.customItemGenres,
                    width: 140,
                  ),
                  // Платформа (только для игр)
                  if (_selectedType == MediaType.game)
                    _buildEditableChip(
                      icon: Icons.sports_esports,
                      controller: _platformController,
                      hint: l.customItemPlatform,
                      width: 100,
                    ),
                  // URL обложки
                  _buildEditableChip(
                    icon: Icons.image_outlined,
                    controller: _coverUrlController,
                    hint: 'Cover URL',
                    width: 140,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoverPlaceholder() {
    return Center(
      child: Icon(
        MediaTypeTheme.iconFor(_selectedType),
        size: 40,
        color: AppColors.textTertiary,
      ),
    );
  }

  /// Inline-редактируемый чип (как infoChips в MediaDetailView).
  Widget _buildEditableChip({
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    required double width,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      constraints: BoxConstraints(maxWidth: width),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Flexible(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Тип медиа — горизонтальные chips.
  Widget _buildMediaTypeChips(S l) {
    const List<MediaType> types = <MediaType>[
      MediaType.game,
      MediaType.movie,
      MediaType.tvShow,
      MediaType.animation,
      MediaType.visualNovel,
      MediaType.manga,
    ];

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: types.map((MediaType type) {
        final bool isSelected = type == _selectedType;
        final Color typeColor = MediaTypeTheme.colorFor(type);
        return ChoiceChip(
          label: Text(type.localizedLabel(l)),
          selected: isSelected,
          onSelected: (bool selected) {
            if (selected) setState(() => _selectedType = type);
          },
          selectedColor: typeColor.withValues(alpha: 0.3),
          side: isSelected
              ? BorderSide(color: typeColor, width: 1.5)
              : null,
          labelStyle: TextStyle(
            color: isSelected ? typeColor : null,
            fontWeight: isSelected ? FontWeight.w600 : null,
            fontSize: 12,
          ),
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 6),
        );
      }).toList(),
    );
  }

  /// Секция рейтинга — 10 звёзд.
  Widget _buildRatingSection(S l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'My Rating',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: List<Widget>.generate(10, (int index) {
            final int starValue = index + 1;
            final bool isFilled =
                _userRating != null && starValue <= _userRating!;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _userRating =
                      _userRating == starValue ? null : starValue;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 28,
                  color: isFilled ? _accentColor : AppColors.textTertiary,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Секция описания — многострочное поле.
  Widget _buildDescriptionSection(S l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l.customItemDescription,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: l.customItemDescriptionHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: const BorderSide(color: AppColors.surfaceBorder),
            ),
            filled: true,
            fillColor: AppColors.surfaceLight,
          ),
        ),
      ],
    );
  }
}
