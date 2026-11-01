import 'package:core/models/collection_import.dart';
import 'package:core/models/import_source_kind.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/dialogs/collection_import_source_dialog.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  CollectionImport saved(ImportSourceKind source) => CollectionImport(
    collectionId: 1,
    source: source,
    lastRunAt: DateTime(2026, 1, 2),
  );

  Future<void> open(
    WidgetTester tester,
    List<CollectionImport> records,
    void Function(CollectionImportChoice? choice) onResult,
  ) async {
    await tester.pumpApp(
      Builder(
        builder: (BuildContext context) => ElevatedButton(
          onPressed: () async => onResult(
            await CollectionImportSourceDialog.show(context, records),
          ),
          child: const Text('Open'),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('CollectionImportSourceDialog', () {
    testWidgets('should list the file option plus one row per saved run', (
      WidgetTester tester,
    ) async {
      await open(tester, <CollectionImport>[
        saved(ImportSourceKind.steam),
        saved(ImportSourceKind.customCards),
      ], (_) {});

      expect(tester.takeException(), isNull);
      expect(find.byType(SimpleDialogOption), findsNWidgets(3));
    });

    testWidgets('should return the file choice from the first option', (
      WidgetTester tester,
    ) async {
      CollectionImportChoice? result;
      await open(tester, <CollectionImport>[
        saved(ImportSourceKind.steam),
      ], (CollectionImportChoice? c) => result = c);

      await tester.tap(find.byType(SimpleDialogOption).first);
      await tester.pumpAndSettle();

      expect(result, isA<CollectionImportFromFile>());
    });

    testWidgets('should return the tapped saved run', (
      WidgetTester tester,
    ) async {
      CollectionImportChoice? result;
      await open(tester, <CollectionImport>[
        saved(ImportSourceKind.steam),
        saved(ImportSourceKind.trakt),
      ], (CollectionImportChoice? c) => result = c);

      await tester.tap(
        find.byKey(ValueKey<String>(ImportSourceKind.trakt.key)),
      );
      await tester.pumpAndSettle();

      expect(result, isA<CollectionImportRerun>());
      expect(
        (result! as CollectionImportRerun).record.source,
        ImportSourceKind.trakt,
      );
    });

    testWidgets('should return null when dismissed', (
      WidgetTester tester,
    ) async {
      CollectionImportChoice? result = const CollectionImportFromFile();
      await open(tester, <CollectionImport>[
        saved(ImportSourceKind.steam),
      ], (CollectionImportChoice? c) => result = c);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
