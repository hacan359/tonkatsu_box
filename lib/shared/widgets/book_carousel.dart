// Horizontal carousel of book poster cards. Shared by the "similar books"
// sections (Fantlab / Google Books) and the search sheet's "more by this
// author" strip.

import 'package:core/models/book.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:core/utils/cover_image_id.dart';
import 'package:flutter/material.dart';

import '../../core/services/image_cache_service.dart';
import '../constants/platform_features.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/url_launch.dart';
import 'media_poster_card.dart';
import 'scrollable_row_with_arrows.dart';
import 'shimmer_loading.dart';

/// One horizontal strip of book cards (cover + title + year, with optional
/// rating and in-collection badge). Supports lazy paging through
/// [onEndReached] and per-book hover tooltips through [tooltipOf].
class BookCarousel extends StatefulWidget {
  const BookCarousel({
    required this.books,
    required this.onTap,
    this.ownedKeys = const <(DataSource, int)>{},
    this.showRating = true,
    this.tooltipOf,
    this.onEndReached,
    this.loadingMore = false,
    super.key,
  });

  final List<Book> books;
  final void Function(Book book) onTap;

  /// `(source, externalIdInt)` of books already in a collection — those cards
  /// show the owned badge. Keyed by source because book providers hand out
  /// colliding numeric ids. Empty disables the badge.
  final Set<(DataSource, int)> ownedKeys;

  final bool showRating;

  /// Hover / long-press tooltip text per book (e.g. its description). Returning
  /// null or empty hides the tooltip for that card.
  final String? Function(Book book)? tooltipOf;

  /// Called when the row is scrolled near its end, for incremental paging.
  /// Null disables paging.
  final VoidCallback? onEndReached;

  /// Appends a trailing spinner card while the next page loads.
  final bool loadingMore;

  @override
  State<BookCarousel> createState() => _BookCarouselState();
}

class _BookCarouselState extends State<BookCarousel> {
  final ScrollController _scrollController = ScrollController();

  // Tooltips longer than this are clipped so the hover card stays readable.
  static const int _maxTooltipChars = 280;

  @override
  void initState() {
    super.initState();
    if (widget.onEndReached != null) {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.onEndReached == null || !_scrollController.hasClients) return;
    final ScrollPosition pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      widget.onEndReached!();
    }
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
    final int itemCount = widget.books.length + (widget.loadingMore ? 1 : 0);

    return SizedBox(
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
          itemCount: itemCount,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (BuildContext context, int index) {
            if (index >= widget.books.length) {
              return SizedBox(
                width: posterWidth,
                child: const Center(
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            return _card(widget.books[index], posterWidth, compact);
          },
        ),
      ),
    );
  }

  Widget _card(Book book, double posterWidth, bool compact) {
    final Widget card = SizedBox(
      width: posterWidth,
      child: MediaPosterCard(
        variant: compact ? CardVariant.compact : CardVariant.grid,
        title: book.title,
        imageUrl: book.coverUrl ?? '',
        cacheImageType: ImageType.bookCover,
        cacheImageId: coverImageId(
          mediaType: MediaType.book,
          externalId: book.externalIdInt,
          source: book.source,
          coverUrl: book.coverUrl,
        ),
        year: book.publishYear,
        apiRating: widget.showRating ? book.rating : null,
        splitRatings: true,
        isInCollection:
            widget.ownedKeys.contains((book.source, book.externalIdInt)),
        placeholderIcon: Icons.menu_book,
        source: book.source,
        onSourceTap: openUrlCallback(book.externalUrl),
        onTap: () => widget.onTap(book),
      ),
    );

    final String? tip = widget.tooltipOf?.call(book);
    if (tip == null || tip.isEmpty) return card;
    return Tooltip(
      message: tip.length > _maxTooltipChars
          ? '${tip.substring(0, _maxTooltipChars).trimRight()}…'
          : tip,
      waitDuration: const Duration(milliseconds: 400),
      child: card,
    );
  }
}

/// Title-and-strip shimmer shown while a similars carousel is loading.
class BookCarouselShimmer extends StatelessWidget {
  const BookCarouselShimmer({super.key});

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
