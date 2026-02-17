// Базовый виджет для экранов деталей медиа в коллекции.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/services/image_cache_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'cached_image.dart';
import 'source_badge.dart';
import 'star_rating_bar.dart';

/// Чип с иконкой и текстом для отображения метаинформации.
class MediaDetailChip {
  /// Создаёт [MediaDetailChip].
  const MediaDetailChip({
    required this.icon,
    required this.text,
    this.iconColor,
  });

  /// Иконка чипа.
  final IconData icon;

  /// Текст чипа.
  final String text;

  /// Цвет иконки (по умолчанию [AppColors.textSecondary]).
  final Color? iconColor;
}

/// Базовый виджет экрана деталей медиа в коллекции.
///
/// Отображает единый layout для игр, фильмов и сериалов:
/// постер + информация, статус, комментарии, заметки.
/// Специфичные секции передаются через [extraSections].
class MediaDetailView extends StatelessWidget {
  /// Создаёт [MediaDetailView].
  const MediaDetailView({
    required this.title,
    required this.placeholderIcon,
    required this.source,
    required this.typeIcon,
    required this.typeLabel,
    required this.isEditable,
    required this.onAuthorCommentSave,
    required this.onUserCommentSave,
    this.coverUrl,
    this.infoChips = const <MediaDetailChip>[],
    this.description,
    this.statusWidget,
    this.extraSections,
    this.authorComment,
    this.userComment,
    this.userRating,
    this.onUserRatingChanged,
    this.hasAuthorComment = false,
    this.hasUserComment = false,
    this.embedded = false,
    this.cacheImageType,
    this.cacheImageId,
    this.accentColor = AppColors.gameAccent,
    super.key,
  });

  /// Название для AppBar.
  final String title;

  /// URL обложки/постера.
  final String? coverUrl;

  /// Иконка-заглушка при отсутствии обложки.
  final IconData placeholderIcon;

  /// Источник данных (IGDB, TMDB).
  final DataSource source;

  /// Иконка типа контента.
  final IconData typeIcon;

  /// Текст типа контента (платформа, "Movie", "TV Show").
  final String typeLabel;

  /// Чипы с метаинформацией (год, рейтинг, жанры и т.д.).
  final List<MediaDetailChip> infoChips;

  /// Описание/обзор контента.
  final String? description;

  /// Виджет выбора статуса.
  final Widget? statusWidget;

  /// Дополнительные секции (например, Progress для сериалов).
  final List<Widget>? extraSections;

  /// Рецензия автора коллекции (видна другим пользователям при экспорте).
  final String? authorComment;

  /// Личные заметки пользователя.
  final String? userComment;

  /// Пользовательский рейтинг (1-10).
  final int? userRating;

  /// Колбэк при изменении пользовательского рейтинга.
  final ValueChanged<int?>? onUserRatingChanged;

  /// Есть ли рецензия автора.
  final bool hasAuthorComment;

  /// Есть ли личные заметки.
  final bool hasUserComment;

  /// Можно ли редактировать рецензию автора.
  final bool isEditable;

  /// Встраиваемый режим (без Scaffold и AppBar).
  ///
  /// Если true, виджет возвращает только контент без обёртки в Scaffold.
  /// Используется когда MediaDetailView встроен в другой экран (например,
  /// в TabBarView на GameDetailScreen).
  final bool embedded;

  /// Тип изображения для локального кэширования.
  ///
  /// Если задан вместе с [cacheImageId], используется [CachedImage]
  /// вместо [CachedNetworkImage] для поддержки оффлайн-режима.
  final ImageType? cacheImageType;

  /// ID изображения для локального кэширования.
  final String? cacheImageId;

  /// Акцентный цвет (зависит от типа медиа).
  final Color accentColor;

  /// Колбэк сохранения комментария автора.
  final ValueChanged<String?> onAuthorCommentSave;

  /// Колбэк сохранения личных заметок.
  final ValueChanged<String?> onUserCommentSave;

  @override
  Widget build(BuildContext context) {
    final Widget content = ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: <Widget>[
        _buildHeader(),
        if (statusWidget != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _buildStatusSection(),
        ],
        if (onUserRatingChanged != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _buildUserRatingSection(),
        ],
        const SizedBox(height: AppSpacing.md),
        _buildUserNotesSection(context),
        const SizedBox(height: AppSpacing.md),
        _buildAuthorCommentSection(context),
        if (extraSections != null && extraSections!.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _buildExtraSectionsExpansion(context),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );

    if (embedded) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        title: Text(title, style: AppTypography.h2),
      ),
      body: content,
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Обложка/постер (увеличена до 100×150)
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: SizedBox(
            width: 100,
            height: 150,
            child: _buildCoverImage(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Информация
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  SourceBadge(
                    source: source,
                    size: SourceBadgeSize.medium,
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    typeIcon,
                    size: 16,
                    color: accentColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      typeLabel,
                      style: AppTypography.bodySmall.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (infoChips.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: <Widget>[
                    for (final MediaDetailChip chip in infoChips)
                      _buildInfoChip(chip.icon, chip.text, iconColor: chip.iconColor),
                  ],
                ),
              ],
              if (description != null &&
                  description!.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoverImage() {
    if (coverUrl == null || coverUrl!.isEmpty) return _buildPlaceholder();

    final bool useLocalCache =
        cacheImageType != null && cacheImageId != null;

    if (useLocalCache) {
      return CachedImage(
        imageType: cacheImageType!,
        imageId: cacheImageId!,
        remoteUrl: coverUrl!,
        fit: BoxFit.cover,
        memCacheWidth: 200,
        memCacheHeight: 300,
        placeholder: _buildLoadingPlaceholder(),
        errorWidget: _buildPlaceholder(),
      );
    }

    return CachedNetworkImage(
      imageUrl: coverUrl!,
      fit: BoxFit.cover,
      memCacheWidth: 200,
      memCacheHeight: 300,
      placeholder: (BuildContext ctx, String url) =>
          _buildLoadingPlaceholder(),
      errorWidget: (BuildContext ctx, String url, Object error) =>
          _buildPlaceholder(),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: Icon(
        placeholderIcon,
        size: 32,
        color: AppColors.textTertiary,
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: iconColor ?? AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Status',
          style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        statusWidget!,
      ],
    );
  }

  Widget _buildUserRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(
              Icons.star,
              size: 18,
              color: AppColors.ratingStar,
            ),
            const SizedBox(width: 6),
            Text(
              'My Rating',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
            ),
            if (userRating != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$userRating/10',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        StarRatingBar(
          rating: userRating,
          onChanged: onUserRatingChanged!,
        ),
      ],
    );
  }

  Widget _buildExtraSectionsExpansion(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(
          'Activity & Progress',
          style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
        ),
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        children: <Widget>[
          for (final Widget section in extraSections!) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            section,
          ],
        ],
      ),
    );
  }

  Widget _buildAuthorCommentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.format_quote,
                  size: 18,
                  color: AppColors.movieAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  "Author's Review",
                  style: AppTypography.h3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (isEditable)
              TextButton.icon(
                onPressed: () => _editComment(
                  context,
                  title: "Edit Author's Review",
                  hint: 'Write your review...',
                  initialValue: authorComment,
                  onSave: onAuthorCommentSave,
                ),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Edit'),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Visible to others when shared. Your review of this title.',
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md - 4),
          decoration: BoxDecoration(
            color: AppColors.movieAccent.withAlpha(20),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: AppColors.movieAccent.withAlpha(40),
            ),
          ),
          child: hasAuthorComment
              ? Text(
                  authorComment!,
                  style: AppTypography.body.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                )
              : Text(
                  isEditable
                      ? 'No review yet. Tap Edit to add one.'
                      : 'No review from the author.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildUserNotesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.note_alt_outlined,
                  size: 18,
                  color: accentColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'My Notes',
                  style: AppTypography.h3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => _editComment(
                context,
                title: 'Edit My Notes',
                hint: 'Write your personal notes...',
                initialValue: userComment,
                onSave: onUserCommentSave,
              ),
              icon: const Icon(Icons.edit, size: 14),
              label: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md - 4),
          decoration: BoxDecoration(
            color: accentColor.withAlpha(20),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: accentColor.withAlpha(40),
            ),
          ),
          child: hasUserComment
              ? Text(
                  userComment!,
                  style: AppTypography.body.copyWith(height: 1.5),
                )
              : Text(
                  'No notes yet. Tap Edit to add your personal notes.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _editComment(
    BuildContext context, {
    required String title,
    required String hint,
    required ValueChanged<String?> onSave,
    String? initialValue,
  }) async {
    final TextEditingController controller =
        TextEditingController(text: initialValue);

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        scrollable: true,
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;
    onSave(result.isEmpty ? null : result);
  }
}
