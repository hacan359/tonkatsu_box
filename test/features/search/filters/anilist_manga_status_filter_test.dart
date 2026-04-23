import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/features/search/filters/anilist_manga_status_filter.dart';
import 'package:xerabora/features/search/models/search_source.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('AniListMangaStatusFilter', () {
    late AniListMangaStatusFilter filter;
    late MockS mockL;

    setUp(() {
      filter = AniListMangaStatusFilter();
      mockL = MockS();
      when(() => mockL.animeFilterStatus).thenReturn('Status');
      when(() => mockL.mangaStatusPublishing).thenReturn('Publishing');
      when(() => mockL.mangaStatusFinished).thenReturn('Finished');
      when(() => mockL.mangaStatusNotYetPublished)
          .thenReturn('Not yet published');
      when(() => mockL.mangaStatusCancelled).thenReturn('Cancelled');
      when(() => mockL.mangaStatusHiatus).thenReturn('Hiatus');
    });

    test('key is "status" — binds to AniList MediaStatus', () {
      expect(filter.key, 'status');
    });

    test('allOption clears the filter', () {
      expect(filter.allOption.value, isNull);
    });

    test(
        'options cover all 5 MediaStatus values including HIATUS (manga-specific)',
        () async {
      final MockWidgetRef ref = MockWidgetRef();
      final List<FilterOption> opts = await filter.options(ref, mockL);

      expect(opts.map((FilterOption o) => o.value).toList(), <String>[
        'RELEASING',
        'FINISHED',
        'NOT_YET_RELEASED',
        'CANCELLED',
        'HIATUS',
      ]);
    });
  });
}
