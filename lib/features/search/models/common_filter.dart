import 'package:core/models/media_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;

import '../../../l10n/app_localizations.dart';
import '../sources/search_sources.dart';
import 'search_source.dart';

/// One source's filter behind a [CommonFilter].
typedef CommonFilterMember = ({String sourceId, SearchFilter filter});

/// How one source spells a picked value: its own filter key plus the raw API
/// value, because the key differs too (`format` / `type` / `subtype`).
typedef CommonFilterTarget = ({String filterKey, Object? value});

/// Resolved contents of a [CommonFilter].
class CommonFilterOptions {
  const CommonFilterOptions({required this.display, required this.bySource});

  /// Union of the members' options; each carries its [FilterSemantic] as value.
  final List<FilterOption> display;

  /// Semantic → the sources that know it and how each spells it. A source
  /// absent from an entry cannot answer that value and drops out of the query.
  final Map<FilterSemantic, Map<String, CommonFilterTarget>> bySource;

  static const CommonFilterOptions empty = CommonFilterOptions(
    display: <FilterOption>[],
    bySource: <FilterSemantic, Map<String, CommonFilterTarget>>{},
  );
}

/// One control standing in for the same filter across several sources of a
/// media type — four spellings of "Publishing" become one "Status".
class CommonFilter extends SearchFilter {
  CommonFilter({required this.family, required this.members});

  final FilterSemanticFamily family;
  final List<CommonFilterMember> members;

  @override
  String get key => family.name;

  @override
  String get cacheKey => 'common_${family.name}';

  @override
  FilterSemanticFamily? get semanticFamily => family;

  /// Borrowed from the first member, so the wording stays the one users of that
  /// media type already see.
  @override
  String placeholder(S l) => members.first.filter.placeholder(l);

  @override
  FilterOption get allOption =>
      const FilterOption(id: 'any', label: 'All', value: null);

  @override
  Future<List<FilterOption>> options(WidgetRef ref, S l) async =>
      (await load(ref, l)).display;

  /// Loads every member's options once and joins them by semantic. The label of
  /// a value comes from the first member offering it — no new ARB strings.
  Future<CommonFilterOptions> load(WidgetRef ref, S l) async {
    final List<FilterOption> display = <FilterOption>[];
    final Map<FilterSemantic, Map<String, CommonFilterTarget>> bySource =
        <FilterSemantic, Map<String, CommonFilterTarget>>{};

    for (final CommonFilterMember member in members) {
      final List<FilterOption> memberOptions =
          await member.filter.options(ref, l);
      for (final FilterOption option in memberOptions) {
        final FilterSemantic? semantic = option.semantic;
        if (semantic == null) continue;

        (bySource[semantic] ??= <String, CommonFilterTarget>{})[member.sourceId] =
            (filterKey: member.filter.key, value: option.value);

        if (!display.any((FilterOption d) => d.semantic == semantic)) {
          display.add(
            FilterOption(
              id: semantic.name,
              label: option.label,
              value: semantic,
              semantic: semantic,
            ),
          );
        }
      }
    }

    return CommonFilterOptions(display: display, bySource: bySource);
  }
}

/// Filter layout of one media type: shared controls plus what stays private to
/// each source.
class MediaTypeFilters {
  const MediaTypeFilters({required this.common, required this.own});

  final List<CommonFilter> common;

  /// Source id → its filters that were not folded into [common].
  final Map<String, List<SearchFilter>> own;

  int get ownCount =>
      own.values.fold(0, (int sum, List<SearchFilter> f) => sum + f.length);
}

final Map<MediaType, MediaTypeFilters> _byMediaType =
    <MediaType, MediaTypeFilters>{};

/// Memoized: `SearchSource.filters` builds fresh objects on every call, and the
/// bar keys its option-loading state off these instances.
MediaTypeFilters filtersForMediaType(MediaType type) =>
    _byMediaType[type] ??= _buildFilters(type);

MediaTypeFilters _buildFilters(MediaType type) {
  final Map<String, List<SearchFilter>> perSource = <String, List<SearchFilter>>{
    for (final SearchSource source in searchSourcesFor(type))
      source.id: source.filters,
  };

  final Map<FilterSemanticFamily, List<CommonFilterMember>> byFamily =
      <FilterSemanticFamily, List<CommonFilterMember>>{};
  perSource.forEach((String sourceId, List<SearchFilter> filters) {
    for (final SearchFilter filter in filters) {
      final FilterSemanticFamily? family = filter.semanticFamily;
      if (family == null) continue;
      (byFamily[family] ??= <CommonFilterMember>[])
          .add((sourceId: sourceId, filter: filter));
    }
  });

  // A family only one source knows stays private — folding buys nothing and
  // would hide which provider it belongs to.
  final List<CommonFilter> common = <CommonFilter>[];
  final Set<FilterSemanticFamily> folded = <FilterSemanticFamily>{};
  for (final FilterSemanticFamily family in FilterSemanticFamily.values) {
    final List<CommonFilterMember>? members = byFamily[family];
    if (members == null || members.length < 2) continue;
    common.add(CommonFilter(family: family, members: members));
    folded.add(family);
  }

  return MediaTypeFilters(
    common: List<CommonFilter>.unmodifiable(common),
    own: Map<String, List<SearchFilter>>.unmodifiable(
      <String, List<SearchFilter>>{
        for (final MapEntry<String, List<SearchFilter>> entry
            in perSource.entries)
          entry.key: List<SearchFilter>.unmodifiable(
            entry.value.where(
              (SearchFilter f) =>
                  f.semanticFamily == null || !folded.contains(f.semanticFamily),
            ),
          ),
      },
    ),
  );
}
