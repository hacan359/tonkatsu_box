// Widget tests for RecommendationsSection — owned badge (check_circle).

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/core/api/tmdb_api.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/features/collections/widgets/recommendations_section.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/models/collected_item_info.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/tv_show.dart';

class MockTmdbApi extends Mock implements TmdbApi {}

class MockDatabaseService extends Mock implements DatabaseService {}

/// Pumps enough frames for async providers to resolve without waiting for
/// CachedNetworkImage animations to settle (which never finish in tests).
Future<void> pumpUntilResolved(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  late MockTmdbApi mockTmdbApi;
  late MockDatabaseService mockDb;
  late SharedPreferences prefs;

  const Movie movieOwned = Movie(
    tmdbId: 100,
    title: 'Owned Movie',
    overview: 'An owned movie',
    posterUrl: 'https://example.com/owned.jpg',
    releaseYear: 2024,
    rating: 8.0,
    genres: <String>['Action'],
  );

  const Movie movieNotOwned = Movie(
    tmdbId: 200,
    title: 'Not Owned Movie',
    overview: 'A free movie',
    posterUrl: 'https://example.com/free.jpg',
    releaseYear: 2024,
    rating: 7.0,
    genres: <String>['Drama'],
  );

  const TvShow tvOwned = TvShow(
    tmdbId: 300,
    title: 'Owned Show',
    overview: 'An owned show',
    posterUrl: 'https://example.com/owned_tv.jpg',
    firstAirYear: 2023,
    rating: 9.0,
    genres: <String>['Sci-Fi'],
  );

  const TvShow tvNotOwned = TvShow(
    tmdbId: 400,
    title: 'Not Owned Show',
    overview: 'A free show',
    posterUrl: 'https://example.com/free_tv.jpg',
    firstAirYear: 2023,
    rating: 6.5,
    genres: <String>['Comedy'],
  );

  setUp(() async {
    mockTmdbApi = MockTmdbApi();
    mockDb = MockDatabaseService();

    // SettingsNotifier calls getPlatformCount on init.
    when(() => mockDb.getPlatformCount()).thenAnswer((_) async => 0);

    SharedPreferences.setMockInitialValues(<String, Object>{
      'tmdb_api_key': 'test_key',
    });
    prefs = await SharedPreferences.getInstance();
  });

  /// Builds a widget with all required provider overrides.
  Widget buildWidget({
    required MediaType mediaType,
    int tmdbId = 1,
    Map<int, List<CollectedItemInfo>> movieIds =
        const <int, List<CollectedItemInfo>>{},
    Map<int, List<CollectedItemInfo>> tvIds =
        const <int, List<CollectedItemInfo>>{},
    Map<int, List<CollectedItemInfo>> animationIds =
        const <int, List<CollectedItemInfo>>{},
  }) {
    return ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        tmdbApiProvider.overrideWithValue(mockTmdbApi),
        databaseServiceProvider.overrideWithValue(mockDb),
        collectedMovieIdsProvider.overrideWith(
          (Ref ref) async => movieIds,
        ),
        collectedTvShowIdsProvider.overrideWith(
          (Ref ref) async => tvIds,
        ),
        collectedAnimationIdsProvider.overrideWith(
          (Ref ref) async => animationIds,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecommendationsSection(
              tmdbId: tmdbId,
              mediaType: mediaType,
            ),
          ),
        ),
      ),
    );
  }

  group('RecommendationsSection', () {
    group('movie recommendations', () {
      testWidgets('shows check_circle for owned movie',
          (WidgetTester tester) async {
        when(() => mockTmdbApi.getMovieRecommendations(any(),
                page: any(named: 'page')))
            .thenAnswer((_) async => <Movie>[movieOwned, movieNotOwned]);

        await tester.pumpWidget(
          buildWidget(
            mediaType: MediaType.movie,
            movieIds: <int, List<CollectedItemInfo>>{
              100: <CollectedItemInfo>[
                const CollectedItemInfo(
                  recordId: 1,
                  collectionId: 1,
                  collectionName: 'Favorites',
                ),
              ],
            },
          ),
        );

        await pumpUntilResolved(tester);

        // Should show exactly one check_circle (for owned movie).
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        // Both movie titles should be visible.
        expect(find.text('Owned Movie'), findsOneWidget);
        expect(find.text('Not Owned Movie'), findsOneWidget);
      });

      testWidgets('no check_circle when no movies are owned',
          (WidgetTester tester) async {
        when(() => mockTmdbApi.getMovieRecommendations(any(),
                page: any(named: 'page')))
            .thenAnswer((_) async => <Movie>[movieOwned, movieNotOwned]);

        await tester.pumpWidget(
          buildWidget(mediaType: MediaType.movie),
        );

        await pumpUntilResolved(tester);

        expect(find.byIcon(Icons.check_circle), findsNothing);
      });

      testWidgets('animation owned IDs also count for movies',
          (WidgetTester tester) async {
        when(() => mockTmdbApi.getMovieRecommendations(any(),
                page: any(named: 'page')))
            .thenAnswer((_) async => <Movie>[movieOwned]);

        await tester.pumpWidget(
          buildWidget(
            mediaType: MediaType.movie,
            animationIds: <int, List<CollectedItemInfo>>{
              100: <CollectedItemInfo>[
                const CollectedItemInfo(
                  recordId: 2,
                  collectionId: 3,
                  collectionName: 'Anime',
                ),
              ],
            },
          ),
        );

        await pumpUntilResolved(tester);

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });
    });

    group('tv recommendations', () {
      testWidgets('shows check_circle for owned tv show',
          (WidgetTester tester) async {
        when(() => mockTmdbApi.getTvRecommendations(any(),
                page: any(named: 'page')))
            .thenAnswer((_) async => <TvShow>[tvOwned, tvNotOwned]);

        await tester.pumpWidget(
          buildWidget(
            mediaType: MediaType.tvShow,
            tvIds: <int, List<CollectedItemInfo>>{
              300: <CollectedItemInfo>[
                const CollectedItemInfo(
                  recordId: 10,
                  collectionId: 5,
                  collectionName: 'Watchlist',
                ),
              ],
            },
          ),
        );

        await pumpUntilResolved(tester);

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.text('Owned Show'), findsOneWidget);
        expect(find.text('Not Owned Show'), findsOneWidget);
      });

      testWidgets('no check_circle when no tv shows are owned',
          (WidgetTester tester) async {
        when(() => mockTmdbApi.getTvRecommendations(any(),
                page: any(named: 'page')))
            .thenAnswer((_) async => <TvShow>[tvOwned, tvNotOwned]);

        await tester.pumpWidget(
          buildWidget(mediaType: MediaType.tvShow),
        );

        await pumpUntilResolved(tester);

        expect(find.byIcon(Icons.check_circle), findsNothing);
      });

      testWidgets('animation owned IDs also count for tv shows',
          (WidgetTester tester) async {
        when(() => mockTmdbApi.getTvRecommendations(any(),
                page: any(named: 'page')))
            .thenAnswer((_) async => <TvShow>[tvOwned]);

        await tester.pumpWidget(
          buildWidget(
            mediaType: MediaType.animation,
            animationIds: <int, List<CollectedItemInfo>>{
              300: <CollectedItemInfo>[
                const CollectedItemInfo(
                  recordId: 11,
                  collectionId: 6,
                  collectionName: 'Animation',
                ),
              ],
            },
          ),
        );

        await pumpUntilResolved(tester);

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });
    });

    group('empty state', () {
      testWidgets('returns SizedBox.shrink when no TMDB API key',
          (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final SharedPreferences emptyPrefs =
            await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              sharedPreferencesProvider.overrideWithValue(emptyPrefs),
              tmdbApiProvider.overrideWithValue(mockTmdbApi),
              databaseServiceProvider.overrideWithValue(mockDb),
              collectedMovieIdsProvider.overrideWith(
                (Ref ref) async => <int, List<CollectedItemInfo>>{},
              ),
              collectedTvShowIdsProvider.overrideWith(
                (Ref ref) async => <int, List<CollectedItemInfo>>{},
              ),
              collectedAnimationIdsProvider.overrideWith(
                (Ref ref) async => <int, List<CollectedItemInfo>>{},
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: S.localizationsDelegates,
              supportedLocales: S.supportedLocales,
              home: Scaffold(
                body: RecommendationsSection(
                  tmdbId: 1,
                  mediaType: MediaType.movie,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should not show any recommendation content.
        expect(find.byType(ListView), findsNothing);
      });

      testWidgets('returns SizedBox.shrink for empty recommendations',
          (WidgetTester tester) async {
        when(() => mockTmdbApi.getMovieRecommendations(any(),
                page: any(named: 'page')))
            .thenAnswer((_) async => <Movie>[]);

        await tester.pumpWidget(
          buildWidget(mediaType: MediaType.movie),
        );

        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsNothing);
      });
    });

    group('poster card', () {
      testWidgets('shows CachedNetworkImage when posterUrl exists',
          (WidgetTester tester) async {
        when(() => mockTmdbApi.getMovieRecommendations(any(),
                page: any(named: 'page')))
            .thenAnswer((_) async => <Movie>[movieOwned]);

        await tester.pumpWidget(
          buildWidget(mediaType: MediaType.movie),
        );

        await pumpUntilResolved(tester);

        expect(find.byType(CachedNetworkImage), findsOneWidget);
      });

      testWidgets('shows placeholder icon when no posterUrl',
          (WidgetTester tester) async {
        const Movie movieNoPoster = Movie(
          tmdbId: 500,
          title: 'No Poster Movie',
          overview: 'No poster',
          rating: 5.0,
          genres: <String>[],
        );

        when(() => mockTmdbApi.getMovieRecommendations(any(),
                page: any(named: 'page')))
            .thenAnswer((_) async => <Movie>[movieNoPoster]);

        await tester.pumpWidget(
          buildWidget(mediaType: MediaType.movie),
        );

        await pumpUntilResolved(tester);

        expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
        expect(find.byType(CachedNetworkImage), findsNothing);
      });

      testWidgets('shows year when provided', (WidgetTester tester) async {
        when(() => mockTmdbApi.getMovieRecommendations(any(),
                page: any(named: 'page')))
            .thenAnswer((_) async => <Movie>[movieOwned]);

        await tester.pumpWidget(
          buildWidget(mediaType: MediaType.movie),
        );

        await pumpUntilResolved(tester);

        expect(find.text('2024'), findsOneWidget);
      });
    });
  });
}
