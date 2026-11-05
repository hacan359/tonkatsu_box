import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/navigation/frame_chrome.dart';

void main() {
  group('FrameChromeController', () {
    late FrameChromeController controller;
    final Object title = Object();
    final Object strip = Object();
    const Widget center = SizedBox();

    setUp(() => controller = FrameChromeController());
    tearDown(() => controller.dispose());

    test('пустой контроллер ничего не отдаёт', () {
      expect(controller.current, isNull);
    });

    test('заголовок старшего и центр младшего, порядок set не важен', () {
      controller.set(strip, const FrameChrome(center: center));
      controller.set(title, const FrameChrome(title: 'T', priority: 1));
      expect(controller.current?.title, 'T');
      expect(controller.current?.center, same(center));

      final FrameChromeController reversed = FrameChromeController();
      reversed.set(title, const FrameChrome(title: 'T', priority: 1));
      reversed.set(strip, const FrameChrome(center: center));
      expect(reversed.current?.title, 'T');
      expect(reversed.current?.center, same(center));
      reversed.dispose();
    });

    test('старший приоритет побеждает по полю, не по арендатору', () {
      controller.set(title, const FrameChrome(title: 'page', priority: 1));
      controller.set(strip, const FrameChrome(title: 'strip'));
      expect(controller.current?.title, 'page');

      controller.set(strip, const FrameChrome(title: 'strip', priority: 2));
      expect(controller.current?.title, 'strip');
    });

    test('should keep mount order for equal priorities', () {
      final List<Object> owners = List<Object>.generate(40, (_) => Object());
      for (int i = 0; i < owners.length; i++) {
        controller.set(owners[i], FrameChrome(title: 't$i'));
      }
      expect(controller.current?.title, 't39');

      controller.set(owners.first, const FrameChrome(title: 'again'));
      expect(controller.current?.title, 't39');
    });

    test('clear одного оставляет поля другого', () {
      controller.set(strip, const FrameChrome(center: center));
      controller.set(title, const FrameChrome(title: 'T', priority: 1));

      controller.clear(title);
      expect(controller.current?.title, isNull);
      expect(controller.current?.center, same(center));

      controller.clear(strip);
      expect(controller.current, isNull);
    });

    test('уведомляет слушателей на set и clear', () {
      int calls = 0;
      controller.addListener(() => calls++);
      controller.set(title, const FrameChrome(title: 'T'));
      controller.clear(title);
      expect(calls, 2);
    });

    test('после dispose set и clear не бросают', () {
      final FrameChromeController gone = FrameChromeController()..dispose();
      expect(
        () => gone.set(title, const FrameChrome(title: 'T')),
        returnsNormally,
      );
      expect(() => gone.clear(title), returnsNormally);
    });
  });
}
