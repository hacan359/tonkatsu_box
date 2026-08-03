import 'dart:ui';

import 'package:core/models/tier_definition.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/constants/tier_definition_ui.dart';

void main() {
  group('TierDefinitionUi', () {
    test('color wraps the stored colorValue', () {
      const TierDefinition def = TierDefinition(
        tierKey: 'S',
        label: 'S',
        colorValue: 0xFFFF4444,
        sortOrder: 0,
      );

      expect(def.color, const Color(0xFFFF4444));
    });

    test('every default tier exposes a color', () {
      for (final TierDefinition def in TierDefinition.defaults) {
        expect(def.color, isA<Color>(), reason: def.tierKey);
      }
    });
  });
}
