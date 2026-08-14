import 'package:core/models/collection.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/providers/rich_collections_provider.dart';
import 'package:tonkatsu_box/features/collections/widgets/rich/rich_hero_styles.dart';
import 'package:tonkatsu_box/shared/constants/rich_hero_style.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  final Collection collection = createTestCollection(name: 'Sci-Fi Shelf');
  final List<CollectionItem> items = <CollectionItem>[
    createTestCollectionItem(id: 1, status: ItemStatus.inProgress),
    createTestCollectionItem(
      id: 2,
      externalId: 101,
      status: ItemStatus.completed,
      mediaType: MediaType.movie,
    ),
    createTestCollectionItem(
      id: 3,
      externalId: 102,
      status: ItemStatus.planned,
      isFavorite: true,
    ),
  ];

  Widget hero() => SingleChildScrollView(
        child: RichCollectionHero(collection: collection, items: items),
      );

  group('RichCollectionHero', () {
    for (final RichHeroStyle style in RichHeroStyle.values) {
      testWidgets('should render the ${style.id} style without exceptions',
          (WidgetTester tester) async {
        await tester.pumpApp(
          hero(),
          overrides: <Override>[
            richHeroStyleProvider.overrideWithValue(style),
          ],
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('should render the ${style.id} style on a phone screen',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpApp(
          hero(),
          overrides: <Override>[
            richHeroStyleProvider.overrideWithValue(style),
          ],
        );

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('should show the collection name in the strips style',
        (WidgetTester tester) async {
      await tester.pumpApp(
        hero(),
        overrides: <Override>[
          richHeroStyleProvider.overrideWithValue(RichHeroStyle.slats),
        ],
      );

      expect(find.text(collection.name), findsOneWidget);
    });

    testWidgets('should render an empty collection without exceptions',
        (WidgetTester tester) async {
      await tester.pumpApp(
        SingleChildScrollView(
          child: RichCollectionHero(
            collection: collection,
            items: const <CollectionItem>[],
          ),
        ),
        overrides: <Override>[
          richHeroStyleProvider.overrideWithValue(RichHeroStyle.comic),
        ],
      );

      expect(tester.takeException(), isNull);
    });
  });
}
