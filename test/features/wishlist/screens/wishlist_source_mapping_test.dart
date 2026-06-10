import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/search/models/search_source.dart';
import 'package:tonkatsu_box/features/search/sources/search_sources.dart';
import 'package:tonkatsu_box/features/wishlist/screens/wishlist_screen.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

void main() {
  group('wishlistSourceIdFor', () {
    test('maps book hint to a books source, not movies', () {
      expect(wishlistSourceIdFor(MediaType.book), 'openlibrary');
    });

    test('returns null for custom and for an absent hint', () {
      expect(wishlistSourceIdFor(MediaType.custom), isNull);
      expect(wishlistSourceIdFor(null), isNull);
    });

    test('every non-null id resolves to a real source of that media type',
        () {
      final Set<String> known =
          searchSources.map((SearchSource s) => s.id).toSet();

      for (final MediaType type in MediaType.values) {
        final String? id = wishlistSourceIdFor(type);
        if (id == null) continue;

        expect(
          known,
          contains(id),
          reason: '$type maps to "$id" which is not a registered source',
        );
        expect(
          getSearchSourceById(id).id,
          id,
          reason: '$type -> "$id" fell back to a different source',
        );
        expect(
          getSearchSourceById(id).outputMediaType,
          type,
          reason: '$type -> "$id" outputs a different media type',
        );
      }
    });
  });
}
