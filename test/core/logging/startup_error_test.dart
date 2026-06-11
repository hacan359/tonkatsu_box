import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/logging/startup_error.dart';
import 'package:tonkatsu_box/shared/theme/app_theme.dart';

void main() {
  const StartupErrorInfo info = StartupErrorInfo(
    source: 'zone',
    error: 'Boom',
    stack: '#0 main (package:tonkatsu_box/main.dart:1:1)',
  );

  group('StartupErrorInfo', () {
    test('details joins source, error and stack', () {
      expect(info.details, contains('source: zone'));
      expect(info.details, contains('Boom'));
      expect(info.details, contains('#0 main'));
    });
  });

  group('recordStartupError', () {
    tearDown(() => startupError.value = null);

    test('first error wins, follow-ups are ignored', () {
      final StartupErrorInfo first =
          recordStartupError('database', StateError('first'), null);
      final StartupErrorInfo second =
          recordStartupError('zone', StateError('second'), null);

      expect(second, same(first));
      expect(startupError.value, same(first));
      expect(startupError.value?.source, 'database');
    });
  });

  group('StartupErrorView', () {
    // The real app theme is essential here: it forces an infinite
    // minimumSize on FilledButton, which used to blow up the copy button
    // inside the header Row ("BoxConstraints forces an infinite width").
    Widget app() => MaterialApp(
          theme: AppTheme.darkTheme,
          home: const StartupErrorView(info: info),
        );

    testWidgets('should render under the app theme without layout exceptions',
        (WidgetTester tester) async {
      await tester.pumpWidget(app());

      expect(tester.takeException(), isNull);
      expect(find.text('Boom'), findsOneWidget);
      expect(find.textContaining('zone'), findsOneWidget);
    });

    testWidgets('should copy details to clipboard on button tap',
        (WidgetTester tester) async {
      final List<MethodCall> calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      await tester.pumpWidget(app());
      await tester.tap(find.byType(FilledButton));
      // Let the "Copied" confirmation timer expire.
      await tester.pump(const Duration(seconds: 3));

      expect(tester.takeException(), isNull);
      final MethodCall copy = calls
          .firstWhere((MethodCall c) => c.method == 'Clipboard.setData');
      expect(
        (copy.arguments as Map<Object?, Object?>)['text'],
        info.details,
      );
    });
  });
}
