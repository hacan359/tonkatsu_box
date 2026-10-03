import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/models/universal_import_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/import/sources/custom_file/custom_card_entry.dart';
import 'package:tonkatsu_box/core/import/sources/custom_file/custom_cards_import_service.dart';
import 'package:tonkatsu_box/features/settings/screens/custom_cards_preview_screen.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    registerAllFallbacks();
    registerFallbackValue(<CustomCardEntry>[]);
  });

  CustomCardRow valid(int index, String title) => CustomCardRow(
        index: index,
        sourceTitle: title,
        entry: CustomCardEntry(title: title, type: MediaType.game),
      );

  CustomCardRow invalid(int index) => CustomCardRow(
        index: index,
        issues: const <CustomCardIssue>[
          CustomCardIssue(CustomCardIssueCode.missingTitle),
        ],
      );

  Widget screen({
    required List<CustomCardRow> rows,
    Set<int> duplicates = const <int>{},
    bool resolveFromSources = false,
  }) {
    return Scaffold(
      body: CustomCardsPreviewScreen(
        rows: rows,
        duplicateIndexes: duplicates,
        collectionId: 1,
        author: 'me',
        resolveFromSources: resolveFromSources,
      ),
    );
  }

  group('CustomCardsPreviewScreen', () {
    testWidgets('renders without exception on a phone-sized screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpApp(screen(
        rows: <CustomCardRow>[valid(1, 'Valid'), valid(2, 'Dup'), invalid(3)],
        duplicates: <int>{2},
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('checks valid rows by default and leaves duplicates unchecked',
        (WidgetTester tester) async {
      await tester.pumpApp(screen(
        rows: <CustomCardRow>[valid(1, 'Valid'), valid(2, 'Dup')],
        duplicates: <int>{2},
      ));

      final List<CheckboxListTile> tiles = tester
          .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
          .toList();
      expect(tiles, hasLength(2));
      final Map<bool?, int> byValue = <bool?, int>{};
      for (final CheckboxListTile tile in tiles) {
        byValue[tile.value] = (byValue[tile.value] ?? 0) + 1;
      }
      expect(byValue[true], 1);
      expect(byValue[false], 1);
    });

    testWidgets('invalid rows come first and get no checkbox',
        (WidgetTester tester) async {
      await tester.pumpApp(screen(
        rows: <CustomCardRow>[valid(1, 'Valid'), invalid(2)],
      ));

      expect(find.byType(CheckboxListTile), findsOneWidget);
      final Offset invalidRow =
          tester.getTopLeft(find.byIcon(Icons.error_outline));
      final Offset validRow =
          tester.getTopLeft(find.byType(CheckboxListTile));
      expect(invalidRow.dy, lessThan(validRow.dy));
    });

    testWidgets('select none disables import, select all re-enables it',
        (WidgetTester tester) async {
      await tester.pumpApp(screen(
        rows: <CustomCardRow>[valid(1, 'Valid'), valid(2, 'Other')],
      ));

      FilledButton importButton() => tester.widget<FilledButton>(
            find.ancestor(
              of: find.byIcon(Icons.download),
              matching: find.byType(FilledButton),
            ),
          );
      expect(importButton().onPressed, isNotNull);

      final S l = await S.delegate.load(const Locale('en'));
      await tester.tap(find.text(l.customImportSelectNone));
      await tester.pump();
      expect(importButton().onPressed, isNull);

      await tester.tap(find.text(l.selectAll));
      await tester.pump();
      expect(importButton().onPressed, isNotNull);
    });

    testWidgets('toggling a row checkbox updates the selection',
        (WidgetTester tester) async {
      await tester.pumpApp(screen(
        rows: <CustomCardRow>[valid(1, 'Only')],
      ));

      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile))
            .value,
        isTrue,
      );

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();

      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile))
            .value,
        isFalse,
      );
    });

    testWidgets('passes the source lookup flag to the import service',
        (WidgetTester tester) async {
      final MockCustomCardsImportService service =
          MockCustomCardsImportService();
      when(() => service.importSelected(
            collectionId: any(named: 'collectionId'),
            author: any(named: 'author'),
            entries: any(named: 'entries'),
            resolveFromSources: any(named: 'resolveFromSources'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer(
        (_) async => const UniversalImportResult.failure(
          sourceName: 'Custom cards',
          error: 'stub',
        ),
      );

      await tester.pumpApp(
        screen(rows: <CustomCardRow>[valid(1, 'Valid')], resolveFromSources: true),
        overrides: <Override>[
          customCardsImportServiceProvider.overrideWithValue(service),
        ],
      );
      await tester.tap(find.text(S.of(tester.element(find.byType(
        CustomCardsPreviewScreen,
      ))).customImportStart));
      // The progress dialog's loader animates forever: settle by time.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      verify(() => service.importSelected(
            collectionId: 1,
            author: 'me',
            entries: any(named: 'entries'),
            resolveFromSources: true,
            onProgress: any(named: 'onProgress'),
          )).called(1);
    });
  });
}
