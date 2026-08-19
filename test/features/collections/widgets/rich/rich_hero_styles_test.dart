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

    for (final RichHeroStyle style in RichHeroStyle.values) {
      testWidgets('should fire onBack from the ${style.id} style banner',
          (WidgetTester tester) async {
        bool popped = false;
        await tester.pumpApp(
          SingleChildScrollView(
            child: RichCollectionHero(
              collection: collection,
              items: items,
              onBack: () => popped = true,
            ),
          ),
          overrides: <Override>[
            richHeroStyleProvider.overrideWithValue(style),
          ],
        );

        await tester.tap(find.byIcon(Icons.arrow_back));
        expect(popped, isTrue);
      });
    }

    testWidgets('should not render a back control when onBack is absent',
        (WidgetTester tester) async {
      await tester.pumpApp(
        hero(),
        overrides: <Override>[
          richHeroStyleProvider.overrideWithValue(RichHeroStyle.slats),
        ],
      );

      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets(
        'should render the stickers style in a very narrow hero '
        'without overflowing', (WidgetTester tester) async {
      // Regression: on a narrow window the right column of the stickers hero
      // used to overflow the fixed banner height once the badges wrapped.
      tester.view.physicalSize = const Size(328, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final List<CollectionItem> manyStatuses = <CollectionItem>[
        for (final (int, ItemStatus) e in <(int, ItemStatus)>[
          (1, ItemStatus.notStarted),
          (2, ItemStatus.inProgress),
          (3, ItemStatus.completed),
          (4, ItemStatus.dropped),
          (5, ItemStatus.planned),
        ])
          createTestCollectionItem(id: e.$1, externalId: 100 + e.$1, status: e.$2),
      ];

      await tester.pumpApp(
        SingleChildScrollView(
          child: RichCollectionHero(collection: collection, items: manyStatuses),
        ),
        overrides: <Override>[
          richHeroStyleProvider.overrideWithValue(RichHeroStyle.stickers),
        ],
      );

      expect(tester.takeException(), isNull);
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
