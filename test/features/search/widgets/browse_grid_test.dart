import 'package:core/models/anime.dart';
import 'package:core/models/collected_item_info.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/game.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/platform.dart';
import 'package:core/models/tv_show.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/api/api_error_extract.dart';
import 'package:tonkatsu_box/features/search/widgets/source_error_strip.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/search/providers/browse_provider.dart';
import 'package:tonkatsu_box/features/search/widgets/browse_grid.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/widgets/media_poster_card.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

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
      collectedMangaIdsProvider.overrideWith(
        (Ref ref) async => const <int, List<CollectedItemInfo>>{},
      ),
      collectedAnimeIdsProvider.overrideWith(
        (Ref ref) async => const <int, List<CollectedItemInfo>>{},
      ),
      collectedBookIdsProvider.overrideWith(
        (Ref ref) async => const <int, List<CollectedItemInfo>>{},
      ),
      collectedAudioIdsProvider.overrideWith(
        (Ref ref) async => const <int, List<CollectedItemInfo>>{},
      ),
    ];
  }

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
    Map<int, List<CollectedItemInfo>> mangas =
        const <int, List<CollectedItemInfo>>{},
    Map<int, List<CollectedItemInfo>> animes =
        const <int, List<CollectedItemInfo>>{},
    Map<int, List<CollectedItemInfo>> books =
        const <int, List<CollectedItemInfo>>{},
    Map<int, List<CollectedItemInfo>> albums =
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
      collectedMangaIdsProvider.overrideWith((Ref ref) async => mangas),
      collectedAnimeIdsProvider.overrideWith((Ref ref) async => animes),
      collectedBookIdsProvider.overrideWith((Ref ref) async => books),
      collectedAudioIdsProvider.overrideWith((Ref ref) async => albums),
    ];
  }

  Widget buildWidget({
    BrowseState? initialState,
    void Function(Object item, MediaType mediaType)? onItemTap,
    void Function(int externalId, MediaType mediaType, DataSource? source)?
        onOpenInCollection,
    List<Override>? extraOverrides,
    Map<int, Platform> platformMap = const <int, Platform>{},
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
            onOpenInCollection: onOpenInCollection,
            platformMap: platformMap,
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
            mediaType: MediaType.movie,
            loadingSourceIds: <String>{'movies'},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('shows error state when error and no items',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            mediaType: MediaType.movie,
            errors: <String, ApiError>{
              'movies': (message: 'Network error', detail: null),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SourceErrorStrip), findsOneWidget);
    });

    testWidgets('reports the API message, not a generic failure',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            mediaType: MediaType.movie,
            errors: <String, ApiError>{
              'movies': (message: 'Invalid API key', detail: null),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Invalid API key'), findsOneWidget);
    });

    testWidgets('hides the error of a source the user switched off',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            mediaType: MediaType.manga,
            searchQuery: 'berserk',
            disabledSourceIds: <String>{
              'mangadex',
              'kitsu_manga',
              'mangabaka',
            },
            errors: <String, ApiError>{
              'mangadex': (message: 'Network error', detail: null),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SourceErrorStrip), findsNothing);
    });

    testWidgets('shows empty results state when empty with filters',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            mediaType: MediaType.movie,
            ownFilterValues: <String, Map<String, Object?>>{'movies': <String, Object?>{'genre': 28}},
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
            mediaType: MediaType.movie,
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
            mediaType: MediaType.movie,
            ownFilterValues: <String, Map<String, Object?>>{'movies': <String, Object?>{'genre': 28}},
            itemsBySource: <String, List<Object>>{'movies': <Object>[
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
            ]},
          ),
        ),
      );
      await tester.pumpAndSettle();

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
            mediaType: MediaType.movie,
            ownFilterValues: <String, Map<String, Object?>>{'movies': <String, Object?>{'genre': 28}},
            itemsBySource: <String, List<Object>>{'movies': <Object>[
              Movie(
                tmdbId: 1,
                title: 'Tap Me',
                releaseYear: 2024,
                posterUrl: 'https://example.com/1.jpg',
              ),
            ]},
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
            mediaType: MediaType.movie,
            ownFilterValues: <String, Map<String, Object?>>{'movies': <String, Object?>{'genre': 28}},
            itemsBySource: <String, List<Object>>{'movies': <Object>[
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
            ]},
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

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('marks game as in collection when id matches',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            mediaType: MediaType.game,
            ownFilterValues: <String, Map<String, Object?>>{'games': <String, Object?>{'genre': 5}},
            itemsBySource: <String, List<Object>>{'games': <Object>[
              Game(
                id: 100,
                name: 'Collected Game',
                coverUrl: 'https://example.com/g.jpg',
              ),
            ]},
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
            mediaType: MediaType.tvShow,
            ownFilterValues: <String, Map<String, Object?>>{'tv': <String, Object?>{'genre': 18}},
            itemsBySource: <String, List<Object>>{'tv': <Object>[
              TvShow(
                tmdbId: 55,
                title: 'Collected Show',
                posterUrl: 'https://example.com/tv.jpg',
              ),
            ]},
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

    testWidgets('passes the item source and its page link to the card',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            mediaType: MediaType.tvShow,
            ownFilterValues: <String, Map<String, Object?>>{'tv': <String, Object?>{'genre': 18}},
            itemsBySource: <String, List<Object>>{'tv': <Object>[
              TvShow(
                tmdbId: 55,
                title: 'Linked Show',
                source: DataSource.tvmaze,
                externalUrl: 'https://example.org/tv/55',
              ),
            ]},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final MediaPosterCard card =
          tester.widget<MediaPosterCard>(find.byType(MediaPosterCard));
      expect(card.source, DataSource.tvmaze);
      expect(card.onSourceTap, isNotNull);
    });

    testWidgets('leaves the source logo inert when the item has no link',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            mediaType: MediaType.tvShow,
            ownFilterValues: <String, Map<String, Object?>>{'tv': <String, Object?>{'genre': 18}},
            itemsBySource: <String, List<Object>>{'tv': <Object>[
              TvShow(tmdbId: 56, title: 'Unlinked Show'),
            ]},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final MediaPosterCard card =
          tester.widget<MediaPosterCard>(find.byType(MediaPosterCard));
      expect(card.onSourceTap, isNull);
    });

    testWidgets(
        'does not mark a TVmaze show when only a TMDB show shares the id',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            mediaType: MediaType.tvShow,
            searchQuery: 'dark',
            itemsBySource: <String, List<Object>>{'tvmaze_tv': <Object>[
              TvShow(
                tmdbId: 55,
                title: 'Dark',
                source: DataSource.tvmaze,
                posterUrl: 'https://example.com/tv.jpg',
              ),
            ]},
          ),
          extraOverrides: collectedOverrides(
            tvShows: <int, List<CollectedItemInfo>>{
              55: const <CollectedItemInfo>[
                // Defaults to DataSource.tmdb — a different provider.
                CollectedItemInfo(
                    recordId: 1, collectionId: 1, collectionName: 'Coll'),
              ],
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('marks a TVmaze show collected from the same source',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            mediaType: MediaType.tvShow,
            searchQuery: 'dark',
            itemsBySource: <String, List<Object>>{'tvmaze_tv': <Object>[
              TvShow(
                tmdbId: 55,
                title: 'Dark',
                source: DataSource.tvmaze,
                posterUrl: 'https://example.com/tv.jpg',
              ),
            ]},
          ),
          extraOverrides: collectedOverrides(
            tvShows: <int, List<CollectedItemInfo>>{
              55: const <CollectedItemInfo>[
                CollectedItemInfo(
                  recordId: 1,
                  collectionId: 1,
                  collectionName: 'Coll',
                  source: DataSource.tvmaze,
                ),
              ],
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('does not mark a Kitsu anime when an AniList one shares the id',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            mediaType: MediaType.anime,
            searchQuery: 'bebop',
            itemsBySource: <String, List<Object>>{'kitsu_anime': <Object>[
              Anime(
                id: 55,
                title: 'Cowboy Bebop',
                source: DataSource.kitsu,
                coverUrl: 'https://example.com/anime.jpg',
              ),
            ]},
          ),
          extraOverrides: collectedOverrides(
            animes: <int, List<CollectedItemInfo>>{
              55: const <CollectedItemInfo>[
                // Defaults to DataSource.tmdb; the DAO resolves a NULL source
                // for anime to anilist — either way, not Kitsu.
                CollectedItemInfo(
                  recordId: 1,
                  collectionId: 1,
                  collectionName: 'Coll',
                  source: DataSource.anilist,
                ),
              ],
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('marks a Kitsu anime collected from the same source',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            mediaType: MediaType.anime,
            searchQuery: 'bebop',
            itemsBySource: <String, List<Object>>{'kitsu_anime': <Object>[
              Anime(
                id: 55,
                title: 'Cowboy Bebop',
                source: DataSource.kitsu,
                coverUrl: 'https://example.com/anime.jpg',
              ),
            ]},
          ),
          extraOverrides: collectedOverrides(
            animes: <int, List<CollectedItemInfo>>{
              55: const <CollectedItemInfo>[
                CollectedItemInfo(
                  recordId: 1,
                  collectionId: 1,
                  collectionName: 'Coll',
                  source: DataSource.kitsu,
                ),
              ],
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('open-in-collection carries the item source for anime',
        (WidgetTester tester) async {
      int? gotId;
      MediaType? gotType;
      DataSource? gotSource;

      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            mediaType: MediaType.anime,
            searchQuery: 'bebop',
            itemsBySource: <String, List<Object>>{'kitsu_anime': <Object>[
              Anime(
                id: 55,
                title: 'Cowboy Bebop',
                source: DataSource.kitsu,
                coverUrl: 'https://example.com/anime.jpg',
              ),
            ]},
          ),
          onOpenInCollection: (int id, MediaType type, DataSource? source) {
            gotId = id;
            gotType = type;
            gotSource = source;
          },
          extraOverrides: collectedOverrides(
            animes: <int, List<CollectedItemInfo>>{
              55: const <CollectedItemInfo>[
                CollectedItemInfo(
                  recordId: 1,
                  collectionId: 1,
                  collectionName: 'Coll',
                  source: DataSource.kitsu,
                ),
              ],
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.open_in_new));
      await tester.pump();

      expect(gotId, 55);
      expect(gotType, MediaType.anime);
      expect(gotSource, DataSource.kitsu);
    });

    testWidgets('open-in-collection carries the source of a movie',
        (WidgetTester tester) async {
      DataSource? gotSource;
      bool called = false;

      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            mediaType: MediaType.movie,
            itemsBySource: <String, List<Object>>{'movies': <Object>[
              Movie(
                tmdbId: 77,
                title: 'Dune',
                releaseYear: 2021,
                posterUrl: 'https://example.com/dune.jpg',
              ),
            ]},
          ),
          onOpenInCollection: (int id, MediaType type, DataSource? source) {
            called = true;
            gotSource = source;
          },
          extraOverrides: collectedOverrides(
            movies: <int, List<CollectedItemInfo>>{
              77: const <CollectedItemInfo>[
                CollectedItemInfo(
                  recordId: 1,
                  collectionId: 1,
                  collectionName: 'Coll',
                ),
              ],
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.open_in_new));
      await tester.pump();

      expect(called, isTrue);
      // Movies come from several providers now, so the id alone would open the
      // wrong entry.
      expect(gotSource, DataSource.tmdb);
    });

    testWidgets('no collection mark when item not collected',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildWidget(
          initialState: const BrowseState(
            mediaType: MediaType.movie,
            ownFilterValues: <String, Map<String, Object?>>{'movies': <String, Object?>{'genre': 28}},
            itemsBySource: <String, List<Object>>{'movies': <Object>[
              Movie(
                tmdbId: 999,
                title: 'Not In Collection',
                releaseYear: 2024,
                posterUrl: 'https://example.com/nc.jpg',
              ),
            ]},
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
            mediaType: MediaType.movie,
            loadingSourceIds: <String>{'movies'},
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
            mediaType: MediaType.movie,
            loadingSourceIds: <String>{'movies'},
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

    group('viewport fill auto-load', () {
      testWidgets('auto-loads more when content does not fill viewport',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        int loadMoreCalls = 0;
        late _ViewportFillTestNotifier notifier;

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              sharedPreferencesProvider.overrideWithValue(prefs),
              ...emptyCollectedOverrides(),
              browseProvider.overrideWith(() {
                notifier = _ViewportFillTestNotifier(
                  onLoadMore: () => loadMoreCalls++,
                );
                return notifier;
              }),
            ],
            child: MaterialApp(
              localizationsDelegates: S.localizationsDelegates,
              supportedLocales: S.supportedLocales,
              locale: const Locale('en'),
              home: Scaffold(
                body: BrowseGrid(onItemTap: (_, _) {}),
              ),
            ),
          ),
        );
        await tester.pump();

        notifier.completeLoading(
          const <Object>[
            Movie(tmdbId: 1, title: 'M1', releaseYear: 2024),
            Movie(tmdbId: 2, title: 'M2', releaseYear: 2024),
          ],
          hasMore: true,
        );

        await tester.pump();
        await tester.pump();

        expect(loadMoreCalls, greaterThan(0));
      });

      testWidgets(
          'auto-loads when the grid appears with a short page already loaded',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        int loadMoreCalls = 0;

        // Narrowing to one provider swaps the sections view for this grid with
        // the page already in state — no state change follows, so the initial
        // build must run the fill check itself.
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              sharedPreferencesProvider.overrideWithValue(prefs),
              ...emptyCollectedOverrides(),
              browseProvider.overrideWith(
                () => _ViewportFillTestNotifier(
                  onLoadMore: () => loadMoreCalls++,
                  initial: const BrowseState(
                    mediaType: MediaType.movie,
                    searchQuery: 'bleach',
                    itemsBySource: <String, List<Object>>{
                      'movies': <Object>[
                        Movie(tmdbId: 1, title: 'M1', releaseYear: 2024),
                        Movie(tmdbId: 2, title: 'M2', releaseYear: 2024),
                      ],
                    },
                    moreBySource: <String, bool>{'movies': true},
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: S.localizationsDelegates,
              supportedLocales: S.supportedLocales,
              locale: const Locale('en'),
              home: Scaffold(
                body: BrowseGrid(onItemTap: (_, _) {}),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(loadMoreCalls, greaterThan(0));
      });

      testWidgets('does not auto-load when hasMore is false',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        int loadMoreCalls = 0;
        late _ViewportFillTestNotifier notifier;

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              sharedPreferencesProvider.overrideWithValue(prefs),
              ...emptyCollectedOverrides(),
              browseProvider.overrideWith(() {
                notifier = _ViewportFillTestNotifier(
                  onLoadMore: () => loadMoreCalls++,
                );
                return notifier;
              }),
            ],
            child: MaterialApp(
              localizationsDelegates: S.localizationsDelegates,
              supportedLocales: S.supportedLocales,
              locale: const Locale('en'),
              home: Scaffold(
                body: BrowseGrid(onItemTap: (_, _) {}),
              ),
            ),
          ),
        );
        await tester.pump();

        notifier.completeLoading(
          const <Object>[
            Movie(tmdbId: 1, title: 'M1', releaseYear: 2024),
          ],
          hasMore: false,
        );

        await tester.pump();
        await tester.pump();

        expect(loadMoreCalls, 0);
      });

      testWidgets('does not auto-load while still loading',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        int loadMoreCalls = 0;
        late _ViewportFillTestNotifier notifier;

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              sharedPreferencesProvider.overrideWithValue(prefs),
              ...emptyCollectedOverrides(),
              browseProvider.overrideWith(() {
                notifier = _ViewportFillTestNotifier(
                  onLoadMore: () => loadMoreCalls++,
                );
                return notifier;
              }),
            ],
            child: MaterialApp(
              localizationsDelegates: S.localizationsDelegates,
              supportedLocales: S.supportedLocales,
              locale: const Locale('en'),
              home: Scaffold(
                body: BrowseGrid(onItemTap: (_, _) {}),
              ),
            ),
          ),
        );
        await tester.pump();

        notifier.setLoadingMore(
          const <Object>[
            Movie(tmdbId: 1, title: 'M1', releaseYear: 2024),
          ],
        );

        await tester.pump();
        await tester.pump();

        expect(loadMoreCalls, 0);
      });

      testWidgets('does not auto-load when isLoading is true',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        int loadMoreCalls = 0;
        late _ViewportFillTestNotifier notifier;

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              sharedPreferencesProvider.overrideWithValue(prefs),
              ...emptyCollectedOverrides(),
              browseProvider.overrideWith(() {
                notifier = _ViewportFillTestNotifier(
                  onLoadMore: () => loadMoreCalls++,
                );
                return notifier;
              }),
            ],
            child: MaterialApp(
              localizationsDelegates: S.localizationsDelegates,
              supportedLocales: S.supportedLocales,
              locale: const Locale('en'),
              home: Scaffold(
                body: BrowseGrid(onItemTap: (_, _) {}),
              ),
            ),
          ),
        );
        await tester.pump();

        notifier.setStillLoading(
          const <Object>[
            Movie(tmdbId: 1, title: 'M1', releaseYear: 2024),
          ],
        );

        await tester.pump();
        await tester.pump();

        expect(loadMoreCalls, 0);
      });

      testWidgets('does not auto-load when items are empty',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        int loadMoreCalls = 0;
        late _ViewportFillTestNotifier notifier;

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              sharedPreferencesProvider.overrideWithValue(prefs),
              ...emptyCollectedOverrides(),
              browseProvider.overrideWith(() {
                notifier = _ViewportFillTestNotifier(
                  onLoadMore: () => loadMoreCalls++,
                );
                return notifier;
              }),
            ],
            child: MaterialApp(
              localizationsDelegates: S.localizationsDelegates,
              supportedLocales: S.supportedLocales,
              locale: const Locale('en'),
              home: Scaffold(
                body: BrowseGrid(onItemTap: (_, _) {}),
              ),
            ),
          ),
        );
        await tester.pump();

        notifier.completeLoading(
          const <Object>[],
          hasMore: true,
        );

        await tester.pump();
        await tester.pump();

        expect(loadMoreCalls, 0);
      });
    });

    group('platform label', () {
      testWidgets('shows platform abbreviation on game card',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildWidget(
            initialState: const BrowseState(
              mediaType: MediaType.game,
              ownFilterValues: <String, Map<String, Object?>>{'games': <String, Object?>{'genre': 5}},
              itemsBySource: <String, List<Object>>{'games': <Object>[
                Game(
                  id: 1,
                  name: 'Super Mario',
                  platformIds: <int>[19],
                  coverUrl: 'https://example.com/mario.jpg',
                ),
              ]},
            ),
            platformMap: const <int, Platform>{
              19: Platform(id: 19, name: 'Super Nintendo', abbreviation: 'SNES'),
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Super Mario'), findsOneWidget);
        expect(find.textContaining('SNES'), findsOneWidget);
      });

      testWidgets('shows multiple platforms separated by comma',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildWidget(
            initialState: const BrowseState(
              mediaType: MediaType.game,
              ownFilterValues: <String, Map<String, Object?>>{'games': <String, Object?>{'genre': 5}},
              itemsBySource: <String, List<Object>>{'games': <Object>[
                Game(
                  id: 2,
                  name: 'Multi Plat Game',
                  platformIds: <int>[6, 48],
                  coverUrl: 'https://example.com/mp.jpg',
                ),
              ]},
            ),
            platformMap: const <int, Platform>{
              6: Platform(id: 6, name: 'PC (Microsoft Windows)', abbreviation: 'PC'),
              48: Platform(id: 48, name: 'PlayStation 4', abbreviation: 'PS4'),
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('PC'), findsOneWidget);
        expect(find.textContaining('PS4'), findsOneWidget);
      });

      testWidgets('shows +N for more than 3 platforms',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildWidget(
            initialState: const BrowseState(
              mediaType: MediaType.game,
              ownFilterValues: <String, Map<String, Object?>>{'games': <String, Object?>{'genre': 5}},
              itemsBySource: <String, List<Object>>{'games': <Object>[
                Game(
                  id: 3,
                  name: 'Everywhere Game',
                  platformIds: <int>[6, 48, 49, 130],
                  coverUrl: 'https://example.com/eg.jpg',
                ),
              ]},
            ),
            platformMap: const <int, Platform>{
              6: Platform(id: 6, name: 'PC', abbreviation: 'PC'),
              48: Platform(id: 48, name: 'PlayStation 4', abbreviation: 'PS4'),
              49: Platform(id: 49, name: 'Xbox One', abbreviation: 'XONE'),
              130: Platform(id: 130, name: 'Nintendo Switch', abbreviation: 'Switch'),
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('+1'), findsOneWidget);
      });

      testWidgets('does not show platform when platformMap is empty',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildWidget(
            initialState: const BrowseState(
              mediaType: MediaType.game,
              ownFilterValues: <String, Map<String, Object?>>{'games': <String, Object?>{'genre': 5}},
              itemsBySource: <String, List<Object>>{'games': <Object>[
                Game(
                  id: 4,
                  name: 'No Platform Game',
                  platformIds: <int>[19],
                  coverUrl: 'https://example.com/np.jpg',
                ),
              ]},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('No Platform Game'), findsOneWidget);
        expect(find.textContaining('SNES'), findsNothing);
      });

      testWidgets('uses full name when abbreviation is null',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildWidget(
            initialState: const BrowseState(
              mediaType: MediaType.game,
              ownFilterValues: <String, Map<String, Object?>>{'games': <String, Object?>{'genre': 5}},
              itemsBySource: <String, List<Object>>{'games': <Object>[
                Game(
                  id: 5,
                  name: 'Full Name Game',
                  platformIds: <int>[999],
                  coverUrl: 'https://example.com/fn.jpg',
                ),
              ]},
            ),
            platformMap: const <int, Platform>{
              999: Platform(id: 999, name: 'My Custom Platform'),
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('My Custom Platform'), findsOneWidget);
      });
    });
  });
}

class _TestBrowseNotifier extends BrowseNotifier {
  _TestBrowseNotifier(this._initialState);

  final BrowseState _initialState;

  @override
  BrowseState build() => _initialState;
}

class _ViewportFillTestNotifier extends BrowseNotifier {
  _ViewportFillTestNotifier({required this.onLoadMore, BrowseState? initial})
      : _initial = initial;

  final void Function() onLoadMore;
  final BrowseState? _initial;

  @override
  BrowseState build() =>
      _initial ??
      const BrowseState(
        mediaType: MediaType.movie,
        loadingSourceIds: <String>{'movies'},
      );

  void completeLoading(List<Object> items, {required bool hasMore}) {
    state = _withItems(items, hasMore: hasMore, isLoading: false);
  }

  void setLoadingMore(List<Object> items) {
    state = _withItems(items, hasMore: true, isLoading: false)
        .copyWith(isLoadingMore: true);
  }

  void setStillLoading(List<Object> items) {
    state = _withItems(items, hasMore: true, isLoading: true);
  }

  BrowseState _withItems(
    List<Object> items, {
    required bool hasMore,
    required bool isLoading,
  }) {
    return state.copyWith(
      itemsBySource: <String, List<Object>>{'movies': items},
      moreBySource: <String, bool>{'movies': hasMore},
      loadingSourceIds:
          isLoading ? const <String>{'movies'} : const <String>{},
      ownFilterValues: const <String, Map<String, Object?>>{
        'movies': <String, Object?>{'genre': 28},
      },
    );
  }

  @override
  Future<void> loadMore() async {
    onLoadMore();
  }
}
