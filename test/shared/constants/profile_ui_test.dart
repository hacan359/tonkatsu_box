import 'dart:ui';

import 'package:core/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/constants/profile_ui.dart';
import 'package:tonkatsu_box/shared/utils/color_hex.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ProfileUi', () {
    group('displayColor', () {
      test('should convert hex with hash to Color', () {
        final Profile profile = createTestProfile(color: '#EF7B44');
        expect(profile.displayColor, const Color(0xFFEF7B44));
      });

      test('should handle lowercase hex', () {
        final Profile profile = createTestProfile(color: '#abcdef');
        expect(profile.displayColor, const Color(0xFFABCDEF));
      });
    });

    group('hexToColor', () {
      test('should convert hex with hash prefix', () {
        expect(ColorHex.fromHex('#FF0000'), const Color(0xFFFF0000));
      });

      test('should convert hex without hash prefix', () {
        expect(ColorHex.fromHex('00FF00'), const Color(0xFF00FF00));
      });
    });
  });
}
