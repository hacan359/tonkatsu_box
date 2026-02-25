// Переиспользуемый горизонтальный ряд постеров для Discover.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
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

    final bool compact = MediaQuery.sizeOf(context).width < 600;
    final double posterWidth = compact ? 100 : 130;
    final double rowHeight = compact ? 175 : 220;

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
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: widget.items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (BuildContext context, int index) {
                final DiscoverItem item = widget.items[index];
                return _DiscoverPosterCard(
                  item: item,
                  width: posterWidth,
                  onTap: () => widget.onTap(item),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Карточка постера в ряду Discover.
class _DiscoverPosterCard extends StatelessWidget {
  const _DiscoverPosterCard({
    required this.item,
    required this.width,
    required this.onTap,
  });

  final DiscoverItem item;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusSm),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _buildPoster(),
                    // Лёгкое затемнение
                    const Positioned.fill(
                      child: ColoredBox(color: Color(0x20000000)),
                    ),
                    // Бейдж "в коллекции"
                    if (item.isOwned)
                      const Positioned(
                        top: 4,
                        right: 4,
                        child: Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                    // Рейтинг
                    if (item.rating != null)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(
                                Icons.star,
                                size: 10,
                                color: AppColors.ratingStar,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                item.rating!,
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.title,
              style: AppTypography.posterTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.year != null)
              Text(
                item.year.toString(),
                style: AppTypography.posterSubtitle,
                maxLines: 1,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster() {
    if (item.posterUrl == null || item.posterUrl!.isEmpty) {
      return Container(
        color: AppColors.surfaceLight,
        child: const Center(
          child: Icon(
            Icons.movie_outlined,
            color: AppColors.textTertiary,
            size: 32,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: item.posterUrl!,
      fit: BoxFit.cover,
      memCacheWidth: 300,
      placeholder: (_, _) => Container(
        color: AppColors.surfaceLight,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (_, _, _) => Container(
        color: AppColors.surfaceLight,
        child: const Center(
          child: Icon(
            Icons.movie_outlined,
            color: AppColors.textTertiary,
            size: 32,
          ),
        ),
      ),
    );
  }
}
