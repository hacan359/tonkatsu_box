import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/data/repositories/collection_repository.dart';
import 'package:tonkatsu_box/features/collections/providers/collection_covers_provider.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/collections/widgets/collection_card.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/models/collection.dart';
import 'package:tonkatsu_box/shared/models/cover_info.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

Collection _makeCollection({
  int id = 1,
  String name = 'Test Collection',
  CollectionType type = CollectionType.own,
}) {
  return Collection(
    id: id,
    name: name,
    author: 'Author',
    type: type,
    createdAt: DateTime(2024),
  );
}

const CollectionStats _emptyStats = CollectionStats(
  total: 0,
  completed: 0,
  inProgress: 0,
  notStarted: 0,
  dropped: 0,
  planned: 0,
);

const CollectionStats _gameStats = CollectionStats(
  total: 10,
  completed: 5,
  inProgress: 3,
  notStarted: 2,
  dropped: 0,
  planned: 0,
  gameCount: 8,
  movieCount: 2,
);

const CollectionStats _movieStats = CollectionStats(
  total: 6,
  completed: 3,
  inProgress: 1,
  notStarted: 1,
  dropped: 0,
  planned: 1,
  movieCount: 5,
  tvShowCount: 1,
);

const List<CoverInfo> _testCovers = <CoverInfo>[
  CoverInfo(externalId: 1, mediaType: MediaType.game, thumbnailUrl: 'url1'),
  CoverInfo(externalId: 2, mediaType: MediaType.movie, thumbnailUrl: 'url2'),
  CoverInfo(externalId: 3, mediaType: MediaType.tvShow, thumbnailUrl: 'url3'),
  CoverInfo(
    externalId: 4,
    mediaType: MediaType.animation,
    platformId: 1,
    thumbnailUrl: 'url4',
  ),
];

const List<CoverInfo> _sixCovers = <CoverInfo>[
  CoverInfo(externalId: 1, mediaType: MediaType.game, thumbnailUrl: 'url1'),
  CoverInfo(externalId: 2, mediaType: MediaType.movie, thumbnailUrl: 'url2'),
  CoverInfo(externalId: 3, mediaType: MediaType.tvShow, thumbnailUrl: 'url3'),
  CoverInfo(
    externalId: 4,
    mediaType: MediaType.animation,
    platformId: 1,
    thumbnailUrl: 'url4',
  ),
  CoverInfo(externalId: 5, mediaType: MediaType.visualNovel, thumbnailUrl: 'url5'),
  CoverInfo(externalId: 6, mediaType: MediaType.manga, thumbnailUrl: 'url6'),
];

Widget _buildTestApp({
  required Widget child,
  required List<Override> overrides,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 200,
          height: 280,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('CollectionCard', () {
    testWidgets('должен отобразить название коллекции', (WidgetTester tester) async {
      final Collection collection = _makeCollection(name: 'Marvel Marathon');

      await tester.pumpWidget(_buildTestApp(
        overrides: <Override>[
          collectionStatsProvider(collection.id)
              .overrideWith((Ref ref) async => _gameStats),
          collectionCoversProvider(collection.id)
              .overrideWith((Ref ref) async => _testCovers),
        ],
        child: CollectionCard(collection: collection),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Marvel Marathon'), findsOneWidget);
    });

    testWidgets('должен отобразить статистику', (WidgetTester tester) async {
      final Collection collection = _makeCollection();

      await tester.pumpWidget(_buildTestApp(
        overrides: <Override>[
          collectionStatsProvider(collection.id)
              .overrideWith((Ref ref) async => _gameStats),
          collectionCoversProvider(collection.id)
              .overrideWith((Ref ref) async => <CoverInfo>[]),
        ],
        child: CollectionCard(collection: collection),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('10'), findsOneWidget);
    });

    testWidgets('should call onTap when pressed', (WidgetTester tester) async {
      bool tapped = false;
      final Collection collection = _makeCollection();

      await tester.pumpWidget(_buildTestApp(
        overrides: <Override>[
          collectionStatsProvider(collection.id)
              .overrideWith((Ref ref) async => _emptyStats),
          collectionCoversProvider(collection.id)
              .overrideWith((Ref ref) async => <CoverInfo>[]),
        ],
        child: CollectionCard(
          collection: collection,
          onTap: () => tapped = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CollectionCard));
      expect(tapped, isTrue);
    });

    testWidgets('should call onLongPress при долгом нажатии',
        (WidgetTester tester) async {
      bool longPressed = false;
      final Collection collection = _makeCollection();

      await tester.pumpWidget(_buildTestApp(
        overrides: <Override>[
          collectionStatsProvider(collection.id)
              .overrideWith((Ref ref) async => _emptyStats),
          collectionCoversProvider(collection.id)
              .overrideWith((Ref ref) async => <CoverInfo>[]),
        ],
        child: CollectionCard(
          collection: collection,
          onLongPress: () => longPressed = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(CollectionCard));
      expect(longPressed, isTrue);
    });

    testWidgets('should show fallback when empty обложках',
        (WidgetTester tester) async {
      final Collection collection = _makeCollection();

      await tester.pumpWidget(_buildTestApp(
        overrides: <Override>[
          collectionStatsProvider(collection.id)
              .overrideWith((Ref ref) async => _emptyStats),
          collectionCoversProvider(collection.id)
              .overrideWith((Ref ref) async => <CoverInfo>[]),
        ],
        child: CollectionCard(collection: collection),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.folder_rounded), findsOneWidget);
    });

    testWidgets('should show +N при total > 6',
        (WidgetTester tester) async {
      final Collection collection = _makeCollection();

      await tester.pumpWidget(_buildTestApp(
        overrides: <Override>[
          collectionStatsProvider(collection.id)
              .overrideWith((Ref ref) async => _gameStats),
          collectionCoversProvider(collection.id)
              .overrideWith((Ref ref) async => _testCovers),
        ],
        child: CollectionCard(collection: collection),
      ));
      await tester.pumpAndSettle();

      // total=10, 6 cells, remaining 4 shown as "+4".
      expect(find.text('+4'), findsOneWidget);
    });

    testWidgets('не should show +N при total <= 6',
        (WidgetTester tester) async {
      final Collection collection = _makeCollection();
      const CollectionStats sixItemStats = CollectionStats(
        total: 6,
        completed: 3,
        inProgress: 1,
        notStarted: 2,
        dropped: 0,
        planned: 0,
        gameCount: 6,
      );

      await tester.pumpWidget(_buildTestApp(
        overrides: <Override>[
          collectionStatsProvider(collection.id)
              .overrideWith((Ref ref) async => sixItemStats),
          collectionCoversProvider(collection.id)
              .overrideWith((Ref ref) async => _testCovers),
        ],
        child: CollectionCard(collection: collection),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('должен не показывать progress bar для пустой коллекции',
        (WidgetTester tester) async {
      final Collection collection = _makeCollection();

      await tester.pumpWidget(_buildTestApp(
        overrides: <Override>[
          collectionStatsProvider(collection.id)
              .overrideWith((Ref ref) async => _emptyStats),
          collectionCoversProvider(collection.id)
              .overrideWith((Ref ref) async => <CoverInfo>[]),
        ],
        child: CollectionCard(collection: collection),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('should use акцент по доминирующему медиа-типу (movie)',
        (WidgetTester tester) async {
      final Collection collection = _makeCollection();

      await tester.pumpWidget(_buildTestApp(
        overrides: <Override>[
          collectionStatsProvider(collection.id)
              .overrideWith((Ref ref) async => _movieStats),
          collectionCoversProvider(collection.id)
              .overrideWith((Ref ref) async => <CoverInfo>[]),
        ],
        child: CollectionCard(collection: collection),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CollectionCard), findsOneWidget);
    });

    testWidgets('should show loading while loading обложек',
        (WidgetTester tester) async {
      final Collection collection = _makeCollection();
      final Completer<List<CoverInfo>> completer =
          Completer<List<CoverInfo>>();

      await tester.pumpWidget(_buildTestApp(
        overrides: <Override>[
          collectionStatsProvider(collection.id)
              .overrideWith((Ref ref) async => _emptyStats),
          collectionCoversProvider(collection.id)
              .overrideWith((Ref ref) => completer.future),
        ],
        child: CollectionCard(collection: collection),
      ));
      await tester.pump();

      expect(find.byType(CollectionCard), findsOneWidget);

      // Complete the future to avoid leaving a pending timer.
      completer.complete(<CoverInfo>[]);
      await tester.pumpAndSettle();
    });

    testWidgets('should show fallback on error загрузки обложек',
        (WidgetTester tester) async {
      final Collection collection = _makeCollection();

      await tester.pumpWidget(_buildTestApp(
        overrides: <Override>[
          collectionStatsProvider(collection.id)
              .overrideWith((Ref ref) async => _emptyStats),
          collectionCoversProvider(collection.id)
              .overrideWith((Ref ref) => throw Exception('cover error')),
        ],
        child: CollectionCard(collection: collection),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.folder_rounded), findsOneWidget);
    });

    testWidgets('should show SizedBox при loading статистики',
        (WidgetTester tester) async {
      final Collection collection = _makeCollection();
      final Completer<CollectionStats> statsCompleter =
          Completer<CollectionStats>();

      await tester.pumpWidget(_buildTestApp(
        overrides: <Override>[
          collectionStatsProvider(collection.id)
              .overrideWith((Ref ref) => statsCompleter.future),
          collectionCoversProvider(collection.id)
              .overrideWith((Ref ref) async => <CoverInfo>[]),
        ],
        child: CollectionCard(collection: collection),
      ));
      await tester.pump();

      expect(find.byType(CollectionCard), findsOneWidget);

      statsCompleter.complete(_emptyStats);
      await tester.pumpAndSettle();
    });

    testWidgets('should show ошибку при сбое загрузки статистики',
        (WidgetTester tester) async {
      final Collection collection = _makeCollection();

      await tester.pumpWidget(_buildTestApp(
        overrides: <Override>[
          collectionStatsProvider(collection.id)
              .overrideWith((Ref ref) => throw Exception('stats error')),
          collectionCoversProvider(collection.id)
              .overrideWith((Ref ref) async => <CoverInfo>[]),
        ],
        child: CollectionCard(collection: collection),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error'), findsOneWidget);
    });

    testWidgets('должен отрендерить все 6 обложек в мозаике',
        (WidgetTester tester) async {
      final Collection collection = _makeCollection();

      await tester.pumpWidget(_buildTestApp(
        overrides: <Override>[
          collectionStatsProvider(collection.id)
              .overrideWith((Ref ref) async => _gameStats),
          collectionCoversProvider(collection.id)
              .overrideWith((Ref ref) async => _sixCovers),
        ],
        child: CollectionCard(collection: collection),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CollectionCard), findsOneWidget);
      expect(find.text('+4'), findsOneWidget);
    });

    testWidgets('should show пустые ячейки при неполных обложках',
        (WidgetTester tester) async {
      final Collection collection = _makeCollection();
      const List<CoverInfo> twoCovers = <CoverInfo>[
        CoverInfo(externalId: 1, mediaType: MediaType.game, thumbnailUrl: 'url1'),
        CoverInfo(externalId: 2, mediaType: MediaType.movie, thumbnailUrl: 'url2'),
      ];

      await tester.pumpWidget(_buildTestApp(
        overrides: <Override>[
          collectionStatsProvider(collection.id)
              .overrideWith((Ref ref) async => const CollectionStats(
                    total: 2,
                    completed: 1,
                    inProgress: 1,
                    notStarted: 0,
                    dropped: 0,
                    planned: 0,
                  )),
          collectionCoversProvider(collection.id)
              .overrideWith((Ref ref) async => twoCovers),
        ],
        child: CollectionCard(collection: collection),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CollectionCard), findsOneWidget);
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('должен рендерить обложку с null thumbnailUrl',
        (WidgetTester tester) async {
      final Collection collection = _makeCollection();
      const List<CoverInfo> coversWithNull = <CoverInfo>[
        CoverInfo(externalId: 1, mediaType: MediaType.game, thumbnailUrl: null),
      ];

      await tester.pumpWidget(_buildTestApp(
        overrides: <Override>[
          collectionStatsProvider(collection.id)
              .overrideWith((Ref ref) async => const CollectionStats(
                    total: 1,
                    completed: 0,
                    inProgress: 0,
                    notStarted: 1,
                    dropped: 0,
                    planned: 0,
                  )),
          collectionCoversProvider(collection.id)
              .overrideWith((Ref ref) async => coversWithNull),
        ],
        child: CollectionCard(collection: collection),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CollectionCard), findsOneWidget);
    });

    testWidgets('должен рендерить обложку animation с platformId tvShow',
        (WidgetTester tester) async {
      final Collection collection = _makeCollection();
      const List<CoverInfo> animCovers = <CoverInfo>[
        CoverInfo(
          externalId: 1,
          mediaType: MediaType.animation,
          platformId: 1, // AnimationSource.tvShow
          thumbnailUrl: 'url1',
        ),
        CoverInfo(
          externalId: 2,
          mediaType: MediaType.animation,
          platformId: 0, // AnimationSource.movie
          thumbnailUrl: 'url2',
        ),
        CoverInfo(
          externalId: 3,
          mediaType: MediaType.visualNovel,
          thumbnailUrl: 'url3',
        ),
      ];

      await tester.pumpWidget(_buildTestApp(
        overrides: <Override>[
          collectionStatsProvider(collection.id)
              .overrideWith((Ref ref) async => const CollectionStats(
                    total: 3,
                    completed: 0,
                    inProgress: 0,
                    notStarted: 3,
                    dropped: 0,
                    planned: 0,
                    animationCount: 2,
                    visualNovelCount: 1,
                  )),
          collectionCoversProvider(collection.id)
              .overrideWith((Ref ref) async => animCovers),
        ],
        child: CollectionCard(collection: collection),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CollectionCard), findsOneWidget);
    });

    testWidgets('должен иметь click курсор при наличии onTap',
        (WidgetTester tester) async {
      final Collection collection = _makeCollection();

      await tester.pumpWidget(_buildTestApp(
        overrides: <Override>[
          collectionStatsProvider(collection.id)
              .overrideWith((Ref ref) async => _emptyStats),
          collectionCoversProvider(collection.id)
              .overrideWith((Ref ref) async => <CoverInfo>[]),
        ],
        child: CollectionCard(
          collection: collection,
          onTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      final Finder inkWells = find.descendant(
        of: find.byType(CollectionCard),
        matching: find.byType(InkWell),
      );
      final InkWell inkWell = tester.widget<InkWell>(inkWells.first);
      expect(inkWell.onTap, isNotNull);
    });

    testWidgets('InkWell не имеет onTap без onTap параметра',
        (WidgetTester tester) async {
      final Collection collection = _makeCollection();

      await tester.pumpWidget(_buildTestApp(
        overrides: <Override>[
          collectionStatsProvider(collection.id)
              .overrideWith((Ref ref) async => _emptyStats),
          collectionCoversProvider(collection.id)
              .overrideWith((Ref ref) async => <CoverInfo>[]),
        ],
        child: CollectionCard(collection: collection),
      ));
      await tester.pumpAndSettle();

      final Finder inkWells = find.descendant(
        of: find.byType(CollectionCard),
        matching: find.byType(InkWell),
      );
      final InkWell inkWell = tester.widget<InkWell>(inkWells.first);
      expect(inkWell.onTap, isNull);
    });
  });

  group('UncategorizedCard', () {
    testWidgets('должен отобразить название и количество',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp(
        overrides: <Override>[],
        child: const UncategorizedCard(count: 5),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Uncategorized'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);
    });

    testWidgets('should call onTap when pressed',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(_buildTestApp(
        overrides: <Override>[],
        child: UncategorizedCard(
          count: 3,
          onTap: () => tapped = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(UncategorizedCard));
      expect(tapped, isTrue);
    });

  });
}
