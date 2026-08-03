import 'package:core/models/item_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/constants/item_status_ui.dart';

void main() {
  group('ItemStatusUi', () {
    group('color', () {
      test('каждый статус возвращает ненулевой цвет', () {
        for (final ItemStatus status in ItemStatus.values) {
          expect(status.color, isNotNull, reason: '${status.name} color');
        }
      });
    });

    group('materialIcon', () {
      test('все иконки уникальны (пользователь должен различать статусы)', () {
        final Set<IconData> icons = <IconData>{};
        for (final ItemStatus status in ItemStatus.values) {
          expect(icons.add(status.materialIcon), isTrue,
              reason: '${status.name} materialIcon should be unique');
        }
      });
    });
  });
}
