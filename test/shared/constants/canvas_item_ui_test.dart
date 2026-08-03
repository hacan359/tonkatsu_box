import 'package:core/models/canvas_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/constants/canvas_item_ui.dart';

void main() {
  group('CanvasItemUi', () {
      test('mediaPlaceholderIcon should return Icons.menu_book', () {
        final CanvasItem item = CanvasItem(
          id: 1,
          collectionId: 10,
          itemType: CanvasItemType.visualNovel,
          x: 0,
          y: 0,
          createdAt: DateTime(2024, 1, 15),
        );
        expect(item.mediaPlaceholderIcon, Icons.menu_book);
      });
  });
}
