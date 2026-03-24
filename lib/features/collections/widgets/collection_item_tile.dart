// Плитка элемента коллекции для list-режима CollectionScreen.

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/dual_rating_badge.dart';
import 'status_ribbon.dart';

/// Плитка элемента в коллекции (list mode).
///
/// Показывает обложку, название, подзаголовок, рейтинги, описание,
/// авторский комментарий и личные заметки. Поддерживает drag handle
/// для ручной сортировки и контекстное меню (move/remove).
class CollectionItemTile extends StatelessWidget {
  /// Создаёт [CollectionItemTile].
  const CollectionItemTile({
    required this.item,
    required this.isEditable,
    this.showDragHandle = false,
    this.dragIndex = 0,
    this.onMove,
    this.onClone,
    this.onRemove,
    this.onSecondaryTap,
    this.onLongPress,
    this.onTap,
    super.key,
  });

  /// Элемент коллекции.
  final CollectionItem item;

  /// Можно ли редактировать (move/remove).
  final bool isEditable;

  /// Показывать drag handle для ручной сортировки.
  final bool showDragHandle;

  /// Индекс для [ReorderableDragStartListener].
  final int dragIndex;

  /// Callback перемещения в другую коллекцию.
  final VoidCallback? onMove;

  /// Callback копирования в другую коллекцию.
  final VoidCallback? onClone;

  /// Callback удаления из коллекции.
  final VoidCallback? onRemove;

  /// Callback правого клика (координаты для showMenu).
  final void Function(Offset globalPosition)? onSecondaryTap;

  /// Callback долгого нажатия / Y на геймпаде (контекстное меню).
  final VoidCallback? onLongPress;

  /// Callback нажатия (открыть детали).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapUp: onSecondaryTap != null
          ? (TapUpDetails details) =>
              onSecondaryTap!(details.globalPosition)
          : null,
      child: Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.surfaceBorder),
      ),
      child: Stack(
        children: <Widget>[
          // Фоновая иконка типа медиа (наклонённая, обрезается Card)
          Positioned.fill(
            child: Align(
              alignment: const Alignment(0.0, -7.2),
              child: Transform.rotate(
                angle: -0.3,
                child: Icon(
                  MediaTypeTheme.iconFor(item.mediaType),
                  size: 200,
                  color: MediaTypeTheme.colorFor(item.mediaType)
                      .withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          // Основное содержимое
          InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md - 4),
              child: Row(
                children: <Widget>[
                  // Drag handle (только в manual sort mode)
                  if (showDragHandle)
                    ReorderableDragStartListener(
                      index: dragIndex,
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: Icon(
                          Icons.drag_handle,
                          size: 20,
                          color: AppColors.textTertiary.withAlpha(128),
                        ),
                      ),
                    ),
                  // Обложка
                  _buildCover(),
                  const SizedBox(width: AppSpacing.md - 4),

                  // Информация
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Название
                        Text(
                          item.itemName,
                          style: AppTypography.h3,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: AppSpacing.xs),

                        // Подзаголовок (зависит от типа медиа)
                        Text(
                          _getSubtitle(),
                          style: AppTypography.bodySmall,
                        ),

                        // Рейтинги (пользовательский + API)
                        if (_hasAnyRating) ...<Widget>[
                          const SizedBox(height: AppSpacing.xs),
                          DualRatingBadge(
                            userRating: item.userRating,
                            apiRating: item.apiRating,
                            inline: true,
                          ),
                        ],

                        // Описание
                        if (item.itemDescription != null &&
                            item.itemDescription!.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            item.itemDescription!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        // Комментарий автора (рецензия)
                        if (item.hasAuthorComment) ...<Widget>[
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.format_quote,
                                size: 14,
                                color: AppColors.movieAccent,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  item.authorComment!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.movieAccent,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Личные заметки
                        if (item.hasUserComment) ...<Widget>[
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.note_outlined,
                                size: 14,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  item.userComment!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Move / Clone / Remove меню
                  if (onMove != null || onClone != null || onRemove != null)
                    _buildContextMenu(context),
                ],
              ),
            ),
          ),
          // Диагональная ленточка статуса (верхний левый угол, поверх контента)
          StatusRibbon(
            status: item.status,
            mediaType: item.mediaType,
          ),
        ],
      ),
    ),
    );
  }

  bool get _hasAnyRating =>
      item.userRating != null ||
      (item.apiRating != null && item.apiRating! > 0);

  String _getSubtitle() {
    if (item.mediaType == MediaType.game) return item.platformName;
    final List<String> parts = <String>[];
    if (item.releaseYear != null) parts.add(item.releaseYear.toString());
    if (item.runtime != null) {
      final int hours = item.runtime! ~/ 60;
      final int mins = item.runtime! % 60;
      if (hours > 0 && mins > 0) {
        parts.add('${hours}h ${mins}m');
      } else if (hours > 0) {
        parts.add('${hours}h');
      } else {
        parts.add('${mins}m');
      }
    }
    if (item.totalSeasons != null) {
      parts.add(
        '${item.totalSeasons} season${item.totalSeasons != 1 ? 's' : ''}',
      );
    }
    if (parts.isNotEmpty) return parts.join(' \u2022 ');
    return item.genresString ?? '';
  }

  Widget _buildCover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: SizedBox(
        width: 48,
        height: 72,
        child: item.thumbnailUrl != null
            ? CachedImage(
                imageType: item.imageType,
                imageId: item.externalId.toString(),
                remoteUrl: item.thumbnailUrl!,
                fit: BoxFit.cover,
                memCacheWidth: 96,
                memCacheHeight: 128,
                placeholder: Container(
                  color: AppColors.surfaceLight,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: Icon(
        item.placeholderIcon,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildContextMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        color: AppColors.textSecondary,
      ),
      padding: EdgeInsets.zero,
      onSelected: (String value) {
        switch (value) {
          case 'move':
            onMove?.call();
          case 'clone':
            onClone?.call();
          case 'remove':
            onRemove?.call();
        }
      },
      itemBuilder: (BuildContext context) {
        final S ml = S.of(context);
        return <PopupMenuEntry<String>>[
          if (onMove != null)
            PopupMenuItem<String>(
              value: 'move',
              child: ListTile(
                leading:
                    const Icon(Icons.drive_file_move_outlined),
                title: Text(ml.collectionMoveToCollection),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          if (onClone != null)
            PopupMenuItem<String>(
              value: 'clone',
              child: ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: Text(ml.collectionCopyToCollection),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          if ((onMove != null || onClone != null) && onRemove != null)
            const PopupMenuDivider(),
          if (onRemove != null)
            PopupMenuItem<String>(
              value: 'remove',
              child: ListTile(
                leading: Icon(
                  Icons.remove_circle_outline,
                  color:
                      Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  ml.remove,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .error,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
        ];
      },
    );
  }
}
