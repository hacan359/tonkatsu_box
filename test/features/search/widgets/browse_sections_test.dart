import 'package:core/models/data_source.dart';
import 'package:core/models/manga.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/api/api_error_extract.dart';
import 'package:tonkatsu_box/features/collections/providers/collections_provider.dart';
import 'package:tonkatsu_box/features/search/providers/browse_provider.dart';
import 'package:tonkatsu_box/features/search/widgets/browse_sections.dart';
import 'package:tonkatsu_box/features/search/widgets/browse_sections_compact.dart';
import 'package:tonkatsu_box/features/search/widgets/source_error_strip.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/theme/app_theme.dart';
import 'package:tonkatsu_box/shared/widgets/shimmer_loading.dart';


class _TestBrowseNotifier extends BrowseNotifier {
  _TestBrowseNotifier(this._initial);

  final BrowseState _initial;

  String? narrowedTo;

  @override
  BrowseState build() => _initial;

  @override
  Future<void> narrowTo(String sourceId) async {
    narrowedTo = sourceId;
  }
}

Manga _manga(int id, String title, DataSource source) => Manga(
      id: id,
      source: source,
      title: title,
    );

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  List<Override> emptyCollected() => <Override>[
        collectedMovieIdsProvider.overrideWith((_) async => <int, List<Never>>{}),
        collectedTvShowIdsProvider.overrideWith((_) async => <int, List<Never>>{}),
        collectedAnimationIdsProvider
            .overrideWith((_) async => <int, List<Never>>{}),
        collectedGameIdsProvider.overrideWith((_) async => <int, List<Never>>{}),
        collectedVisualNovelIdsProvider
            .overrideWith((_) async => <int, List<Never>>{}),
        collectedMangaIdsProvider.overrideWith((_) async => <int, List<Never>>{}),
        collectedAnimeIdsProvider.overrideWith((_) async => <int, List<Never>>{}),
        collectedBookIdsProvider.overrideWith((_) async => <int, List<Never>>{}),
        collectedAudioIdsProvider.overrideWith((_) async => <int, List<Never>>{}),
      ];

  Widget build(
    BrowseState state, {
    required bool compact,
    _TestBrowseNotifier? notifier,
  }) {
    return ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...emptyCollected(),
        browseProvider.overrideWith(
          () => notifier ?? _TestBrowseNotifier(state),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: const Locale('en'),
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: compact
              ? BrowseSectionsCompact(onItemTap: (_, _) {})
              : BrowseSections(onItemTap: (_, _) {}),
        ),
      ),
    );
  }

  BrowseState mangaState({int perSource = 3}) => BrowseState(
        mediaType: MediaType.manga,
        searchQuery: 'berserk',
        itemsBySource: <String, List<Object>>{
          'manga': <Object>[
            for (int i = 0; i < perSource; i++)
              _manga(100 + i, 'AniList $i', DataSource.anilist),
          ],
          'mangadex': <Object>[
            for (int i = 0; i < perSource; i++)
              _manga(200 + i, 'MangaDex $i', DataSource.mangadex),
          ],
        },
        disabledSourceIds: const <String>{'mangabaka', 'kitsu_manga'},
      );

  /// AniList already answered, Kitsu is still thinking — the case the
  /// per-source shimmer exists for.
  BrowseState oneStillLoading({List<Object>? anilistItems}) => BrowseState(
        mediaType: MediaType.manga,
        searchQuery: 'berserk',
        itemsBySource: <String, List<Object>>{
          'manga': anilistItems ??
              <Object>[_manga(100, 'AniList 0', DataSource.anilist)],
        },
        loadingSourceIds: const <String>{'kitsu_manga'},
        disabledSourceIds: const <String>{'mangabaka', 'mangadex'},
      );

  group('BrowseSections', () {
    testWidgets('renders a block per source without layout errors',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(build(mangaState(), compact: false));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('AniList 0'), findsOneWidget);
      expect(find.text('MangaDex 0'), findsOneWidget);
    });

    testWidgets('caps a block to two rows and offers the rest',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      // Far more than two rows fit at this width, so the cap must hide some.
      await tester.pumpWidget(build(mangaState(perSource: 40), compact: false));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('+'), findsWidgets);
      expect(find.text('AniList 39'), findsNothing);
    });

    testWidgets('show all narrows to that source', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final _TestBrowseNotifier notifier = _TestBrowseNotifier(mangaState());
      await tester.pumpWidget(
        build(mangaState(), compact: false, notifier: notifier),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextButton).first);
      await tester.pumpAndSettle();

      expect(notifier.narrowedTo, 'manga');
    });

    testWidgets('a failed source is reported inline, others keep rendering',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final BrowseState state = mangaState().copyWith(
        errors: const <String, ApiError>{
          'mangadex': (message: 'boom', detail: null),
        },
      );

      await tester.pumpWidget(build(state, compact: false));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SourceErrorStrip), findsOneWidget);
      expect(find.text('AniList 0'), findsOneWidget);
    });

    testWidgets('a load-more failure keeps the loaded results under the strip',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final BrowseState state = mangaState().copyWith(
        errors: const <String, ApiError>{
          'mangadex': (message: 'boom', detail: null),
        },
      );

      await tester.pumpWidget(build(state, compact: false));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SourceErrorStrip), findsOneWidget);
      expect(find.text('MangaDex 0'), findsOneWidget);
    });

    testWidgets('a source still answering shimmers next to one that has',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(build(oneStillLoading(), compact: false));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('AniList 0'), findsOneWidget);
      expect(find.byType(ShimmerPosterCard), findsWidgets);
    });

    testWidgets('a source that answered with nothing collapses',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      // AniList answered — with nothing — while Kitsu is still loading, so only
      // Kitsu may shimmer.
      await tester.pumpWidget(
        build(oneStillLoading(anilistItems: <Object>[]), compact: false),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text(DataSource.anilist.label), findsNothing);
      expect(find.text(DataSource.kitsu.label), findsOneWidget);
    });
  });

  group('BrowseSectionsCompact', () {
    testWidgets('renders on a phone without overflowing',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(build(mangaState(), compact: true));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('AniList 0'), findsOneWidget);
    });

    testWidgets('gives a still-answering source a rail of its own',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(build(oneStillLoading(), compact: true));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('AniList 0'), findsOneWidget);
      expect(find.byType(ShimmerPosterCard), findsWidgets);
      expect(find.text(DataSource.kitsu.label), findsOneWidget);
    });

    testWidgets('a load-more failure keeps the rail under the strip',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final BrowseState state = mangaState().copyWith(
        errors: const <String, ApiError>{
          'mangadex': (message: 'boom', detail: null),
        },
      );

      await tester.pumpWidget(build(state, compact: true));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SourceErrorStrip), findsOneWidget);
      expect(find.text('MangaDex 0'), findsOneWidget);
    });
  });
}
