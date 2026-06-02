import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/context_menu_item.dart';

void main() {
  group('contextMenuItem', () {
    test('should pass the value through to the PopupMenuItem', () {
      final PopupMenuItem<String> entry = contextMenuItem<String>(
        value: 'remove',
        icon: Icons.delete,
        label: 'Remove',
      );

      expect(entry.value, 'remove');
    });

    test('should be enabled so it can be selected', () {
      final PopupMenuItem<String> entry = contextMenuItem<String>(
        value: 'move',
        icon: Icons.drive_file_move_outlined,
        label: 'Move',
      );

      expect(entry.enabled, isTrue);
    });
  });
}
