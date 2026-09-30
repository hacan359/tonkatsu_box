import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/custom_item/cover_image_picker.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('pickCustomCoverImage', () {
    late CoverPickResult? result;
    late bool returned;

    Future<void> openPicker(
      WidgetTester tester, {
      String currentUrl = '',
      List<CoverPickSource> extraSources = const <CoverPickSource>[],
    }) async {
      returned = false;
      result = null;
      await tester.pumpApp(
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async {
              result = await pickCustomCoverImage(
                context,
                currentUrl: currentUrl,
                extraSources: extraSources,
              );
              returned = true;
            },
            child: const Text('open'),
          ),
        ),
        wrapInScaffold: true,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    Finder option(int index) => find.byType(SimpleDialogOption).at(index);

    testWidgets('should return a trimmed link from the URL dialog',
        (WidgetTester tester) async {
      await openPicker(tester);
      await tester.tap(option(1));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '  https://x/a.png  ');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(returned, isTrue);
      expect(result?.url, 'https://x/a.png');
      expect(result?.bytes, isNull);
    });

    testWidgets('should close cleanly and return null on an empty link',
        (WidgetTester tester) async {
      await openPicker(tester);
      await tester.tap(option(1));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(returned, isTrue);
      expect(result, isNull);
    });

    testWidgets('should prefill the URL dialog with the current link',
        (WidgetTester tester) async {
      await openPicker(tester, currentUrl: 'https://x/old.png');
      await tester.tap(option(1));
      await tester.pumpAndSettle();

      final TextField field = tester.widget(find.byType(TextField));
      expect(field.controller?.text, 'https://x/old.png');
    });

    testWidgets('should hand back what an extra source picked',
        (WidgetTester tester) async {
      int calls = 0;
      await openPicker(
        tester,
        extraSources: <CoverPickSource>[
          CoverPickSource(
            icon: Icons.grid_view,
            label: 'Extra',
            pick: (BuildContext _) async {
              calls++;
              return const CoverPickResult.url('https://x/extra.png');
            },
          ),
        ],
      );

      await tester.tap(option(2));
      await tester.pumpAndSettle();

      expect(calls, 1);
      expect(result?.url, 'https://x/extra.png');
    });

    testWidgets('should return null when the source dialog is dismissed',
        (WidgetTester tester) async {
      await openPicker(tester);

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();

      expect(returned, isTrue);
      expect(result, isNull);
    });
  });
}
