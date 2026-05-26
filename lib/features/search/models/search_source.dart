import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/media_type.dart';

/// TMDB's Animation genre id, used to keep animation out of generic
/// TV / movie searches.
const int tmdbAnimationGenreId = 16;

class FilterOption {
  const FilterOption({
    required this.id,
    required this.label,
    this.icon,
    this.value,
  });

  final String id;
  final String label;
  final IconData? icon;

  /// Raw value passed to the API for this option.
  final Object? value;

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
        'popular' || 'popularity' => l.browseSortPopular,
        'top_rated' || 'rating' || 'score' => l.browseSortTopRated,
        'newest' => l.browseSortNewest,
        'most_voted' => l.browseSortMostVoted,
        'trending' => l.browseSortTrending,
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

  /// True for filters with many options — turns on the in-dropdown search.
  bool get searchable => false;

  /// When `true`, the stored value is a `List<Object>`.
  bool get multiSelect => false;

  /// "All" (reset) option.
  FilterOption get allOption;

  /// Optional bespoke picker that replaces the default dropdown / searchable
  /// dialog. Return the new value (or `null` to clear), or leave [Future]
  /// resolved to a sentinel that the caller ignores. Override only when the
  /// default UI is insufficient (e.g. needs grouped categories).
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

  /// Logical group ('tmdb', 'igdb', 'anilist', 'vndb') used to cluster
  /// sources in the picker popup.
  String get groupId;

  String get groupName;
  IconData get groupIcon;

  /// Localised label.
  String label(S l);

  IconData get icon;

  /// Brand PNG asset; rendered instead of [icon] when present.
  String? get iconAsset => null;

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

  String searchHint(S l);

  /// MediaType stamped onto items added from this source. May differ from
  /// the runtime type of the fetched model — TMDB's anime tab fetches
  /// `Movie` / `TvShow` but classifies them as [MediaType.animation].
  MediaType get outputMediaType;
}
