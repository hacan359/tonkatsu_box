import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/services/whats_new_service.dart';
import 'package:tonkatsu_box/shared/widgets/mini_markdown_text.dart';
import 'package:tonkatsu_box/shared/widgets/whats_new_dialog.dart';

import '../../helpers/test_helpers.dart';

const WhatsNewContent _content = WhatsNewContent(
  version: '0.40.0',
  body: '**Added**\n\n• **New banner cards**\n\nPoster cards got a banner.',
);

void main() {
  group('WhatsNewDialog', () {
    testWidgets('should render the version and markdown body',
        (WidgetTester tester) async {
      await tester.pumpApp(const WhatsNewDialog(content: _content));

      expect(find.textContaining('0.40.0'), findsOneWidget);
      expect(find.byType(MiniMarkdownText), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should close via the action button',
        (WidgetTester tester) async {
      await tester.pumpApp(
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => showWhatsNewDialog(context, _content),
            child: const Text('open'),
          ),
        ),
      );

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      expect(find.byType(WhatsNewDialog), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(WhatsNewDialog),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WhatsNewDialog), findsNothing);
    });

    testWidgets('should not overflow on a phone-sized screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpApp(
        WhatsNewDialog(
          content: WhatsNewContent(
            version: '0.40.0',
            body: List<String>.generate(
              40,
              (int i) => '• **Topic $i**\n\nBody line for topic $i.',
            ).join('\n\n'),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
