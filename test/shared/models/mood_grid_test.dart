import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/models/mood_grid.dart';

void main() {
  group('MoodGrid', () {
    final DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(
      1_700_000_000 * 1000,
    );
    final DateTime updatedAt = DateTime.fromMillisecondsSinceEpoch(
      1_700_000_500 * 1000,
    );

    test('should round-trip through toDb / fromDb', () {
      final MoodGrid grid = MoodGrid(
        id: 7,
        name: 'My Grid',
        rows: 3,
        cols: 4,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final MoodGrid restored = MoodGrid.fromDb(grid.toDb());
      expect(restored.id, 7);
      expect(restored.name, 'My Grid');
      expect(restored.rows, 3);
      expect(restored.cols, 4);
      expect(restored.createdAt, createdAt);
      expect(restored.updatedAt, updatedAt);
    });

    test('should round-trip through toExport / fromExport', () {
      final MoodGrid grid = MoodGrid(
        id: 7,
        name: 'My Grid',
        rows: 2,
        cols: 2,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final MoodGrid restored = MoodGrid.fromExport(grid.toExport());
      expect(restored.name, grid.name);
      expect(restored.rows, grid.rows);
      expect(restored.cols, grid.cols);
      expect(restored.createdAt, grid.createdAt);
      expect(restored.updatedAt, grid.updatedAt);
    });

    test('cellCount returns rows * cols', () {
      final MoodGrid grid = MoodGrid(
        id: 1,
        name: '',
        rows: 4,
        cols: 5,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      expect(grid.cellCount, 20);
    });

    test('copyWith replaces only listed fields', () {
      final MoodGrid grid = MoodGrid(
        id: 1,
        name: 'a',
        rows: 1,
        cols: 1,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final MoodGrid copy = grid.copyWith(name: 'b', cols: 5);
      expect(copy.id, 1);
      expect(copy.name, 'b');
      expect(copy.cols, 5);
      expect(copy.rows, 1);
    });

    test('round-trips captionTemplate through toDb / fromDb', () {
      final MoodGrid grid = MoodGrid(
        id: 1,
        name: 'Captioned',
        rows: 1,
        cols: 1,
        captionTemplate: '{{name}} ({{year}})',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final MoodGrid restored = MoodGrid.fromDb(grid.toDb());
      expect(restored.captionTemplate, '{{name}} ({{year}})');
    });

    test('round-trips captionTemplate through toExport / fromExport', () {
      final MoodGrid grid = MoodGrid(
        id: 1,
        name: 'Captioned',
        rows: 1,
        cols: 1,
        captionTemplate: '{{name}}',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final MoodGrid restored = MoodGrid.fromExport(grid.toExport());
      expect(restored.captionTemplate, '{{name}}');
    });

    test('copyWith updates captionTemplate', () {
      final MoodGrid grid = MoodGrid(
        id: 1,
        name: 'a',
        rows: 1,
        cols: 1,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final MoodGrid withTemplate =
          grid.copyWith(captionTemplate: '{{name}}');
      expect(withTemplate.captionTemplate, '{{name}}');
    });

    test('copyWith clearCaptionTemplate resets to null', () {
      final MoodGrid grid = MoodGrid(
        id: 1,
        name: 'a',
        rows: 1,
        cols: 1,
        captionTemplate: '{{name}}',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final MoodGrid cleared = grid.copyWith(clearCaptionTemplate: true);
      expect(cleared.captionTemplate, isNull);
    });

    test('equality is based on id', () {
      final MoodGrid a = MoodGrid(
        id: 1,
        name: 'a',
        rows: 1,
        cols: 1,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final MoodGrid b = MoodGrid(
        id: 1,
        name: 'different name',
        rows: 9,
        cols: 9,
        createdAt: updatedAt,
        updatedAt: updatedAt,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
