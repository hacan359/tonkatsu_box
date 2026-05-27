import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/widgets/copyable_text.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('CopyableText', () {
    testWidgets('copies its text to the clipboard on tap', (WidgetTester t) async {
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
        const CopyableText(text: 'copy-me', child: Text('shown')),
        wrapInScaffold: true,
      );
      expect(find.text('shown'), findsOneWidget);

      await t.tap(find.byType(CopyableText));
      await t.pump();
      expect(copied, 'copy-me');

      // _copy schedules a 1s timer to reset the "copied" state; flush it so
      // the test doesn't end with a pending timer.
      await t.pump(const Duration(seconds: 1));
    });
  });
}
