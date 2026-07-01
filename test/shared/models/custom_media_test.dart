import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/models/custom_media.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

void main() {
  group('CustomMedia.isLocalCover', () {
    test('true only for the local:// scheme', () {
      expect(CustomMedia.isLocalCover(CustomMedia.localCoverMarker), isTrue);
      expect(CustomMedia.isLocalCover('local://anything'), isTrue);
      expect(CustomMedia.isLocalCover('https://x/cover.jpg'), isFalse);
      expect(CustomMedia.isLocalCover(null), isFalse);
      expect(CustomMedia.isLocalCover(''), isFalse);
    });
  });

  group('genreList', () {
    test('splits and trims a comma list', () {
      const CustomMedia m = CustomMedia(
        id: 1,
        title: 't',
        genres: 'RPG, Action ,  Puzzle',
      );
      expect(m.genreList, <String>['RPG', 'Action', 'Puzzle']);
    });

    test('null genres give a null list', () {
      const CustomMedia m = CustomMedia(id: 1, title: 't');
      expect(m.genreList, isNull);
    });
  });

  group('db mapping', () {
    test('fromDb reads displayType and fields', () {
      final CustomMedia m = CustomMedia.fromDb(<String, dynamic>{
        'id': 5,
        'title': 'My Thing',
        'display_type': 'game',
        'year': 1999,
        'platform_name': 'Homebrew',
      });
      expect(m.id, 5);
      expect(m.title, 'My Thing');
      expect(m.displayType, MediaType.game);
      expect(m.year, 1999);
      expect(m.platformName, 'Homebrew');
    });

    test('fromDb leaves displayType null when absent', () {
      final CustomMedia m = CustomMedia.fromDb(<String, dynamic>{
        'id': 1,
        'title': 't',
      });
      expect(m.displayType, isNull);
    });

    test('toDb serialises displayType to its value', () {
      const CustomMedia m = CustomMedia(
        id: 1,
        title: 't',
        displayType: MediaType.movie,
        cachedAt: 123,
      );
      final Map<String, dynamic> db = m.toDb();
      expect(db['display_type'], 'movie');
      expect(db['cached_at'], 123);
    });

    test('toDb defaults cached_at to now when not set', () {
      const CustomMedia m = CustomMedia(id: 1, title: 't');
      final Object? cachedAt = m.toDb()['cached_at'];
      expect(cachedAt, isA<int>());
      expect(cachedAt! as int, greaterThan(0));
    });

    test('toExport drops cached_at', () {
      const CustomMedia m = CustomMedia(id: 1, title: 't', cachedAt: 99);
      expect(m.toExport().containsKey('cached_at'), isFalse);
      expect(m.toExport()['title'], 't');
    });

    test('fromDb reads platform_id, format and unit totals', () {
      final CustomMedia m = CustomMedia.fromDb(<String, dynamic>{
        'id': 5,
        'title': 'Homebrew',
        'display_type': 'game',
        'platform_id': 48,
        'format': 'MANHWA',
        'unit_total': 24,
        'unit_group_total': 2,
      });
      expect(m.platformId, 48);
      expect(m.format, 'MANHWA');
      expect(m.unitTotal, 24);
      expect(m.unitGroupTotal, 2);
    });

    test('round-trips platform_id, format and unit totals through toDb', () {
      const CustomMedia m = CustomMedia(
        id: 1,
        title: 't',
        displayType: MediaType.manga,
        platformId: 7,
        format: 'OVA',
        unitTotal: 12,
        unitGroupTotal: 3,
      );
      final CustomMedia restored = CustomMedia.fromDb(m.toDb());
      expect(restored.platformId, 7);
      expect(restored.format, 'OVA');
      expect(restored.unitTotal, 12);
      expect(restored.unitGroupTotal, 3);
    });

    test('toExport carries the new fields', () {
      const CustomMedia m = CustomMedia(
        id: 1,
        title: 't',
        platformId: 48,
        format: 'MANHWA',
        unitTotal: 24,
        unitGroupTotal: 2,
      );
      final Map<String, dynamic> export = m.toExport();
      expect(export['platform_id'], 48);
      expect(export['format'], 'MANHWA');
      expect(export['unit_total'], 24);
      expect(export['unit_group_total'], 2);
    });
  });

  group('copyWith', () {
    test('clear flags null out fields', () {
      const CustomMedia m = CustomMedia(
        id: 1,
        title: 't',
        displayType: MediaType.game,
        platformName: 'PC',
      );
      final CustomMedia cleared =
          m.copyWith(clearDisplayType: true, clearPlatformName: true);
      expect(cleared.displayType, isNull);
      expect(cleared.platformName, isNull);
      expect(cleared.title, 't');
    });

    test('updates a single field', () {
      const CustomMedia m = CustomMedia(id: 1, title: 'old');
      expect(m.copyWith(title: 'new').title, 'new');
    });

    test('clear flags null out the new fields', () {
      const CustomMedia m = CustomMedia(
        id: 1,
        title: 't',
        platformId: 48,
        format: 'OVA',
        unitTotal: 12,
        unitGroupTotal: 3,
      );
      final CustomMedia cleared = m.copyWith(
        clearPlatformId: true,
        clearFormat: true,
        clearUnitTotal: true,
        clearUnitGroupTotal: true,
      );
      expect(cleared.platformId, isNull);
      expect(cleared.format, isNull);
      expect(cleared.unitTotal, isNull);
      expect(cleared.unitGroupTotal, isNull);
    });
  });
}
