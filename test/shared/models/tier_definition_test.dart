import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/tier_definition.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('TierDefinition', () {
    group('fromDb', () {
      test('должен создавать из записи БД', () {
        final TierDefinition def = TierDefinition.fromDb(<String, dynamic>{
          'tier_key': 'S',
          'label': 'S',
          'color': 0xFFFF4444,
          'sort_order': 0,
        });

        expect(def.tierKey, 'S');
        expect(def.label, 'S');
        expect(def.color, const Color(0xFFFF4444));
        expect(def.sortOrder, 0);
      });
    });

    group('toDb', () {
      test('должен сериализовать с tierListId', () {
        final TierDefinition def = createTestTierDefinition(
          tierKey: 'A',
          label: 'A',
          colorValue: 0xFFFF8C00,
          sortOrder: 1,
        );

        final Map<String, dynamic> db = def.toDb(42);
        expect(db['tier_list_id'], 42);
        expect(db['tier_key'], 'A');
        expect(db['label'], 'A');
        expect(db['color'], 0xFFFF8C00);
        expect(db['sort_order'], 1);
      });
    });

    group('toExport / fromExport', () {
      test('round-trip', () {
        final TierDefinition original = createTestTierDefinition(
          tierKey: 'B',
          label: 'Best',
          colorValue: 0xFFFFD700,
          sortOrder: 2,
        );

        final Map<String, dynamic> exported = original.toExport();
        final TierDefinition restored = TierDefinition.fromExport(exported);

        expect(restored.tierKey, original.tierKey);
        expect(restored.label, original.label);
        expect(restored.color, original.color);
        expect(restored.sortOrder, original.sortOrder);
      });
    });

    group('defaults', () {
      test('должен содержать 6 тиров', () {
        expect(TierDefinition.defaults, hasLength(6));
      });

      test('должен начинаться с S и заканчиваться F', () {
        expect(TierDefinition.defaults.first.tierKey, 'S');
        expect(TierDefinition.defaults.last.tierKey, 'F');
      });

      test('должен иметь последовательные sortOrder', () {
        for (int i = 0; i < TierDefinition.defaults.length; i++) {
          expect(TierDefinition.defaults[i].sortOrder, i);
        }
      });

      test('все тиры должны иметь уникальные ключи', () {
        final Set<String> keys =
            TierDefinition.defaults.map((TierDefinition d) => d.tierKey).toSet();
        expect(keys, hasLength(6));
      });
    });

    group('copyWith', () {
      test('должен копировать с изменённым label', () {
        final TierDefinition original = createTestTierDefinition(label: 'Old');
        final TierDefinition copy = original.copyWith(label: 'New');
        expect(copy.label, 'New');
        expect(copy.tierKey, original.tierKey);
      });

      test('должен копировать с изменённым color', () {
        final TierDefinition original = createTestTierDefinition();
        final TierDefinition copy =
            original.copyWith(color: const Color(0xFF00FF00));
        expect(copy.color, const Color(0xFF00FF00));
      });
    });

    group('equality', () {
      test('равенство по tierKey', () {
        final TierDefinition a = createTestTierDefinition(
          tierKey: 'S',
          label: 'Super',
        );
        final TierDefinition b = createTestTierDefinition(
          tierKey: 'S',
          label: 'Stellar',
        );
        expect(a, equals(b));
      });

      test('неравенство при разных tierKey', () {
        final TierDefinition a = createTestTierDefinition(tierKey: 'S');
        final TierDefinition b = createTestTierDefinition(tierKey: 'A');
        expect(a, isNot(equals(b)));
      });
    });
  });
}
