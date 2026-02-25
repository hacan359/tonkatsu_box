// Секция отзывов TMDB на странице элемента коллекции.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/tmdb_review.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../settings/providers/settings_provider.dart' show SettingsState, settingsNotifierProvider;

/// Кэш провайдеров отзывов фильмов по tmdbId.
final Map<int, FutureProvider<List<TmdbReview>>> _movieReviewProviders =
    <int, FutureProvider<List<TmdbReview>>>{};

/// Кэш провайдеров отзывов сериалов по tmdbId.
final Map<int, FutureProvider<List<TmdbReview>>> _tvReviewProviders =
    <int, FutureProvider<List<TmdbReview>>>{};

/// Возвращает кэшированный провайдер отзывов фильмов.
FutureProvider<List<TmdbReview>> _getMovieReviewProvider(int tmdbId) {
  return _movieReviewProviders.putIfAbsent(
    tmdbId,
    () => FutureProvider<List<TmdbReview>>((Ref ref) async {
      final TmdbApi tmdb = ref.watch(tmdbApiProvider);
      return tmdb.getMovieReviews(tmdbId);
    }),
  );
}

/// Возвращает кэшированный провайдер отзывов сериалов.
FutureProvider<List<TmdbReview>> _getTvReviewProvider(int tmdbId) {
  return _tvReviewProviders.putIfAbsent(
    tmdbId,
    () => FutureProvider<List<TmdbReview>>((Ref ref) async {
      final TmdbApi tmdb = ref.watch(tmdbApiProvider);
      return tmdb.getTvReviews(tmdbId);
    }),
  );
}

/// Секция с отзывами TMDB.
///
/// Показывает 2-3 отзыва с возможностью развернуть.
/// Скрывается если отзывов нет.
class ReviewsSection extends ConsumerWidget {
  /// Создаёт [ReviewsSection].
  const ReviewsSection({
    required this.tmdbId,
    required this.mediaType,
    super.key,
  });

  /// TMDB ID элемента.
  final int tmdbId;

  /// Тип медиа.
  final MediaType mediaType;

  bool get _isTvBased =>
      mediaType == MediaType.tvShow ||
      (mediaType == MediaType.animation);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsState settings = ref.watch(settingsNotifierProvider);
    if (settings.tmdbApiKey == null || settings.tmdbApiKey!.isEmpty) {
      return const SizedBox.shrink();
    }

    final FutureProvider<List<TmdbReview>> provider =
        _isTvBased ? _getTvReviewProvider(tmdbId) : _getMovieReviewProvider(tmdbId);

    final AsyncValue<List<TmdbReview>> asyncReviews = ref.watch(provider);

    return asyncReviews.when(
      data: (List<TmdbReview> reviews) {
        if (reviews.isEmpty) return const SizedBox.shrink();
        return _ReviewsList(reviews: reviews);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Список отзывов с разворачиванием.
class _ReviewsList extends StatefulWidget {
  const _ReviewsList({required this.reviews});

  final List<TmdbReview> reviews;

  @override
  State<_ReviewsList> createState() => _ReviewsListState();
}

class _ReviewsListState extends State<_ReviewsList> {
  static const int _previewCount = 2;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final List<TmdbReview> visible = _showAll
        ? widget.reviews
        : widget.reviews.take(_previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              l.reviewsTitle,
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l.reviewsInEnglish,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (int i = 0; i < visible.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _ReviewCard(review: visible[i]),
        ],
        if (!_showAll && widget.reviews.length > _previewCount) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => setState(() => _showAll = true),
            child: Text(l.reviewsShowAll(widget.reviews.length)),
          ),
        ],
      ],
    );
  }
}

/// Карточка одного отзыва.
class _ReviewCard extends StatefulWidget {
  const _ReviewCard({required this.review});

  final TmdbReview review;

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  static const int _maxContentLength = 200;
  bool _expanded = false;

  bool get _isLong => widget.review.content.length > _maxContentLength;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md - 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Заголовок: автор + рейтинг
          Row(
            children: <Widget>[
              if (widget.review.avatarPath != null) ...<Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: widget.review.avatarPath!,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) =>
                        const Icon(Icons.person, size: 24),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  widget.review.author,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.review.authorRating != null) ...<Widget>[
                const Icon(
                  Icons.star,
                  size: 14,
                  color: AppColors.ratingStar,
                ),
                const SizedBox(width: 2),
                Text(
                  '${widget.review.formattedRating}/10',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Текст отзыва
          Text(
            _expanded || !_isLong
                ? widget.review.content
                : '${widget.review.content.substring(0, _maxContentLength)}...',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (_isLong) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? l.close : l.reviewsReadMore,
                style: AppTypography.caption.copyWith(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
