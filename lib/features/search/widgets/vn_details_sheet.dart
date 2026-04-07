// Bottom sheet с деталями визуальной новеллы.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/visual_novel.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/source_badge.dart';

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
                      child: CachedImage(
                        imageType: ImageType.vnCover,
                        imageId: visualNovel.id,
                        remoteUrl: visualNovel.imageUrl!,
                        width: 100,
                        height: 142,
                        fit: BoxFit.cover,
                        placeholder: Container(
                          width: 100,
                          height: 142,
                          color: AppColors.surfaceLight,
                          child: const Center(
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: Container(
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
                        Text.rich(
                          TextSpan(children: <InlineSpan>[
                            TextSpan(
                              text: visualNovel.title,
                              style: AppTypography.h2.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (visualNovel.releaseYear != null)
                              TextSpan(
                                text: '  ${visualNovel.releaseYear}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                          ]),
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
                        Row(
                          children: <Widget>[
                            SourceBadge(
                              source: DataSource.vndb,
                              onTap: visualNovel.externalUrl != null
                                  ? () => _launchUrl(visualNovel.externalUrl!)
                                  : null,
                            ),
                            if (visualNovel.formattedRating != null) ...<Widget>[
                              const SizedBox(width: AppSpacing.sm),
                              const Icon(Icons.star, size: 14,
                                  color: AppColors.ratingStar),
                              const SizedBox(width: 2),
                              Text(
                                visualNovel.formattedRating!,
                                style: AppTypography.bodySmall,
                              ),
                            ],
                            if (visualNovel.lengthLabel != null) ...<Widget>[
                              const SizedBox(width: AppSpacing.sm),
                              const Icon(Icons.timer_outlined, size: 14,
                                  color: AppColors.brand),
                              const SizedBox(width: 2),
                              Text(
                                visualNovel.lengthLabel!,
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ],
                        ),
                        if (visualNovel.developersString != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.sm),
                          _buildInfoChip(
                            Icons.business,
                            visualNovel.developersString!,
                          ),
                        ],
                        if (visualNovel.platformsString != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.xs),
                          _buildInfoChip(
                            Icons.devices,
                            visualNovel.platformsString!,
                          ),
                        ],
                        if (visualNovel.tags != null &&
                            visualNovel.tags!.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: visualNovel.tags!
                                .take(_maxDisplayedTags)
                                .map(_buildGenreChip)
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

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: AppColors.brand),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenreChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Text(
        tag,
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
