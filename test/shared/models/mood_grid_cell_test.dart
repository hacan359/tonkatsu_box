import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/mood_grid_cell.dart';

void main() {
  group('MoodGridCell', () {
    test('should round-trip empty cell through toDb / fromDb', () {
      const MoodGridCell cell = MoodGridCell(
        id: 1,
        gridId: 10,
        position: 3,
        label: 'Favorite',
      );

      final MoodGridCell restored = MoodGridCell.fromDb(cell.toDb());
      expect(restored.id, 1);
      expect(restored.gridId, 10);
      expect(restored.position, 3);
      expect(restored.label, 'Favorite');
      expect(restored.mediaType, isNull);
      expect(restored.externalId, isNull);
      expect(restored.isEmpty, isTrue);
    });

    test('should round-trip filled cell through toDb / fromDb', () {
      const MoodGridCell cell = MoodGridCell(
        id: 1,
        gridId: 10,
        position: 3,
        label: 'Favorite Game',
        mediaType: MediaType.game,
        externalId: 12345,
        platformId: 6,
      );

      final MoodGridCell restored = MoodGridCell.fromDb(cell.toDb());
      expect(restored.mediaType, MediaType.game);
      expect(restored.externalId, 12345);
      expect(restored.platformId, 6);
      expect(restored.isEmpty, isFalse);
    });

    test('should round-trip through toExport / fromExport', () {
      const MoodGridCell cell = MoodGridCell(
        id: 99,
        gridId: 5,
        position: 0,
        label: 'X',
        mediaType: MediaType.anime,
        externalId: 100922,
      );

      // Export omits id / gridId; restore uses defaults for those.
      final MoodGridCell restored = MoodGridCell.fromExport(cell.toExport());
      expect(restored.position, 0);
      expect(restored.label, 'X');
      expect(restored.mediaType, MediaType.anime);
      expect(restored.externalId, 100922);
    });

    test('copyWith with clearItem drops media reference', () {
      const MoodGridCell cell = MoodGridCell(
        id: 1,
        gridId: 1,
        position: 0,
        mediaType: MediaType.anime,
        externalId: 100922,
        platformId: 1,
      );

      final MoodGridCell cleared = cell.copyWith(clearItem: true);
      expect(cleared.mediaType, isNull);
      expect(cleared.externalId, isNull);
      expect(cleared.platformId, isNull);
      expect(cleared.id, 1);
    });

    test('copyWith with clearLabel drops label', () {
      const MoodGridCell cell = MoodGridCell(
        id: 1,
        gridId: 1,
        position: 0,
        label: 'x',
      );

      final MoodGridCell cleared = cell.copyWith(clearLabel: true);
      expect(cleared.label, isNull);
    });

    test('isEmpty returns true when mediaType is set but externalId is null',
        () {
      const MoodGridCell partial = MoodGridCell(
        id: 1,
        gridId: 1,
        position: 0,
        mediaType: MediaType.anime,
      );
      expect(partial.isEmpty, isTrue);
    });
  });
}
