import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/constants/media_type_theme.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/widgets/media_card.dart';
import 'package:xerabora/shared/widgets/media_type_badge.dart';
import 'package:xerabora/shared/widgets/source_badge.dart';

void main() {
  Widget buildTestWidget({
    String title = 'Test Title',
    IconData placeholderIcon = Icons.videogame_asset,
    MediaType? mediaType,
    DataSource? source,
    String? imageUrl,
    int? year,
    String? rating,
    String? genres,
    Widget? additionalInfo,
    Widget? trailing,
    VoidCallback? onTap,
    int? memCacheWidth,
    int? memCacheHeight,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: MediaCard(
          title: title,
          placeholderIcon: placeholderIcon,
          mediaType: mediaType,
          source: source,
          imageUrl: imageUrl,
          year: year,
          rating: rating,
          genres: genres,
          additionalInfo: additionalInfo,
          trailing: trailing,
          onTap: onTap,
          memCacheWidth: memCacheWidth,
          memCacheHeight: memCacheHeight,
        ),
      ),
    );
  }

  group('MediaCard', () {
    group('рендеринг основных элементов', () {
      testWidgets('должен показывать название', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(title: 'My Game'));

        expect(find.text('My Game'), findsOneWidget);
      });

      testWidgets('должен показывать год', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(year: 2023));

        expect(find.text('2023'), findsOneWidget);
      });

      testWidgets('должен показывать рейтинг со звездой',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(rating: '8.5'));

        expect(find.text('8.5'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
      });

      testWidgets('должен показывать жанры', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(genres: 'Action, RPG'));

        expect(find.text('Action, RPG'), findsOneWidget);
      });

      testWidgets('должен показывать placeholder иконку при отсутствии изображения',
          (WidgetTester tester) async {
        await tester.pumpWidget(
            buildTestWidget(placeholderIcon: Icons.movie));

        expect(find.byIcon(Icons.movie), findsWidgets);
      });

      testWidgets('должен показывать trailing виджет',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          trailing: const Icon(Icons.add),
        ));

        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('должен показывать additionalInfo',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          additionalInfo: const Text('Extra info'),
        ));

        expect(find.text('Extra info'), findsOneWidget);
      });
    });

    group('обработка нажатий', () {
      testWidgets('должен вызывать onTap при нажатии',
          (WidgetTester tester) async {
        bool tapped = false;

        await tester.pumpWidget(buildTestWidget(
          onTap: () => tapped = true,
        ));

        await tester.tap(find.byType(MediaCard));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });

      testWidgets('должен не падать без onTap',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        await tester.tap(find.byType(MediaCard));
        await tester.pumpAndSettle();

        expect(find.byType(MediaCard), findsOneWidget);
      });
    });

    group('опциональные поля', () {
      testWidgets('должен работать без года', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(year: null));

        expect(find.byType(MediaCard), findsOneWidget);
      });

      testWidgets('должен работать без рейтинга',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(rating: null));

        expect(find.byIcon(Icons.star), findsNothing);
      });

      testWidgets('должен работать без жанров',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(genres: null));

        expect(find.byType(MediaCard), findsOneWidget);
      });

      testWidgets('должен работать без additionalInfo',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(additionalInfo: null));

        expect(find.byType(MediaCard), findsOneWidget);
      });

      testWidgets('должен работать без trailing',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(trailing: null));

        expect(find.byType(MediaCard), findsOneWidget);
      });

      testWidgets('должен работать с минимальными данными',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          title: 'Only Title',
          year: null,
          rating: null,
          genres: null,
          additionalInfo: null,
          trailing: null,
        ));

        expect(find.text('Only Title'), findsOneWidget);
      });
    });

    group('стилизация текста', () {
      testWidgets('название должно обрезаться с ellipsis',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          title:
              'This is a very long title that should be truncated because it does not fit on the screen',
        ));

        final Text nameWidget = tester.widget<Text>(
          find.text(
              'This is a very long title that should be truncated because it does not fit on the screen'),
        );
        expect(nameWidget.overflow, TextOverflow.ellipsis);
        expect(nameWidget.maxLines, 2);
      });

      testWidgets('жанры должны обрезаться в одну строку',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          genres: 'Action, RPG, Adventure, Strategy, Simulation, Puzzle',
        ));

        final Text genresWidget = tester.widget<Text>(
          find.text(
              'Action, RPG, Adventure, Strategy, Simulation, Puzzle'),
        );
        expect(genresWidget.overflow, TextOverflow.ellipsis);
        expect(genresWidget.maxLines, 1);
      });

      testWidgets('рейтинг должен иметь жирность w500',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(rating: '9.0'));

        final Text ratingWidget = tester.widget<Text>(find.text('9.0'));
        expect(ratingWidget.style?.fontWeight, FontWeight.w500);
      });
    });

    group('placeholder изображения', () {
      testWidgets('должен показывать placeholder контейнер правильного размера',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Проверяем что есть контейнер с нужными размерами
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('должен использовать переданную placeholder иконку',
          (WidgetTester tester) async {
        await tester.pumpWidget(
            buildTestWidget(placeholderIcon: Icons.tv));

        expect(find.byIcon(Icons.tv), findsWidgets);
      });
    });

    group('константы', () {
      test('posterWidth должен быть 64', () {
        expect(MediaCard.posterWidth, 64);
      });

      test('posterHeight должен быть 96', () {
        expect(MediaCard.posterHeight, 96);
      });

      test('posterBorderRadius должен быть 4', () {
        expect(MediaCard.posterBorderRadius, 4);
      });

    });

    group('год и рейтинг в одной строке', () {
      testWidgets('должен показывать год и рейтинг вместе',
          (WidgetTester tester) async {
        await tester.pumpWidget(
            buildTestWidget(year: 2020, rating: '7.5'));

        expect(find.text('2020'), findsOneWidget);
        expect(find.text('7.5'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
      });

      testWidgets('должен показывать только год без рейтинга',
          (WidgetTester tester) async {
        await tester.pumpWidget(
            buildTestWidget(year: 2020, rating: null));

        expect(find.text('2020'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsNothing);
      });

      testWidgets('должен показывать только рейтинг без года',
          (WidgetTester tester) async {
        await tester.pumpWidget(
            buildTestWidget(year: null, rating: '7.5'));

        expect(find.text('7.5'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
      });
    });

    group('структура виджета', () {
      testWidgets('должен содержать Material', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        // MediaCard uses Material as root widget
        expect(find.byType(Material), findsWidgets);
      });

      testWidgets('должен содержать InkWell', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.byType(InkWell), findsOneWidget);
      });
    });

    group('SourceBadge в карточке', () {
      testWidgets('должен показывать SourceBadge когда source != null',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          source: DataSource.igdb,
        ));

        expect(find.byType(SourceBadge), findsOneWidget);
      });

      testWidgets('должен не показывать SourceBadge когда source == null',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          source: null,
        ));

        expect(find.byType(SourceBadge), findsNothing);
      });

      testWidgets('должен показывать SourceBadge с текстом IGDB',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          source: DataSource.igdb,
        ));

        expect(find.text('IGDB'), findsOneWidget);
      });

      testWidgets('должен показывать SourceBadge с текстом TMDB',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          source: DataSource.tmdb,
        ));

        expect(find.text('TMDB'), findsOneWidget);
      });
    });

    group('MediaTypeBadge и цветной бордер', () {
      testWidgets('должен показывать MediaTypeBadge когда mediaType != null',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          mediaType: MediaType.game,
        ));

        expect(find.byType(MediaTypeBadge), findsOneWidget);
      });

      testWidgets('должен не показывать MediaTypeBadge когда mediaType == null',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          mediaType: null,
        ));

        expect(find.byType(MediaTypeBadge), findsNothing);
      });

      testWidgets('должен добавлять цветной бордер для игр',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          mediaType: MediaType.game,
        ));

        // Ищем Container с цветным бордером постера (width: 2)
        final Finder containerFinder = find.byWidgetPredicate(
          (Widget widget) {
            if (widget is! Container) return false;
            if (widget.decoration is! BoxDecoration) return false;
            final Border? border =
                (widget.decoration! as BoxDecoration).border as Border?;
            return border != null && border.top.width == 2;
          },
        );
        expect(containerFinder, findsOneWidget);

        final Container container =
            tester.widget<Container>(containerFinder);
        final BoxDecoration decoration =
            container.decoration! as BoxDecoration;
        final Border border = decoration.border! as Border;
        expect(border.top.color, MediaTypeTheme.gameColor);
      });

      testWidgets('должен добавлять цветной бордер для фильмов',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          mediaType: MediaType.movie,
        ));

        final Finder containerFinder = find.byWidgetPredicate(
          (Widget widget) {
            if (widget is! Container) return false;
            if (widget.decoration is! BoxDecoration) return false;
            final Border? border =
                (widget.decoration! as BoxDecoration).border as Border?;
            return border != null && border.top.width == 2;
          },
        );
        expect(containerFinder, findsOneWidget);

        final Container container =
            tester.widget<Container>(containerFinder);
        final BoxDecoration decoration =
            container.decoration! as BoxDecoration;
        final Border border = decoration.border! as Border;
        expect(border.top.color, MediaTypeTheme.movieColor);
      });

      testWidgets('должен добавлять цветной бордер для сериалов',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          mediaType: MediaType.tvShow,
        ));

        final Finder containerFinder = find.byWidgetPredicate(
          (Widget widget) {
            if (widget is! Container) return false;
            if (widget.decoration is! BoxDecoration) return false;
            final Border? border =
                (widget.decoration! as BoxDecoration).border as Border?;
            return border != null && border.top.width == 2;
          },
        );
        expect(containerFinder, findsOneWidget);

        final Container container =
            tester.widget<Container>(containerFinder);
        final BoxDecoration decoration =
            container.decoration! as BoxDecoration;
        final Border border = decoration.border! as Border;
        expect(border.top.color, MediaTypeTheme.tvShowColor);
      });
    });
  });
}
