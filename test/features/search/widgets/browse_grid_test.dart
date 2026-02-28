import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/shared/models/collected_item_info.dart';
import 'package:xerabora/features/search/providers/browse_provider.dart';
import 'package:xerabora/features/search/widgets/browse_grid.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/tv_show.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  /// Создаёт пустые override для провайдеров collected IDs.
  List<Override> emptyCollectedOverrides() {
    return <Override>[
      collectedMovieIdsProvider.overrideWith(
        (Ref ref) async => const <int, List<CollectedItemInfo>>{},
      ),
      collectedTvShowIdsProvider.overrideWith(
        (Ref ref) async => const <int, List<CollectedItemInfo>>{},
      ),
      collectedAnimationIdsProvider.overrideWith(
        (Ref ref) async => const <int, List<CollectedItemInfo>>{},
      ),
      collectedGameIdsProvider.overrideWith(
        (Ref ref) async => const <int, List<CollectedItemInfo>>{},
      ),
      collectedVisualNovelIdsProvider.overrideWith(
        (Ref ref) async => const <int, List<CollectedItemInfo>>{},
      ),
    ];
  }

  /// Создаёт override с конкретными ID в коллекции.
  List<Override> collectedOverrides({
    Map<int, List<CollectedItemInfo>> movies =
        const <int, List<CollectedItemInfo>>{},
    Map<int, List<CollectedItemInfo>> tvShows =
        const <int, List<CollectedItemInfo>>{},
    Map<int, List<CollectedItemInfo>> animations =
        const <int, List<CollectedItemInfo>>{},
    Map<int, List<CollectedItemInfo>> games =
        const <int, List<CollectedItemInfo>>{},
    Map<int, List<CollectedItemInfo>> visualNovels =
        const <int, List<CollectedItemInfo>>{},
  }) {
    return <Override>[
      collectedMovieIdsProvider.overrideWith((Ref ref) async => movies),
      collectedTvShowIdsProvider.overrideWith((Ref ref) async => tvShows),
      collectedAnimationIdsProvider.overrideWith(
        (Ref ref) async => animations,
      ),
      collectedGameIdsProvider.overrideWith((Ref ref) async => games),
      collectedVisualNovelIdsProvider.overrideWith(
        (Ref ref) async => visualNovels,
      ),
    ];
  }

  Widget buildWidget({
    BrowseState? initialState,
    void Function(Object item, MediaType mediaType)? onItemTap,
    List<Override>? extraOverrides,
  }) {
    return ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...emptyCollectedOverrides(),
        if (initialState != null)
          browseProvider.overrideWith(() {
            return _TestBrowseNotifier(initialState);
          }),
        ...?extraOverrides,
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: BrowseGrid(
            onItemTap: onItemTap ?? (_, _) {},
          ),
        ),
      ),
    );
  }

  group('BrowseGrid', () {
    testWidgets('shows shimmer grid when loading with no items',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            sourceId: 'movies',
            isLoading: true,
          ),
        ),
      );
      await tester.pump();

      // Should show shimmer grid (GridView exists)
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('shows error state when error and no items',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            sourceId: 'movies',
            error: 'Network error',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
    });

    testWidgets('shows empty results state when empty with filters',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            sourceId: 'movies',
            filterValues: <String, Object?>{'genre': 28},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('shows empty filter state when empty without filters',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            sourceId: 'movies',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.filter_alt_outlined), findsOneWidget);
    });

    testWidgets('renders movie items in grid', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            sourceId: 'movies',
            filterValues: <String, Object?>{'genre': 28},
            items: <Object>[
              Movie(
                tmdbId: 1,
                title: 'Test Movie 1',
                releaseYear: 2024,
                posterUrl: 'https://example.com/1.jpg',
              ),
              Movie(
                tmdbId: 2,
                title: 'Test Movie 2',
                releaseYear: 2023,
                posterUrl: 'https://example.com/2.jpg',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Test Movie 1'), findsOneWidget);
      expect(find.text('Test Movie 2'), findsOneWidget);
    });

    testWidgets('calls onItemTap when movie tapped',
        (WidgetTester tester) async {
      Object? tappedItem;
      MediaType? tappedType;

      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            sourceId: 'movies',
            filterValues: <String, Object?>{'genre': 28},
            items: <Object>[
              Movie(
                tmdbId: 1,
                title: 'Tap Me',
                releaseYear: 2024,
                posterUrl: 'https://example.com/1.jpg',
              ),
            ],
          ),
          onItemTap: (Object item, MediaType type) {
            tappedItem = item;
            tappedType = type;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(tappedItem, isA<Movie>());
      expect(tappedType, MediaType.movie);
    });

    testWidgets('marks movie as in collection when tmdbId matches',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            sourceId: 'movies',
            filterValues: <String, Object?>{'genre': 28},
            items: <Object>[
              Movie(
                tmdbId: 42,
                title: 'Collected Movie',
                releaseYear: 2024,
                posterUrl: 'https://example.com/c.jpg',
              ),
              Movie(
                tmdbId: 99,
                title: 'Not Collected',
                releaseYear: 2024,
                posterUrl: 'https://example.com/nc.jpg',
              ),
            ],
          ),
          extraOverrides: collectedOverrides(
            movies: <int, List<CollectedItemInfo>>{
              42: const <CollectedItemInfo>[
                CollectedItemInfo(recordId: 1, collectionId: 1, collectionName: 'Coll'),
              ],
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Зелёная галочка check_circle для tmdbId=42
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('marks game as in collection when id matches',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            sourceId: 'games',
            filterValues: <String, Object?>{'genre': 5},
            items: <Object>[
              Game(
                id: 100,
                name: 'Collected Game',
                coverUrl: 'https://example.com/g.jpg',
              ),
            ],
          ),
          extraOverrides: collectedOverrides(
            games: <int, List<CollectedItemInfo>>{
              100: const <CollectedItemInfo>[
                CollectedItemInfo(recordId: 1, collectionId: 1, collectionName: 'Coll'),
              ],
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('marks tv show as in collection when tmdbId matches',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            sourceId: 'tv',
            filterValues: <String, Object?>{'genre': 18},
            items: <Object>[
              TvShow(
                tmdbId: 55,
                title: 'Collected Show',
                posterUrl: 'https://example.com/tv.jpg',
              ),
            ],
          ),
          extraOverrides: collectedOverrides(
            tvShows: <int, List<CollectedItemInfo>>{
              55: const <CollectedItemInfo>[
                CollectedItemInfo(recordId: 1, collectionId: 1, collectionName: 'Coll'),
              ],
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('no collection mark when item not collected',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            sourceId: 'movies',
            filterValues: <String, Object?>{'genre': 28},
            items: <Object>[
              Movie(
                tmdbId: 999,
                title: 'Not In Collection',
                releaseYear: 2024,
                posterUrl: 'https://example.com/nc.jpg',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('uses MaxCrossAxisExtent delegate on desktop width',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            sourceId: 'movies',
            isLoading: true,
          ),
        ),
      );
      await tester.pump();

      final GridView grid =
          tester.widget<GridView>(find.byType(GridView));
      expect(
        grid.gridDelegate,
        isA<SliverGridDelegateWithMaxCrossAxisExtent>(),
      );
    });

    testWidgets('uses FixedCrossAxisCount delegate on mobile width',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            sourceId: 'movies',
            isLoading: true,
          ),
        ),
      );
      await tester.pump();

      final GridView grid =
          tester.widget<GridView>(find.byType(GridView));
      expect(
        grid.gridDelegate,
        isA<SliverGridDelegateWithFixedCrossAxisCount>(),
      );
    });
  });
}

/// Тестовый нотифайер с начальным состоянием.
class _TestBrowseNotifier extends BrowseNotifier {
  _TestBrowseNotifier(this._initialState);

  final BrowseState _initialState;

  @override
  BrowseState build() => _initialState;
}
