import 'package:core/models/item_mark.dart';
import 'package:core/models/marked_unit.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> row({Object? unitTitle}) => <String, dynamic>{
        'id': 7,
        'item_id': 3,
        'unit_type': kUnitEpisode,
        'parent_number': 1,
        'unit_number': 2,
        'is_favorite': 1,
        'user_comment': null,
        'liked_at': 1000,
        'updated_at': 1000,
        'unit_title': unitTitle,
      };

  group('MarkedUnit.fromDb', () {
    test('should read the mark and the joined title', () {
      final MarkedUnit unit = MarkedUnit.fromDb(row(unitTitle: ' Rains '));
      expect(unit.mark.id, 7);
      expect(unit.mark.itemId, 3);
      expect(unit.unitTitle, 'Rains');
    });

    test('should leave the title null when the join found nothing', () {
      expect(MarkedUnit.fromDb(row()).unitTitle, isNull);
    });

    test('should treat a blank title as absent', () {
      expect(MarkedUnit.fromDb(row(unitTitle: '   ')).unitTitle, isNull);
    });
  });
}
