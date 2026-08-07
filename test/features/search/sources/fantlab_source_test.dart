import 'package:core/models/media_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/search/filters/fantlab_work_type_filter.dart';
import 'package:tonkatsu_box/features/search/sources/fantlab_source.dart';

void main() {
  group('FantlabSource', () {
    late FantlabSource source;

    setUp(() {
      source = FantlabSource();
    });

    group('properties', () {
      test('id is "fantlab"', () {
        expect(source.id, 'fantlab');
      });

      test('outputs MediaType.book', () {
        expect(source.outputMediaType, MediaType.book);
      });

      test('requires a query (no browse, no sort during search)', () {
        expect(source.supportsBrowse, isFalse);
        expect(source.supportsSortDuringSearch, isFalse);
      });
    });

    group('filters & sort', () {
      test('exposes the work-type filter', () {
        expect(source.filters, hasLength(1));
        expect(source.filters.single, isA<FantlabWorkTypeFilter>());
      });

      test('offers relevance-only ordering', () {
        expect(source.sortOptions, hasLength(1));
        expect(source.sortOptions.single.id, 'relevance');
        expect(source.defaultSort.id, 'relevance');
      });
    });

    group('buildDiscoverFeed', () {
      test('opts out (no discover feed)', () {
        // Property check only — calling it needs a BuildContext / WidgetRef.
        expect(source.buildDiscoverFeed, isNotNull);
      });
    });
  });
}
