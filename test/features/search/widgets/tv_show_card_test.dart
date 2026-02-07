import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/widgets/tv_show_card.dart';
import 'package:xerabora/shared/models/tv_show.dart';

void main() {
  const TvShow testTvShow = TvShow(
    tmdbId: 1396,
    title: 'Breaking Bad',
    overview: 'A high school chemistry teacher turned meth manufacturer.',
    firstAirYear: 2008,
    rating: 8.9,
    genres: <String>['Drama', 'Crime'],
    totalSeasons: 5,
    totalEpisodes: 62,
    status: 'Ended',
  );

  const TvShow tvShowMinimal = TvShow(
    tmdbId: 1397,
    title: 'Minimal Show',
  );

  Widget buildTestWidget({
    TvShow tvShow = testTvShow,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: TvShowCard(
          tvShow: tvShow,
          onTap: onTap,
          trailing: trailing,
        ),
      ),
    );
  }

  group('TvShowCard', () {
    group('rendering basic elements', () {
      testWidgets('should show tv show title', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.text('Breaking Bad'), findsOneWidget);
      });

      testWidgets('should show rating with star icon',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.text('8.9'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
      });

      testWidgets('should show first air year', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.text('2008'), findsOneWidget);
      });

      testWidgets('should show genres', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.text('Drama, Crime'), findsOneWidget);
      });

      testWidgets('should show seasons and episodes',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.text('5 seasons \u2022 62 ep.'), findsOneWidget);
        expect(find.byIcon(Icons.video_library), findsOneWidget);
      });

      testWidgets('should show status', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.text('Ended'), findsOneWidget);
      });

      testWidgets('should show placeholder when no poster',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.byIcon(Icons.tv), findsOneWidget);
      });

      testWidgets('should show trailing widget', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          trailing: const Icon(Icons.add),
        ));

        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('should call onTap when tapped',
          (WidgetTester tester) async {
        bool tapped = false;

        await tester.pumpWidget(buildTestWidget(
          onTap: () => tapped = true,
        ));

        await tester.tap(find.byType(TvShowCard));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });
    });

    group('seasons formatting', () {
      testWidgets('should show singular season',
          (WidgetTester tester) async {
        const TvShow singleSeason = TvShow(
          tmdbId: 100,
          title: 'Single Season',
          totalSeasons: 1,
        );

        await tester.pumpWidget(buildTestWidget(tvShow: singleSeason));

        expect(find.text('1 season'), findsOneWidget);
      });

      testWidgets('should show plural seasons',
          (WidgetTester tester) async {
        const TvShow multiSeason = TvShow(
          tmdbId: 101,
          title: 'Multi Season',
          totalSeasons: 3,
        );

        await tester.pumpWidget(buildTestWidget(tvShow: multiSeason));

        expect(find.text('3 seasons'), findsOneWidget);
      });

      testWidgets('should show seasons with episodes',
          (WidgetTester tester) async {
        const TvShow withEpisodes = TvShow(
          tmdbId: 102,
          title: 'With Episodes',
          totalSeasons: 2,
          totalEpisodes: 20,
        );

        await tester.pumpWidget(buildTestWidget(tvShow: withEpisodes));

        expect(find.text('2 seasons \u2022 20 ep.'), findsOneWidget);
      });

      testWidgets('should show single season with episodes',
          (WidgetTester tester) async {
        const TvShow singleWithEps = TvShow(
          tmdbId: 103,
          title: 'Single With Eps',
          totalSeasons: 1,
          totalEpisodes: 10,
        );

        await tester.pumpWidget(buildTestWidget(tvShow: singleWithEps));

        expect(find.text('1 season \u2022 10 ep.'), findsOneWidget);
      });
    });

    group('edge cases', () {
      testWidgets('should work without rating', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(tvShow: tvShowMinimal));

        expect(find.text('Minimal Show'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsNothing);
      });

      testWidgets('should work without first air year',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(tvShow: tvShowMinimal));

        expect(find.text('Minimal Show'), findsOneWidget);
      });

      testWidgets('should work without genres', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(tvShow: tvShowMinimal));

        expect(find.text('Drama, Crime'), findsNothing);
      });

      testWidgets('should work without seasons and status',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(tvShow: tvShowMinimal));

        expect(find.byIcon(Icons.video_library), findsNothing);
      });

      testWidgets('should show only status without seasons',
          (WidgetTester tester) async {
        const TvShow statusOnly = TvShow(
          tmdbId: 200,
          title: 'Status Only',
          status: 'Returning Series',
        );

        await tester.pumpWidget(buildTestWidget(tvShow: statusOnly));

        expect(find.text('Returning Series'), findsOneWidget);
        expect(find.byIcon(Icons.video_library), findsNothing);
      });

      testWidgets('should show only seasons without status',
          (WidgetTester tester) async {
        const TvShow seasonsOnly = TvShow(
          tmdbId: 201,
          title: 'Seasons Only',
          totalSeasons: 3,
        );

        await tester.pumpWidget(buildTestWidget(tvShow: seasonsOnly));

        expect(find.text('3 seasons'), findsOneWidget);
      });

      testWidgets('should truncate long title', (WidgetTester tester) async {
        const TvShow longTitle = TvShow(
          tmdbId: 300,
          title:
              'This is a very long TV show title that should be truncated because it does not fit in the card',
        );

        await tester.pumpWidget(buildTestWidget(tvShow: longTitle));

        final Text nameWidget = tester.widget<Text>(
          find.text(
            'This is a very long TV show title that should be truncated because it does not fit in the card',
          ),
        );
        expect(nameWidget.overflow, TextOverflow.ellipsis);
        expect(nameWidget.maxLines, 2);
      });

      testWidgets('should not show trailing when null',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(trailing: null));

        expect(find.byIcon(Icons.add), findsNothing);
      });

      testWidgets('should truncate long genres list',
          (WidgetTester tester) async {
        const TvShow manyGenres = TvShow(
          tmdbId: 301,
          title: 'Many Genres',
          genres: <String>[
            'Action',
            'Adventure',
            'Comedy',
            'Drama',
            'Fantasy',
            'Horror',
          ],
        );

        await tester.pumpWidget(buildTestWidget(tvShow: manyGenres));

        final Text genresText = tester.widget<Text>(
          find.textContaining('Action'),
        );
        expect(genresText.overflow, TextOverflow.ellipsis);
        expect(genresText.maxLines, 1);
      });
    });

    group('poster', () {
      testWidgets('should show placeholder icon when posterUrl is null',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(tvShow: tvShowMinimal));

        expect(find.byIcon(Icons.tv), findsOneWidget);
      });

      testWidgets('should show CachedNetworkImage when posterUrl is set',
          (WidgetTester tester) async {
        const TvShow withPoster = TvShow(
          tmdbId: 400,
          title: 'With Poster',
          posterUrl: 'https://image.tmdb.org/t/p/w500/test.jpg',
        );

        await tester.pumpWidget(buildTestWidget(tvShow: withPoster));

        expect(find.byType(TvShowCard), findsOneWidget);
      });
    });

    group('theming', () {
      testWidgets('should use amber color for star icon',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        final Icon starIcon = tester.widget<Icon>(find.byIcon(Icons.star));
        expect(starIcon.color, Colors.amber.shade600);
      });

      testWidgets('should use correct size for star icon',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        final Icon starIcon = tester.widget<Icon>(find.byIcon(Icons.star));
        expect(starIcon.size, 14);
      });

      testWidgets('should use primary color for video_library icon',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        final Icon videoIcon =
            tester.widget<Icon>(find.byIcon(Icons.video_library));
        final ThemeData theme =
            Theme.of(tester.element(find.byIcon(Icons.video_library)));
        expect(videoIcon.color, theme.colorScheme.primary);
      });

      testWidgets('should use italic style for status text',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        final Text statusText = tester.widget<Text>(find.text('Ended'));
        expect(statusText.style?.fontStyle, FontStyle.italic);
      });
    });
  });
}
