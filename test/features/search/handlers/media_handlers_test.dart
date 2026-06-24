import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/search/handlers/game_handler.dart';
import 'package:tonkatsu_box/features/search/handlers/media_action_handler.dart';
import 'package:tonkatsu_box/features/search/handlers/media_handlers.dart';
import 'package:tonkatsu_box/features/search/handlers/movie_handler.dart';
import 'package:tonkatsu_box/features/search/handlers/simple_media_handler.dart';
import 'package:tonkatsu_box/features/search/handlers/tv_show_handler.dart';
import 'package:tonkatsu_box/shared/models/anime.dart';
import 'package:tonkatsu_box/shared/models/game.dart';
import 'package:tonkatsu_box/shared/models/manga.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/movie.dart';
import 'package:tonkatsu_box/shared/models/platform.dart';
import 'package:tonkatsu_box/shared/models/tv_show.dart';
import 'package:tonkatsu_box/shared/models/visual_novel.dart';

import '../../../helpers/test_helpers.dart';

class _RecordingHandler implements MediaActionHandler {
  final List<String> calls = <String>[];

  @override
  Future<void> onTap(
    BuildContext context,
    Object item,
    MediaType mediaType,
  ) async {
    calls.add('onTap');
  }

  @override
  Future<void> addToAnyCollection(
    BuildContext context,
    Object item,
    MediaType mediaType,
  ) async {
    calls.add('addToAnyCollection');
  }

  @override
  void showDetails(BuildContext context, Object item, MediaType mediaType) {
    calls.add('showDetails');
  }
}

void main() {
  setUpAll(registerAllFallbacks);

  group('MediaHandlers', () {
    late MockWidgetRef ref;
    late MediaHandlers handlers;

    setUp(() {
      ref = MockWidgetRef();
      handlers = MediaHandlers(
        ref: ref,
        platformMap: () => const <int, Platform>{},
        targetCollections: () => <int>{},
      );
    });

    group('forItem (type-based dispatch)', () {
      test('returns GameHandler for Game', () {
        const Game game = Game(id: 1, name: 'g');
        expect(handlers.forItem(game), isA<GameHandler>());
      });

      test('returns MovieHandler for Movie', () {
        const Movie movie = Movie(tmdbId: 1, title: 'm');
        expect(handlers.forItem(movie), isA<MovieHandler>());
      });

      test('returns TvShowHandler for TvShow', () {
        const TvShow tv = TvShow(tmdbId: 1, title: 't');
        expect(handlers.forItem(tv), isA<TvShowHandler>());
      });

      test('returns SimpleMediaHandler<VisualNovel> for VisualNovel', () {
        const VisualNovel vn = VisualNovel(id: 'v1', title: 'v');
        expect(handlers.forItem(vn), isA<SimpleMediaHandler<VisualNovel>>());
      });

      test('returns SimpleMediaHandler<Manga> for Manga', () {
        const Manga manga = Manga(id: 1, title: 'm');
        expect(handlers.forItem(manga), isA<SimpleMediaHandler<Manga>>());
      });

      test('returns SimpleMediaHandler<Anime> for Anime', () {
        const Anime anime = Anime(id: 1, title: 'a');
        expect(handlers.forItem(anime), isA<SimpleMediaHandler<Anime>>());
      });

      test('returns null for unknown type', () {
        expect(handlers.forItem('a string'), isNull);
      });
    });

    group('registerForSource override', () {
      test('source handler takes precedence over type handler', () {
        final _RecordingHandler override = _RecordingHandler();
        handlers.registerForSource('rawg', override);

        const Game game = Game(id: 1, name: 'g');
        expect(handlers.forItem(game, sourceId: 'rawg'), same(override));
      });

      test('falls back to type handler when sourceId not registered', () {
        final _RecordingHandler override = _RecordingHandler();
        handlers.registerForSource('rawg', override);

        const Game game = Game(id: 1, name: 'g');
        expect(handlers.forItem(game, sourceId: 'igdb'), isA<GameHandler>());
      });

      test('falls back to type handler when sourceId not provided', () {
        final _RecordingHandler override = _RecordingHandler();
        handlers.registerForSource('rawg', override);

        const Game game = Game(id: 1, name: 'g');
        expect(handlers.forItem(game), isA<GameHandler>());
      });
    });

    group('dispatch helpers', () {
      testWidgets('onTap routes to handler for item type',
          (WidgetTester tester) async {
        final _RecordingHandler rec = _RecordingHandler();
        handlers.registerForSource('s', rec);

        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
        await handlers.onTap(
          tester.element(find.byType(SizedBox)),
          const Game(id: 1, name: 'g'),
          MediaType.game,
          sourceId: 's',
        );

        expect(rec.calls, <String>['onTap']);
      });

      testWidgets('addToAnyCollection routes to handler',
          (WidgetTester tester) async {
        final _RecordingHandler rec = _RecordingHandler();
        handlers.registerForSource('s', rec);

        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
        await handlers.addToAnyCollection(
          tester.element(find.byType(SizedBox)),
          const Game(id: 1, name: 'g'),
          MediaType.game,
          sourceId: 's',
        );

        expect(rec.calls, <String>['addToAnyCollection']);
      });

      testWidgets('onTap no-ops when no handler registered',
          (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
        await expectLater(
          handlers.onTap(
            tester.element(find.byType(SizedBox)),
            'unknown',
            MediaType.custom,
          ),
          completes,
        );
      });
    });
  });
}
