import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/search/filters/anilist_studio_filter.dart';
import 'package:tonkatsu_box/features/search/filters/anilist_tag_filter.dart';
import 'package:tonkatsu_box/features/search/utils/filter_ui.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';

void main() {
  late S l;

  setUpAll(() async {
    l = await S.delegate.load(const Locale('en'));
  });

  group('AniListStudioFilter', () {
    final AniListStudioFilter filter = AniListStudioFilter();

    test('is a single-select, exclusive filter with a custom picker', () {
      expect(filter.key, AniListStudioFilter.filterKey);
      expect(filter.multiSelect, isFalse);
      expect(filter.exclusive, isTrue);
      expect(filter.openCustomPicker, isNotNull);
      expect(filter.allOption.value, isNull);
    });

    test('cache key does not collide with the MusicBrainz studio filter', () {
      expect(filter.cacheKey, isNot(filter.key));
    });
  });

  group('exclusiveBlockReason', () {
    final AniListStudioFilter studio = AniListStudioFilter();
    final AniListTagFilter tag = AniListTagFilter(forAnime: true);

    test('returns null when no exclusive filter is set', () {
      expect(exclusiveBlockReason(null, tag, l), isNull);
    });

    test('returns null for the exclusive filter itself', () {
      expect(exclusiveBlockReason(studio, studio, l), isNull);
    });

    test('names the exclusive filter for every other filter', () {
      final String? reason = exclusiveBlockReason(studio, tag, l);
      expect(reason, isNotNull);
      expect(reason, contains(studio.placeholder(l)));
    });
  });

  group('SearchFilter.exclusive default', () {
    test('is false for an ordinary filter', () {
      expect(AniListTagFilter().exclusive, isFalse);
    });
  });
}
