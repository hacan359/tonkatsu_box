import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_extract.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../../../shared/widgets/shimmer_loading.dart' show ShimmerPosterCard;
import '../../../shared/widgets/source_logo.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/search_source.dart';
import '../providers/browse_provider.dart';
import 'browse_card.dart';
import 'source_error_strip.dart';

/// Narrow-screen results layout for several sources: swipeable rails, one per
/// provider. Kept apart from the desktop version so neither carries the other's
/// metrics or the desktop-only scroll affordances.
class BrowseSectionsCompact extends ConsumerWidget {
  const BrowseSectionsCompact({
    required this.onItemTap,
    this.onOpenInCollection,
    this.platformMap = const <int, Platform>{},
    super.key,
  });

  final void Function(Object item, MediaType mediaType) onItemTap;

  final void Function(
    int externalId,
    MediaType mediaType,
    DataSource? source,
  )? onOpenInCollection;

  final Map<int, Platform> platformMap;

  static const double cardWidth = 104;

  static double get railHeight => cardWidth / AppSpacing.posterCardAspectRatio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BrowseState state = ref.watch(browseProvider);
    final S l = S.of(context);
    final String animeMangaTitleLanguage = ref.watch(
      settingsNotifierProvider
          .select((SettingsState s) => s.animeMangaTitleLanguage),
    );
    final CollectedIds collected =
        ref.watch(collectedIdsProvider).valueOrNull ?? kNoCollected;

    if (state.isEmpty) {
      final bool queried = state.hasActiveQuery;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                queried ? Icons.search_off : Icons.filter_alt_outlined,
                size: 40,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                queried ? l.searchNoResults : l.browseEmptyFilters,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      children: <Widget>[
        for (final SearchSource source in state.activeSources)
          if (state.errors[source.id] case final ApiError error)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: SourceErrorStrip(
                source: source,
                error: error,
                onRetry: () => ref.read(browseProvider.notifier).refresh(),
              ),
            )
          // A rail of its own while it is still answering: with nothing here at
          // all, a slow provider looks like one that found nothing.
          else if (state.isSourceLoading(source.id) &&
              (state.itemsBySource[source.id] ?? <Object>[]).isEmpty)
            _CompactRail(
              source: source,
              count: null,
              onShowAll: null,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                itemCount: 4,
                separatorBuilder: (BuildContext _, int _) =>
                    const SizedBox(width: AppSpacing.xs),
                itemBuilder: (BuildContext _, int _) => const SizedBox(
                  width: cardWidth,
                  child: ShimmerPosterCard(),
                ),
              ),
            )
          else if ((state.itemsBySource[source.id] ?? <Object>[]).isNotEmpty)
            _CompactRail(
              source: source,
              count: state.itemsBySource[source.id]!.length,
              onShowAll: () =>
                  ref.read(browseProvider.notifier).narrowTo(source.id),
              child: _CompactRailList(
                items: state.itemsBySource[source.id]!,
                state: state,
                source: source,
                collected: collected,
                animeMangaTitleLanguage: animeMangaTitleLanguage,
                platformMap: platformMap,
                onItemTap: onItemTap,
                onOpenInCollection: onOpenInCollection,
              ),
            ),
      ],
    );
  }
}

class _CompactRail extends StatelessWidget {
  const _CompactRail({
    required this.source,
    required this.count,
    required this.onShowAll,
    required this.child,
  });

  final SearchSource source;
  final int? count;
  final VoidCallback? onShowAll;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.xs,
            ),
            child: Row(
              children: <Widget>[
                SourceLogo(source: source.dataSource, size: 14),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  source.dataSource.label,
                  style: AppTypography.bodySmall
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                if (count != null) ...<Widget>[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '$count',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textTertiary),
                  ),
                ],
                const Spacer(),
                if (onShowAll != null)
                  // Buttons in a Row need an explicit minimumSize — the theme's
                  // default is infinite width.
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      minimumSize: const Size(0, 26),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onShowAll,
                    child: Text(
                      '${l.searchShowAll} →',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: BrowseSectionsCompact.railHeight,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _CompactRailList extends ConsumerStatefulWidget {
  const _CompactRailList({
    required this.items,
    required this.state,
    required this.source,
    required this.collected,
    required this.animeMangaTitleLanguage,
    required this.platformMap,
    required this.onItemTap,
    required this.onOpenInCollection,
  });

  final List<Object> items;
  final BrowseState state;
  final SearchSource source;
  final CollectedIds collected;
  final String animeMangaTitleLanguage;
  final Map<int, Platform> platformMap;
  final void Function(Object item, MediaType mediaType) onItemTap;
  final void Function(
    int externalId,
    MediaType mediaType,
    DataSource? source,
  )? onOpenInCollection;

  @override
  ConsumerState<_CompactRailList> createState() => _CompactRailListState();
}

class _CompactRailListState extends ConsumerState<_CompactRailList> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final ScrollPosition pos = _controller.position;
    if (pos.pixels >= pos.maxScrollExtent - 120) {
      ref.read(browseProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool loadingMore = widget.state.isLoadingMore &&
        (widget.state.moreBySource[widget.source.id] ?? false);

    return ListView.separated(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      itemCount: widget.items.length + (loadingMore ? 2 : 0),
      separatorBuilder: (BuildContext _, int _) =>
          const SizedBox(width: AppSpacing.xs),
      itemBuilder: (BuildContext context, int index) {
        if (index >= widget.items.length) {
          return const SizedBox(
            width: BrowseSectionsCompact.cardWidth,
            child: ShimmerPosterCard(),
          );
        }
        return SizedBox(
          width: BrowseSectionsCompact.cardWidth,
          child: BrowseCard(
            item: widget.items[index],
            mediaType: widget.state.mediaType,
            fallbackSource: widget.source.dataSource,
            collected: widget.collected,
            variant: CardVariant.compact,
            animeMangaTitleLanguage: widget.animeMangaTitleLanguage,
            platformMap: widget.platformMap,
            onTap: widget.onItemTap,
            onOpenInCollection: widget.onOpenInCollection,
          ),
        );
      },
    );
  }
}
