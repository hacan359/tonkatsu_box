import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/widgets/api_error_display.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ApiErrorDisplay', () {
    testWidgets('shows the message and no copy button without a detail',
        (WidgetTester t) async {
      await t.pumpApp(
        const ApiErrorDisplay(message: 'Network down'),
        wrapInScaffold: true,
      );

      expect(find.text('Network down'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsNothing);
    });

    testWidgets('copies the detail when the copy button is tapped',
        (WidgetTester t) async {
      String? copied;
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() => t.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await t.pumpApp(
        const ApiErrorDisplay(message: 'Failed', detail: 'GET /x -> 500'),
        wrapInScaffold: true,
      );

      expect(find.byIcon(Icons.copy), findsOneWidget);
      await t.tap(find.byIcon(Icons.copy));
      await t.pump();

      expect(copied, 'GET /x -> 500');
    });
  });
}
