import 'package:core/models/data_source.dart';
import 'package:core/models/image_type.dart';
import 'package:flutter/material.dart';

import '../../../shared/constants/platform_features.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/utils/url_launch.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../../../shared/widgets/scrollable_row_with_arrows.dart';
import '../../../shared/widgets/shimmer_loading.dart';

/// One card of a [SimilarsPosterRow], already resolved to display values so
/// the row stays media-type agnostic.
typedef SimilarCardData = ({
  String title,
  String imageUrl,
  ImageType cacheImageType,
  String cacheImageId,
  int? year,
  double? apiRating,
  bool isOwned,
  IconData placeholderIcon,
  DataSource source,
  String? externalUrl,
  VoidCallback onTap,
});

/// Titled horizontal poster carousel shared by the "Similar …" sections
/// (anime / manga); pair with [SimilarsPosterRowShimmer] while loading.
class SimilarsPosterRow extends StatefulWidget {
  const SimilarsPosterRow({
    required this.title,
    required this.cards,
    super.key,
  });

  final String title;
  final List<SimilarCardData> cards;

  @override
  State<SimilarsPosterRow> createState() => _SimilarsPosterRowState();
}

class _SimilarsPosterRowState extends State<SimilarsPosterRow> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = isCompactScreen(context);
    final double posterWidth = compact ? 100 : 130;
    final double rowHeight = AppSpacing.posterRowHeight(
      posterWidth: posterWidth,
      compact: compact,
      textScaler: MediaQuery.textScalerOf(context),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.title,
          style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Clip.none inside lets hover scale / shadows use the row padding;
        // this rect stops cards sliding out over neighbouring UI mid-scroll.
        ClipRect(
          child: SizedBox(
            height: rowHeight,
            child: ScrollableRowWithArrows(
              controller: _scrollController,
              height: rowHeight,
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.posterRowVerticalPadding,
                ),
                itemCount: widget.cards.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (BuildContext context, int index) {
                  final SimilarCardData card = widget.cards[index];
                  return SizedBox(
                    width: posterWidth,
                    child: MediaPosterCard(
                      variant: compact ? CardVariant.compact : CardVariant.grid,
                      title: card.title,
                      imageUrl: card.imageUrl,
                      cacheImageType: card.cacheImageType,
                      cacheImageId: card.cacheImageId,
                      year: card.year,
                      apiRating: card.apiRating,
                      splitRatings: true,
                      isInCollection: card.isOwned,
                      placeholderIcon: card.placeholderIcon,
                      source: card.source,
                      onSourceTap: openUrlCallback(card.externalUrl),
                      onTap: card.onTap,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Loading placeholder matching [SimilarsPosterRow]'s layout.
class SimilarsPosterRowShimmer extends StatelessWidget {
  const SimilarsPosterRowShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final bool compact = isCompactScreen(context);
    final double posterWidth = compact ? 100 : 130;
    final double rowHeight = AppSpacing.posterRowHeight(
      posterWidth: posterWidth,
      compact: compact,
      textScaler: MediaQuery.textScalerOf(context),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 150,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: rowHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.posterRowVerticalPadding,
            ),
            itemCount: 5,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, _) => SizedBox(
              width: posterWidth,
              child: ShimmerPosterCard(compact: compact),
            ),
          ),
        ),
      ],
    );
  }
}
