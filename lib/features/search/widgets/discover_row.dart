import '../../../shared/constants/platform_features.dart';
// Переиспользуемый горизонтальный ряд постеров для Discover.

import 'package:flutter/material.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../../../shared/widgets/scrollable_row_with_arrows.dart';

/// Элемент для отображения в ряду Discover.
class DiscoverItem {
  /// Создаёт [DiscoverItem].
  const DiscoverItem({
    required this.title,
    required this.tmdbId,
    this.posterUrl,
    this.year,
    this.rating,
    this.isOwned = false,
    this.isMovie = true,
  });

  /// Название.
  final String title;

  /// TMDB ID.
  final int tmdbId;

  /// URL постера.
  final String? posterUrl;

  /// Год.
  final int? year;

  /// Рейтинг (форматированный).
  final String? rating;

  /// Уже в коллекции.
  final bool isOwned;

  /// Фильм (true) или сериал (false) — для различия при одинаковых tmdbId.
  final bool isMovie;
}

/// Горизонтальный ряд постеров с заголовком.
class DiscoverRow extends StatefulWidget {
  /// Создаёт [DiscoverRow].
  const DiscoverRow({
    required this.title,
    required this.items,
    required this.onTap,
    this.icon,
    super.key,
  });

  /// Заголовок секции.
  final String title;

  /// Элементы для отображения.
  final List<DiscoverItem> items;

  /// Callback при тапе на элемент.
  final void Function(DiscoverItem item) onTap;

  /// Иконка в заголовке.
  final IconData? icon;

  @override
  State<DiscoverRow> createState() => _DiscoverRowState();
}

class _DiscoverRowState extends State<DiscoverRow> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final bool compact = isCompactScreen(context);
    final double posterWidth = compact ? 100 : 130;
    final double rowHeight = compact ? 185 : 230;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: <Widget>[
              if (widget.icon != null) ...<Widget>[
                Icon(
                  widget.icon,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  widget.title,
                  style:
                      AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: rowHeight,
          child: ScrollableRowWithArrows(
            controller: _scrollController,
            height: rowHeight,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 4,
              ),
              itemCount: widget.items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (BuildContext context, int index) {
                final DiscoverItem item = widget.items[index];
                return SizedBox(
                  width: posterWidth,
                  child: MediaPosterCard(
                    variant: compact
                        ? CardVariant.compact
                        : CardVariant.grid,
                    title: item.title,
                    imageUrl: item.posterUrl ?? '',
                    cacheImageType: item.isMovie
                        ? ImageType.moviePoster
                        : ImageType.tvShowPoster,
                    cacheImageId: item.tmdbId.toString(),
                    year: item.year,
                    apiRating: double.tryParse(item.rating ?? ''),
                    isInCollection: item.isOwned,
                    placeholderIcon: item.isMovie
                        ? Icons.movie_outlined
                        : Icons.tv_outlined,
                    onTap: () => widget.onTap(item),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

