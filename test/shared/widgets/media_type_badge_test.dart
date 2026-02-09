import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/constants/media_type_theme.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/widgets/media_type_badge.dart';

void main() {
  Widget buildTestWidget({
    required MediaType mediaType,
    double size = 20,
    double iconSize = 12,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: MediaTypeBadge(
          mediaType: mediaType,
          size: size,
          iconSize: iconSize,
        ),
      ),
    );
  }

  group('MediaTypeBadge', () {
    group('рендеринг', () {
      testWidgets('должен показывать иконку игры',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(mediaType: MediaType.game));

        expect(find.byIcon(Icons.videogame_asset), findsOneWidget);
      });

      testWidgets('должен показывать иконку фильма',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(mediaType: MediaType.movie));

        expect(find.byIcon(Icons.movie), findsOneWidget);
      });

      testWidgets('должен показывать иконку сериала',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(mediaType: MediaType.tvShow));

        expect(find.byIcon(Icons.tv), findsOneWidget);
      });
    });

    group('цвета', () {
      testWidgets('должен использовать синий для игр',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(mediaType: MediaType.game));

        final Container container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final BoxDecoration decoration =
            container.decoration! as BoxDecoration;
        expect(decoration.color, MediaTypeTheme.gameColor);
      });

      testWidgets('должен использовать красный для фильмов',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(mediaType: MediaType.movie));

        final Container container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final BoxDecoration decoration =
            container.decoration! as BoxDecoration;
        expect(decoration.color, MediaTypeTheme.movieColor);
      });

      testWidgets('должен использовать зелёный для сериалов',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(mediaType: MediaType.tvShow));

        final Container container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final BoxDecoration decoration =
            container.decoration! as BoxDecoration;
        expect(decoration.color, MediaTypeTheme.tvShowColor);
      });

      testWidgets('иконка должна быть белой',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(mediaType: MediaType.game));

        final Icon icon = tester.widget<Icon>(
          find.byIcon(Icons.videogame_asset),
        );
        expect(icon.color, Colors.white);
      });
    });

    group('размеры', () {
      testWidgets('должен использовать размеры по умолчанию',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(mediaType: MediaType.game));

        final Container container = tester.widget<Container>(
          find.byType(Container).first,
        );
        expect(container.constraints?.maxWidth, 20);
        expect(container.constraints?.maxHeight, 20);
      });

      testWidgets('должен использовать кастомные размеры',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          mediaType: MediaType.game,
          size: 32,
          iconSize: 18,
        ));

        final Container container = tester.widget<Container>(
          find.byType(Container).first,
        );
        expect(container.constraints?.maxWidth, 32);
        expect(container.constraints?.maxHeight, 32);

        final Icon icon = tester.widget<Icon>(
          find.byIcon(Icons.videogame_asset),
        );
        expect(icon.size, 18);
      });

      testWidgets('должен использовать размер иконки по умолчанию',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(mediaType: MediaType.movie));

        final Icon icon = tester.widget<Icon>(
          find.byIcon(Icons.movie),
        );
        expect(icon.size, 12);
      });
    });
  });
}
