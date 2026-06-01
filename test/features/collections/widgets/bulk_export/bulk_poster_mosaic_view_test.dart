import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/bulk_export/bulk_poster_mosaic_view.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/game.dart';
import 'package:tonkatsu_box/shared/models/item_status.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/widgets/cached_image.dart';

CollectionItem _item(int id, {bool withCover = false}) {
  return CollectionItem(
    id: id,
    collectionId: 1,
    mediaType: MediaType.game,
    externalId: 1000 + id,
    status: ItemStatus.notStarted,
    addedAt: DateTime(2024),
    game: Game(
      id: 1000 + id,
      name: 'Game $id',
      coverUrl: withCover ? 'https://example.test/cover_$id.jpg' : null,
    ),
  );
}

void main() {
  group('BulkPosterMosaicView', () {
    group('autoColumns', () {
      test('floors to 4 for empty / tiny sets', () {
        expect(BulkPosterMosaicView.autoColumns(0), 4);
        expect(BulkPosterMosaicView.autoColumns(1), 4);
        expect(BulkPosterMosaicView.autoColumns(5), 4);
      });

      test('picks ~sqrt(n * 1.5) within bounds', () {
        expect(BulkPosterMosaicView.autoColumns(20), 5);
        expect(BulkPosterMosaicView.autoColumns(50), 9);
        expect(BulkPosterMosaicView.autoColumns(100), 12);
      });

      test('clamps to 20 for huge sets', () {
        expect(BulkPosterMosaicView.autoColumns(1000), 20);
        expect(BulkPosterMosaicView.autoColumns(10000), 20);
      });
    });

    testWidgets('renders without exceptions for a small set',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(4000, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final GlobalKey repaintKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: SingleChildScrollView(
            child: BulkPosterMosaicView(
              repaintKey: repaintKey,
              items: <CollectionItem>[for (int i = 0; i < 8; i++) _item(i)],
              columns: 4,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(repaintKey), findsOneWidget);
    });

    testWidgets('renders without exceptions for a medium set',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(6000, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final GlobalKey repaintKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: SingleChildScrollView(
            child: BulkPosterMosaicView(
              repaintKey: repaintKey,
              items: <CollectionItem>[for (int i = 0; i < 50; i++) _item(i)],
              columns: BulkPosterMosaicView.autoColumns(50),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('falls back to CachedImage when precachedFiles is null',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SingleChildScrollView(
              child: BulkPosterMosaicView(
                items: <CollectionItem>[
                  for (int i = 0; i < 4; i++) _item(i, withCover: true),
                ],
                columns: 4,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(CachedImage), findsNWidgets(4));
    });

    testWidgets('renders Image directly when precachedFile is provided',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final Directory tempDir = Directory.systemTemp.createTempSync(
        'bulk_export_test_',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final File tempCover = File('${tempDir.path}/cover.png')
        ..writeAsBytesSync(<int>[
          // 1×1 transparent PNG.
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
          0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
          0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
          0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
          0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
          0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
          0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
          0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
          0x42, 0x60, 0x82,
        ]);

      final CollectionItem item = _item(1);
      await tester.pumpWidget(
        MaterialApp(
          home: SingleChildScrollView(
            child: BulkPosterMosaicView(
              items: <CollectionItem>[item],
              columns: 4,
              precachedFiles: <int, File>{item.id: tempCover},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      // Direct ResizeImage(FileImage) path bypasses CachedImage entirely.
      expect(find.byType(CachedImage), findsNothing);
    });
  });
}
