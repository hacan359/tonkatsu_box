import 'package:core/models/media_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/search/models/search_source.dart';
import 'package:tonkatsu_box/features/search/sources/search_sources.dart';
import 'package:tonkatsu_box/features/wishlist/screens/wishlist_screen.dart';

void main() {
  group('wishlistMediaTypeFor', () {
    test('a book hint opens books, not the first registered type', () {
      expect(wishlistMediaTypeFor(MediaType.book), MediaType.book);
    });

    test('returns null for custom and for an absent hint', () {
      expect(wishlistMediaTypeFor(MediaType.custom), isNull);
      expect(wishlistMediaTypeFor(null), isNull);
    });

    test('every returned type has at least one registered source', () {
      for (final MediaType type in MediaType.values) {
        final MediaType? opened = wishlistMediaTypeFor(type);
        if (opened == null) continue;

        expect(
          searchSourcesFor(opened),
          isNotEmpty,
          reason: '$type opens $opened, which has no sources',
        );
        expect(
          searchSourcesFor(opened)
              .every((SearchSource s) => s.outputMediaType == opened),
          isTrue,
          reason: '$opened is served by a source of another media type',
        );
      }
    });

    test('a hint without sources never reaches the search tab', () {
      final Set<MediaType> searchable = searchableMediaTypes.toSet();
      for (final MediaType type in MediaType.values) {
        if (searchable.contains(type)) continue;
        expect(
          wishlistMediaTypeFor(type),
          isNull,
          reason: '$type has no sources but would still open search',
        );
      }
    });
  });
}
