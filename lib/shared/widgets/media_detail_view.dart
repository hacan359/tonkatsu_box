// Базовый виджет для экранов деталей медиа в коллекции.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/services/image_cache_service.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'cached_image.dart';
import 'source_badge.dart';
import 'star_rating_bar.dart';

/// Колбэк для изменения даты активности.
///
/// [type] — тип даты ('started' или 'completed'),
/// [date] — выбранная дата.
typedef OnActivityDateChanged = Future<void> Function(
  String type,
  DateTime date,
);

/// Форматирует [DateTime] в короткую строку (например, "Jan 15").
String _formatActivityDate(DateTime date) {
  const List<String> months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

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
    this.recommendationSections,
    this.authorComment,
    this.userComment,
    this.userRating,
    this.onUserRatingChanged,
    this.addedAt,
    this.startedAt,
    this.completedAt,
    this.lastActivityAt,
    this.onActivityDateChanged,
    this.hasAuthorComment = false,
    this.hasUserComment = false,
    this.embedded = false,
    this.cacheImageType,
    this.cacheImageId,
    this.accentColor = AppColors.brand,
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

  /// Секции рекомендаций и отзывов (рендерятся после ExpansionTile, всегда видимы).
  final List<Widget>? recommendationSections;

  /// Рецензия автора коллекции (видна другим пользователям при экспорте).
  final String? authorComment;

  /// Личные заметки пользователя.
  final String? userComment;

  /// Пользовательский рейтинг (1-10).
  final int? userRating;

  /// Колбэк при изменении пользовательского рейтинга.
  final ValueChanged<int?>? onUserRatingChanged;

  /// Дата добавления элемента (readonly).
  final DateTime? addedAt;

  /// Дата начала.
  final DateTime? startedAt;

  /// Дата завершения.
  final DateTime? completedAt;

  /// Дата последней активности (readonly).
  final DateTime? lastActivityAt;

  /// Колбэк при изменении даты активности (Started/Completed).
  final OnActivityDateChanged? onActivityDateChanged;

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
  /// в ItemDetailScreen).
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
          _buildStatusSection(context),
        ],
        if (onUserRatingChanged != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _buildUserRatingSection(context),
        ],
        if (addedAt != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _buildActivityDatesRow(context),
        ],
        const SizedBox(height: AppSpacing.md),
        _buildUserNotesSection(context),
        const SizedBox(height: AppSpacing.md),
        _buildAuthorCommentSection(context),
        if (extraSections != null && extraSections!.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _buildExtraSectionsExpansion(context),
        ],
        if (recommendationSections != null &&
            recommendationSections!.isNotEmpty)
          for (final Widget section in recommendationSections!) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            section,
          ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );

    if (embedded) return content;

    return Scaffold(
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

  Widget _buildStatusSection(BuildContext context) {
    return statusWidget!;
  }

  Widget _buildUserRatingSection(BuildContext context) {
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
              S.of(context).detailMyRating,
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
            ),
            if (userRating != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              Text(
                S.of(context).detailRatingValue(userRating!),
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

  Widget _buildActivityDatesRow(BuildContext context) {
    final S l = S.of(context);
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        _buildDateChip(
          icon: Icons.add_circle_outline,
          label: l.activityDatesAdded,
          date: addedAt,
        ),
        _buildDateChip(
          icon: Icons.play_circle_outline,
          label: l.activityDatesStarted,
          date: startedAt,
          editable: onActivityDateChanged != null,
          onTap: onActivityDateChanged != null
              ? () => _pickActivityDate(context, 'started', startedAt)
              : null,
        ),
        _buildDateChip(
          icon: Icons.check_circle_outline,
          label: l.activityDatesCompleted,
          date: completedAt,
          editable: onActivityDateChanged != null,
          onTap: onActivityDateChanged != null
              ? () => _pickActivityDate(context, 'completed', completedAt)
              : null,
        ),
        if (lastActivityAt != null)
          _buildDateChip(
            icon: Icons.update,
            label: l.activityDatesLastActivity,
            date: lastActivityAt,
          ),
      ],
    );
  }

  Widget _buildDateChip({
    required IconData icon,
    required String label,
    DateTime? date,
    bool editable = false,
    VoidCallback? onTap,
  }) {
    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        Text(
          date != null ? _formatActivityDate(date) : '\u2014',
          style: AppTypography.bodySmall.copyWith(
            color: date != null
                ? AppColors.textSecondary
                : AppColors.textTertiary,
          ),
        ),
        if (editable) ...<Widget>[
          const SizedBox(width: 2),
          const Icon(
            Icons.edit_outlined,
            size: 12,
            color: AppColors.brand,
          ),
        ],
      ],
    );

    if (editable && onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: content,
    );
  }

  Future<void> _pickActivityDate(
    BuildContext context,
    String type,
    DateTime? current,
  ) async {
    final DateTime initialDate = current ?? DateTime.now();
    final DateTime firstDate = DateTime(1980);
    final DateTime lastDate = DateTime.now().add(const Duration(days: 365));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: type == 'started'
          ? S.of(context).activityDatesSelectStart
          : S.of(context).activityDatesSelectCompletion,
    );

    if (picked != null && context.mounted) {
      await onActivityDateChanged!(type, picked);
    }
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
          S.of(context).detailActivityProgress,
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
    final S l = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.format_quote,
                    size: 18,
                    color: AppColors.movieAccent,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l.detailAuthorReview,
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (isEditable)
              IconButton(
                onPressed: () => _editComment(
                  context,
                  title: l.detailEditAuthorReview,
                  hint: l.detailWriteReviewHint,
                  initialValue: authorComment,
                  onSave: onAuthorCommentSave,
                ),
                icon: const Icon(Icons.edit, size: 18),
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                tooltip: l.edit,
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          l.detailReviewVisibility,
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
                      ? l.detailNoReviewEditable
                      : l.detailNoReviewReadonly,
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
    final S l = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.note_alt_outlined,
                    size: 18,
                    color: accentColor,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l.detailMyNotes,
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _editComment(
                context,
                title: l.detailEditMyNotes,
                hint: l.detailWriteNotesHint,
                initialValue: userComment,
                onSave: onUserCommentSave,
              ),
              icon: const Icon(Icons.edit, size: 18),
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              tooltip: l.edit,
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
                  l.detailNoNotesYet,
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
            child: Text(S.of(ctx).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(S.of(ctx).save),
          ),
        ],
      ),
    );

    if (result == null) return;
    onSave(result.isEmpty ? null : result);
  }
}
