import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/statistics/widgets/stats_cards.dart';
import 'package:tonkatsu_box/shared/models/item_status.dart';

void main() {
  group('StatusCountsX', () {
    group('sortedSegments', () {
      test('should order by status priority and drop zero counts', () {
        final Map<ItemStatus, int> counts = <ItemStatus, int>{
          ItemStatus.completed: 3,
          ItemStatus.dropped: 0,
          ItemStatus.inProgress: 1,
          ItemStatus.planned: 2,
        };

        expect(
          counts.sortedSegments.map((MapEntry<ItemStatus, int> e) => e.key),
          <ItemStatus>[
            ItemStatus.inProgress,
            ItemStatus.planned,
            ItemStatus.completed,
          ],
        );
      });

      test('should return an empty list for an empty map', () {
        expect(<ItemStatus, int>{}.sortedSegments, isEmpty);
      });
    });

    group('completedPercent', () {
      test('should round the completed share of all counted items', () {
        final Map<ItemStatus, int> counts = <ItemStatus, int>{
          ItemStatus.completed: 1,
          ItemStatus.inProgress: 2,
        };

        expect(counts.completedPercent, 33);
      });

      test('should return zero when the map is empty', () {
        expect(<ItemStatus, int>{}.completedPercent, 0);
      });

      test('should return zero when nothing is completed', () {
        expect(
          <ItemStatus, int>{ItemStatus.planned: 5}.completedPercent,
          0,
        );
      });
    });
  });
}
