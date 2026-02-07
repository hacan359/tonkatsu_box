// Виджет-тесты для CanvasMediaCard.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/widgets/canvas_media_card.dart';
import 'package:xerabora/shared/models/canvas_item.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/tv_show.dart';

void main() {
  group('CanvasMediaCard', () {
    final DateTime testDate = DateTime(2024, 6, 15);

    CanvasItem createMovieItem({
      Movie? movie,
    }) {
      return CanvasItem(
        id: 1,
        collectionId: 10,
        itemType: CanvasItemType.movie,
        itemRefId: 200,
        x: 0,
        y: 0,
        width: 160,
        height: 220,
        zIndex: 0,
        createdAt: testDate,
        movie: movie,
      );
    }

    CanvasItem createTvShowItem({
      TvShow? tvShow,
    }) {
      return CanvasItem(
        id: 2,
        collectionId: 10,
        itemType: CanvasItemType.tvShow,
        itemRefId: 300,
        x: 0,
        y: 0,
        width: 160,
        height: 220,
        zIndex: 0,
        createdAt: testDate,
        tvShow: tvShow,
      );
    }

    Widget buildTestWidget(CanvasItem item) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 160,
            height: 220,
            child: CanvasMediaCard(item: item),
          ),
        ),
      );
    }

    group('Карточка фильма', () {
      testWidgets(
        'отображает название фильма когда movie задан',
        (WidgetTester tester) async {
          final CanvasItem item = createMovieItem(
            movie: const Movie(
              tmdbId: 200,
              title: 'Inception',
              posterUrl: 'https://image.tmdb.org/t/p/w500/poster.jpg',
            ),
          );

          await tester.pumpWidget(buildTestWidget(item));

          expect(find.text('Inception'), findsOneWidget);
        },
      );

      testWidgets(
        'использует CachedNetworkImage когда posterUrl задан',
        (WidgetTester tester) async {
          final CanvasItem item = createMovieItem(
            movie: const Movie(
              tmdbId: 200,
              title: 'Inception',
              posterUrl: 'https://image.tmdb.org/t/p/w500/poster.jpg',
            ),
          );

          await tester.pumpWidget(buildTestWidget(item));

          expect(find.byType(CachedNetworkImage), findsOneWidget);
        },
      );

      testWidgets(
        'отображает иконку-заглушку Icons.movie_outlined когда нет постера',
        (WidgetTester tester) async {
          final CanvasItem item = createMovieItem(
            movie: const Movie(
              tmdbId: 200,
              title: 'Inception',
            ),
          );

          await tester.pumpWidget(buildTestWidget(item));

          expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
          expect(find.byType(CachedNetworkImage), findsNothing);
        },
      );

      testWidgets(
        'отображает "Unknown Movie" когда movie равен null',
        (WidgetTester tester) async {
          final CanvasItem item = createMovieItem();

          await tester.pumpWidget(buildTestWidget(item));

          expect(find.text('Unknown Movie'), findsOneWidget);
        },
      );

      testWidgets(
        'отображает иконку-заглушку когда movie равен null',
        (WidgetTester tester) async {
          final CanvasItem item = createMovieItem();

          await tester.pumpWidget(buildTestWidget(item));

          expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
        },
      );
    });

    group('Карточка сериала', () {
      testWidgets(
        'отображает название сериала когда tvShow задан',
        (WidgetTester tester) async {
          final CanvasItem item = createTvShowItem(
            tvShow: const TvShow(
              tmdbId: 300,
              title: 'Breaking Bad',
              posterUrl: 'https://image.tmdb.org/t/p/w500/bb_poster.jpg',
            ),
          );

          await tester.pumpWidget(buildTestWidget(item));

          expect(find.text('Breaking Bad'), findsOneWidget);
        },
      );

      testWidgets(
        'использует CachedNetworkImage когда posterUrl задан',
        (WidgetTester tester) async {
          final CanvasItem item = createTvShowItem(
            tvShow: const TvShow(
              tmdbId: 300,
              title: 'Breaking Bad',
              posterUrl: 'https://image.tmdb.org/t/p/w500/bb_poster.jpg',
            ),
          );

          await tester.pumpWidget(buildTestWidget(item));

          expect(find.byType(CachedNetworkImage), findsOneWidget);
        },
      );

      testWidgets(
        'отображает иконку-заглушку Icons.tv_outlined когда нет постера',
        (WidgetTester tester) async {
          final CanvasItem item = createTvShowItem(
            tvShow: const TvShow(
              tmdbId: 300,
              title: 'Breaking Bad',
            ),
          );

          await tester.pumpWidget(buildTestWidget(item));

          expect(find.byIcon(Icons.tv_outlined), findsOneWidget);
          expect(find.byType(CachedNetworkImage), findsNothing);
        },
      );

      testWidgets(
        'отображает "Unknown TV Show" когда tvShow равен null',
        (WidgetTester tester) async {
          final CanvasItem item = createTvShowItem();

          await tester.pumpWidget(buildTestWidget(item));

          expect(find.text('Unknown TV Show'), findsOneWidget);
        },
      );

      testWidgets(
        'отображает иконку-заглушку когда tvShow равен null',
        (WidgetTester tester) async {
          final CanvasItem item = createTvShowItem();

          await tester.pumpWidget(buildTestWidget(item));

          expect(find.byIcon(Icons.tv_outlined), findsOneWidget);
        },
      );
    });

    group('Структура карточки', () {
      testWidgets(
        'содержит виджет Card',
        (WidgetTester tester) async {
          final CanvasItem item = createMovieItem();

          await tester.pumpWidget(buildTestWidget(item));

          expect(find.byType(Card), findsOneWidget);
        },
      );

      testWidgets(
        'Card имеет clipBehavior antiAlias',
        (WidgetTester tester) async {
          final CanvasItem item = createMovieItem();

          await tester.pumpWidget(buildTestWidget(item));

          final Card card = tester.widget<Card>(find.byType(Card));
          expect(card.clipBehavior, Clip.antiAlias);
        },
      );

      testWidgets(
        'содержит Column для вертикальной раскладки',
        (WidgetTester tester) async {
          final CanvasItem item = createMovieItem();

          await tester.pumpWidget(buildTestWidget(item));

          expect(find.byType(Column), findsOneWidget);
        },
      );

      testWidgets(
        'содержит Expanded для области постера',
        (WidgetTester tester) async {
          final CanvasItem item = createMovieItem();

          await tester.pumpWidget(buildTestWidget(item));

          expect(find.byType(Expanded), findsOneWidget);
        },
      );

      testWidgets(
        'название отображается с maxLines 2 и TextOverflow.ellipsis',
        (WidgetTester tester) async {
          final CanvasItem item = createMovieItem(
            movie: const Movie(
              tmdbId: 200,
              title: 'Very Long Movie Title That Should Be Truncated',
            ),
          );

          await tester.pumpWidget(buildTestWidget(item));

          final Text titleText = tester.widget<Text>(
            find.text('Very Long Movie Title That Should Be Truncated'),
          );
          expect(titleText.maxLines, 2);
          expect(titleText.overflow, TextOverflow.ellipsis);
        },
      );
    });

    group('Обработка граничных случаев', () {
      testWidgets(
        'movie-элемент без movie данных показывает заглушку и fallback текст',
        (WidgetTester tester) async {
          final CanvasItem item = createMovieItem();

          await tester.pumpWidget(buildTestWidget(item));

          expect(find.text('Unknown Movie'), findsOneWidget);
          expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
          expect(find.byType(CachedNetworkImage), findsNothing);
        },
      );

      testWidgets(
        'tvShow-элемент без tvShow данных показывает заглушку и fallback текст',
        (WidgetTester tester) async {
          final CanvasItem item = createTvShowItem();

          await tester.pumpWidget(buildTestWidget(item));

          expect(find.text('Unknown TV Show'), findsOneWidget);
          expect(find.byIcon(Icons.tv_outlined), findsOneWidget);
          expect(find.byType(CachedNetworkImage), findsNothing);
        },
      );

      testWidgets(
        'movie с posterUrl null показывает placeholder вместо CachedNetworkImage',
        (WidgetTester tester) async {
          final CanvasItem item = createMovieItem(
            movie: const Movie(
              tmdbId: 200,
              title: 'No Poster Movie',
              posterUrl: null,
            ),
          );

          await tester.pumpWidget(buildTestWidget(item));

          expect(find.text('No Poster Movie'), findsOneWidget);
          expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
          expect(find.byType(CachedNetworkImage), findsNothing);
        },
      );

      testWidgets(
        'tvShow с posterUrl null показывает placeholder вместо CachedNetworkImage',
        (WidgetTester tester) async {
          final CanvasItem item = createTvShowItem(
            tvShow: const TvShow(
              tmdbId: 300,
              title: 'No Poster Show',
              posterUrl: null,
            ),
          );

          await tester.pumpWidget(buildTestWidget(item));

          expect(find.text('No Poster Show'), findsOneWidget);
          expect(find.byIcon(Icons.tv_outlined), findsOneWidget);
          expect(find.byType(CachedNetworkImage), findsNothing);
        },
      );
    });
  });
}
