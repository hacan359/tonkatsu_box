import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/features/search/filters/anilist_anime_format_filter.dart';
import 'package:xerabora/features/search/models/search_source.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('AniListAnimeFormatFilter', () {
    late AniListAnimeFormatFilter filter;
    late MockS mockL;

    setUp(() {
      filter = AniListAnimeFormatFilter();
      mockL = MockS();
      when(() => mockL.browseFilterFormat).thenReturn('Format');
      when(() => mockL.animeFormatTv).thenReturn('TV');
      when(() => mockL.animeFormatMovie).thenReturn('Movie');
      when(() => mockL.animeFormatOva).thenReturn('OVA');
      when(() => mockL.animeFormatOna).thenReturn('ONA');
      when(() => mockL.animeFormatSpecial).thenReturn('Special');
      when(() => mockL.animeFormatTvShort).thenReturn('TV Short');
    });

    test('key is "format" — binds to AniList MediaFormat', () {
      expect(filter.key, 'format');
    });

    test('allOption clears the filter', () {
      expect(filter.allOption.value, isNull);
    });

    test('options expose six anime-specific formats', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final List<FilterOption> opts = await filter.options(ref, mockL);

      expect(opts.map((FilterOption o) => o.value).toList(), <String>[
        'TV',
        'MOVIE',
        'OVA',
        'ONA',
        'SPECIAL',
        'TV_SHORT',
      ]);
    });
  });
}
