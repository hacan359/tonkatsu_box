// Bottom sheet с деталями визуальной новеллы.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/data_source.dart';
import '../../../shared/models/visual_novel.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Bottom sheet с деталями визуальной новеллы.
class VnDetailsSheet extends StatelessWidget {
  /// Создаёт [VnDetailsSheet].
  const VnDetailsSheet({
    required this.visualNovel,
    required this.onAddToCollection,
    super.key,
  });

  /// Максимальное количество отображаемых тегов.
  static const int _maxDisplayedTags = 8;

  /// Визуальная новелла для отображения.
  final VisualNovel visualNovel;

  /// Callback добавления в коллекцию.
  final VoidCallback onAddToCollection;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withAlpha(102),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Обложка и основная информация
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (visualNovel.imageUrl != null)
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                      child: CachedNetworkImage(
                        imageUrl: visualNovel.imageUrl!,
                        width: 100,
                        height: 142,
                        fit: BoxFit.cover,
                        placeholder:
                            (BuildContext context, String url) => Container(
                          width: 100,
                          height: 142,
                          color: AppColors.surfaceLight,
                          child: const Center(
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (BuildContext context, String url,
                                Object error) =>
                            Container(
                          width: 100,
                          height: 142,
                          color: AppColors.surfaceLight,
                          child: const Icon(Icons.menu_book,
                              color: AppColors.textSecondary, size: 32),
                        ),
                      ),
                    ),
                  if (visualNovel.imageUrl != null)
                    const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          visualNovel.title,
                          style: AppTypography.h2.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (visualNovel.altTitle != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            visualNovel.altTitle!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),

                        // Бейдж VNDB
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DataSource.vndb.color.withAlpha(51),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            DataSource.vndb.label,
                            style: AppTypography.caption.copyWith(
                              color: DataSource.vndb.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.sm,
                          children: <Widget>[
                            if (visualNovel.releaseYear != null)
                              _buildChip(
                                Icons.calendar_today,
                                visualNovel.releaseYear.toString(),
                              ),
                            if (visualNovel.formattedRating != null)
                              _buildChip(
                                Icons.star,
                                visualNovel.voteCount != null
                                    ? '${visualNovel.formattedRating}'
                                      ' (${visualNovel.voteCount})'
                                    : visualNovel.formattedRating!,
                              ),
                            if (visualNovel.lengthLabel != null)
                              _buildChip(
                                Icons.timer_outlined,
                                visualNovel.lengthLabel!,
                              ),
                          ],
                        ),
                        if (visualNovel.developersString != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.sm),
                          _buildChip(
                            Icons.business,
                            visualNovel.developersString!,
                          ),
                        ],
                        if (visualNovel.platformsString != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.sm),
                          _buildChip(
                            Icons.devices,
                            visualNovel.platformsString!,
                          ),
                        ],
                        if (visualNovel.tags != null &&
                            visualNovel.tags!.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: visualNovel.tags!
                                .take(_maxDisplayedTags)
                                .map((String tag) =>
                                    Chip(label: Text(tag)))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              if (visualNovel.description != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l.searchDescription,
                  style: AppTypography.h3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  visualNovel.description!,
                  style: AppTypography.body,
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onAddToCollection();
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l.searchAddToCollection),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          icon,
          size: 16,
          color: icon == Icons.star
              ? AppColors.ratingStar
              : AppColors.brand,
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(label)),
      ],
    );
  }
}
