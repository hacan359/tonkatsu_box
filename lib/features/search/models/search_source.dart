import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/data_source_ui.dart';

/// TMDB's Animation genre id, used to keep animation out of generic
/// TV / movie searches.
const int tmdbAnimationGenreId = 16;

/// Group of [FilterSemantic] values that answer one question, so filters from
/// different sources can be folded into a single cross-source control.
enum FilterSemanticFamily { status, format }

/// Cross-source identity of a filter option. Labels are localized and per-source
/// ids diverge (`releasing` / `ongoing` / `current`), so only this can join them.
enum FilterSemantic {
  statusReleasing(FilterSemanticFamily.status),
  statusFinished(FilterSemanticFamily.status),
  statusHiatus(FilterSemanticFamily.status),
  statusCancelled(FilterSemanticFamily.status),
  statusNotYetReleased(FilterSemanticFamily.status),
  formatTv(FilterSemanticFamily.format),
  formatTvShort(FilterSemanticFamily.format),
  formatMovie(FilterSemanticFamily.format),
  formatOva(FilterSemanticFamily.format),
  formatOna(FilterSemanticFamily.format),
  formatSpecial(FilterSemanticFamily.format),
  typeManga(FilterSemanticFamily.format),
  typeNovel(FilterSemanticFamily.format),
  typeOneShot(FilterSemanticFamily.format),
  typeManhwa(FilterSemanticFamily.format),
  typeManhua(FilterSemanticFamily.format);

  const FilterSemantic(this.family);

  final FilterSemanticFamily family;
}

class FilterOption {
  const FilterOption({
    required this.id,
    required this.label,
    this.icon,
    this.value,
    this.semantic,
  });

  final String id;
  final String label;
  final IconData? icon;

  /// Raw value passed to the API for this option.
  final Object? value;

  /// Set only on options a shared cross-source filter can broadcast.
  final FilterSemantic? semantic;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'FilterOption($id, $label)';
}

/// Sort option for Browse mode — `id` doubles as the l10n key.
class BrowseSortOption {
  const BrowseSortOption({
    required this.id,
    required this.apiValue,
  });

  final String id;
  final String apiValue;

  String label(S l) => switch (id) {
        'relevance' => l.browseSortRelevance,
        'popular' || 'popularity' => l.browseSortPopular,
        'top_rated' || 'rating' || 'score' => l.browseSortTopRated,
        'newest' => l.browseSortNewest,
        'most_voted' => l.browseSortMostVoted,
        'most_read' => l.browseSortMostRead,
        'trending' => l.browseSortTrending,
        'name_asc' => l.browseSortNameAsc,
        'name_desc' => l.browseSortNameDesc,
        'recently_updated' => l.browseSortRecentlyUpdated,
        'recently_added' => l.browseSortRecentlyAdded,
        _ => id,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrowseSortOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// One filter exposed by a [SearchSource].
abstract class SearchFilter {
  /// Identifier of the filter ("genre", "year", "platform").
  String get key;

  /// Label shown when no value is selected.
  String placeholder(S l);

  Future<List<FilterOption>> options(WidgetRef ref, S l);

  /// Separate from [key] when several filters share the same key but expose
  /// different option sets (e.g. genres for Movie vs TV vs IGDB).
  String get cacheKey => key;

  /// Non-null when options carry [FilterSemantic] and can fold into one
  /// cross-source control. Declared here so grouping stays synchronous.
  FilterSemanticFamily? get semanticFamily => null;

  /// True for filters with many options — turns on the in-dropdown search.
  bool get searchable => false;

  /// When `true`, the stored value is a `List<Object>`.
  bool get multiSelect => false;

  /// "All" (reset) option.
  FilterOption get allOption;

  /// Bespoke picker replacing the default dropdown; returns the new value or
  /// null to clear. Override only when the default UI is insufficient.
  Future<Object?> Function(BuildContext, WidgetRef, S, Object?)?
      get openCustomPicker => null;
}

/// Result of a Browse / Discover request (a filtered page of media).
class BrowseResult {
  const BrowseResult({
    required this.items,
    required this.mediaType,
    this.hasMore = false,
    this.totalPages = 1,
    this.currentPage = 1,
  });

  final List<Object> items;
  final MediaType mediaType;
  final bool hasMore;
  final int totalPages;
  final int currentPage;
}

/// One data source for the search screen. Each source declares its filter
/// set, fetch implementation, and UI metadata.
abstract class SearchSource {
  String get id;

  /// External data provider backing this source. Single source of truth
  /// for [iconAsset].
  DataSource get dataSource;

  String label(S l);

  IconData get icon;

  /// Brand PNG asset; rendered instead of [icon] when present. Defaults to
  /// [dataSource]'s brand asset.
  String? get iconAsset => dataSource.iconAsset;

  /// Filters in display order along the filter bar.
  List<SearchFilter> get filters;

  /// Whether the source supports filter-only browse without a text query.
  bool get supportsBrowse;

  /// Single entry point for both search (when [query] is non-empty) and
  /// browse (when it isn't). Each source decides how it combines them.
  Future<BrowseResult> fetch(
    Ref ref, {
    String? query,
    required Map<String, Object?> filterValues,
    required String sortBy,
    required int page,
  });

  /// Discover feed widget for the no-filters mode. Return null to opt out.
  Widget? buildDiscoverFeed(BuildContext context, WidgetRef ref);

  List<BrowseSortOption> get sortOptions;

  BrowseSortOption get defaultSort => sortOptions.first;

  /// Some APIs (TMDB) don't accept sort on search responses — defaulting
  /// to `false` disables the sort dropdown while a query is active.
  bool get supportsSortDuringSearch => false;

  static const Duration defaultSearchDebounce = Duration(milliseconds: 400);

  /// Search-as-you-type gap; rate-limited providers (MusicBrainz: <1 req/s)
  /// override it, and the screen takes the strictest enabled value.
  Duration get searchDebounce => defaultSearchDebounce;

  String searchHint(S l);

  /// May differ from the fetched model's runtime type — TMDB's anime tab
  /// fetches `Movie` / `TvShow` but stamps them [MediaType.animation].
  MediaType get outputMediaType;
}
