import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/constants/platform_features.dart';

void main() {
  group('platform_features', () {
    group('kCanvasEnabled', () {
      test('should always be true', () {
        expect(kCanvasEnabled, isTrue);
      });
    });

    group('kVgMapsEnabled', () {
      test('should match Platform.isWindows', () {
        expect(kVgMapsEnabled, equals(Platform.isWindows));
      });

      test('should be true on Windows test runner', () {
        // Тесты запускаются на Windows — kVgMapsEnabled == true
        if (Platform.isWindows) {
          expect(kVgMapsEnabled, isTrue);
        }
      });
    });

    group('kScreenshotEnabled', () {
      test('should match Platform.isWindows', () {
        expect(kScreenshotEnabled, equals(Platform.isWindows));
      });
    });

    group('kIsMobile', () {
      test('should be true only on Android or iOS', () {
        expect(kIsMobile, equals(Platform.isAndroid || Platform.isIOS));
      });

      test('should be false on desktop test runner', () {
        // Тесты запускаются на desktop — kIsMobile == false
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          expect(kIsMobile, isFalse);
        }
      });
    });

    group('isLandscapeMobile', () {
      testWidgets('should return false on desktop', (WidgetTester tester) async {
        late bool result;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(1280, 720),
            ),
            child: Builder(
              builder: (BuildContext context) {
                result = isLandscapeMobile(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        // На desktop всегда false (kIsMobile == false)
        expect(result, isFalse);
      });

      testWidgets('should return false on desktop even with landscape orientation',
          (WidgetTester tester) async {
        late bool result;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(1280, 720), // landscape aspect ratio
            ),
            child: Builder(
              builder: (BuildContext context) {
                result = isLandscapeMobile(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        // На desktop всегда false независимо от ориентации
        expect(result, isFalse);
      });
    });
  });
}
