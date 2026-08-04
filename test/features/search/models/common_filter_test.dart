import 'package:core/models/media_type.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/search/models/common_filter.dart';
import 'package:tonkatsu_box/features/search/models/search_source.dart';
import 'package:tonkatsu_box/features/search/sources/search_sources.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  // Real localizations rather than a mock: the fold joins options by semantic
  // and takes labels from them, so every member's label must resolve.
  final S l = lookupS(const Locale('en'));

  group('filtersForMediaType', () {
    test('folds a family only when two or more sources know it', () {
      final MediaTypeFilters manga = filtersForMediaType(MediaType.manga);

      expect(
        manga.common.map((CommonFilter f) => f.family),
        <FilterSemanticFamily>[
          FilterSemanticFamily.status,
          FilterSemanticFamily.format,
        ],
      );
    });

    test('a single-source type folds nothing and keeps every filter private',
        () {
      final MediaTypeFilters game = filtersForMediaType(MediaType.game);

      expect(game.common, isEmpty);
      expect(game.own['games'], hasLength(5));
      expect(game.ownCount, 5);
    });

    test('a folded filter leaves the source\'s private set', () {
      final MediaTypeFilters manga = filtersForMediaType(MediaType.manga);
      final List<String> anilistOwn = manga.own['manga']!
          .map((SearchFilter f) => f.key)
          .toList();

      // status and format went shared; genre, tag and year stay AniList's.
      expect(anilistOwn, isNot(contains('status')));
      expect(anilistOwn, isNot(contains('format')));
      expect(anilistOwn, containsAll(<String>['genre', 'tag', 'year']));
      // Kitsu contributes both of its filters to the shared controls.
      expect(manga.own['kitsu_manga'], isEmpty);
    });

    test('every filter of every source stays reachable', () {
      for (final MediaType type in searchableMediaTypes) {
        final MediaTypeFilters layout = filtersForMediaType(type);
        for (final SearchSource source in searchSourcesFor(type)) {
          final Set<String> reachable = <String>{
            for (final SearchFilter f in layout.own[source.id]!) f.key,
            for (final CommonFilter common in layout.common)
              for (final CommonFilterMember member in common.members)
                if (member.sourceId == source.id) member.filter.key,
          };

          expect(
            reachable,
            source.filters.map((SearchFilter f) => f.key).toSet(),
            reason: '${source.id} lost a filter in the ${type.name} layout',
          );
        }
      }
    });

    test('is memoized so option loading keys off stable instances', () {
      expect(
        filtersForMediaType(MediaType.manga),
        same(filtersForMediaType(MediaType.manga)),
      );
    });
  });

  group('CommonFilter', () {
    late CommonFilter status;
    late CommonFilter format;

    setUp(() {
      final MediaTypeFilters manga = filtersForMediaType(MediaType.manga);
      status = manga.common.firstWhere(
        (CommonFilter f) => f.family == FilterSemanticFamily.status,
      );
      format = manga.common.firstWhere(
        (CommonFilter f) => f.family == FilterSemanticFamily.format,
      );
    });

    test('keys off its family so state survives a rebuild', () {
      expect(status.key, 'status');
      expect(status.cacheKey, 'common_status');
      expect(status.semanticFamily, FilterSemanticFamily.status);
    });

    test('every offered value maps to at least one source', () async {
      final MockWidgetRef ref = MockWidgetRef();

      for (final CommonFilter filter in <CommonFilter>[status, format]) {
        final CommonFilterOptions loaded = await filter.load(ref, l);

        expect(loaded.display, isNotEmpty);
        for (final FilterOption option in loaded.display) {
          final Map<String, CommonFilterTarget>? targets =
              loaded.bySource[option.semantic];
          expect(
            targets,
            isNotNull,
            reason: '${option.id} is offered with no source behind it',
          );
          expect(targets, isNotEmpty);
        }
      }
    });

    test('a target repeats the source\'s own key and raw value', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final CommonFilterOptions loaded = await format.load(ref, l);
      final Map<String, CommonFilterTarget> manga =
          loaded.bySource[FilterSemantic.typeManga]!;

      // Same question, three different spellings on the wire.
      expect(manga['manga'], (filterKey: 'format', value: 'MANGA'));
      expect(manga['kitsu_manga'], (filterKey: 'subtype', value: 'manga'));
      expect(manga['mangabaka'], (filterKey: 'type', value: 'manga'));
    });

    test('a source that cannot answer a value is absent from it', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final CommonFilterOptions loaded = await status.load(ref, l);

      // Only AniList and Kitsu have an "announced but unpublished" status.
      expect(
        loaded.bySource[FilterSemantic.statusNotYetReleased]!.keys.toSet(),
        <String>{'manga', 'kitsu_manga'},
      );
      // Kitsu has no hiatus, MangaBaka no cancelled.
      expect(
        loaded.bySource[FilterSemantic.statusHiatus]!.keys,
        isNot(contains('kitsu_manga')),
      );
      expect(
        loaded.bySource[FilterSemantic.statusCancelled]!.keys,
        isNot(contains('mangabaka')),
      );
    });

    test('every value a member declares survives the fold', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final CommonFilterOptions loaded = await status.load(ref, l);

      for (final CommonFilterMember member in status.members) {
        for (final FilterOption own in await member.filter.options(ref, l)) {
          expect(
            loaded.bySource[own.semantic]?[member.sourceId],
            (filterKey: member.filter.key, value: own.value),
            reason: '${member.sourceId} lost ${own.id} in the fold',
          );
        }
      }
    });

    test('the display list carries one entry per semantic', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final CommonFilterOptions loaded = await status.load(ref, l);

      final List<FilterSemantic?> semantics =
          loaded.display.map((FilterOption o) => o.semantic).toList();
      expect(semantics.toSet(), hasLength(semantics.length));
      expect(loaded.display.map((FilterOption o) => o.value), semantics);
    });

    test('the reset option clears the pick', () {
      expect(status.allOption.value, isNull);
    });
  });
}
