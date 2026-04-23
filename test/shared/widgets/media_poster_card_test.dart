// Виджет-тесты для MediaPosterCard.
// Фокус: данные из пропов доходят до UI, коллбэки вызываются, показ/скрытие
// секций в разных вариантах. Не проверяем размеры/цвета/конкретные иконки —
// design decisions, тесты не должны ломаться от их изменения.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/core/services/image_cache_service.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/widgets/dual_rating_badge.dart';
import 'package:xerabora/shared/widgets/media_poster_card.dart';

void main() {
  Widget buildCard({
    CardVariant variant = CardVariant.grid,
    String title = 'Test Title',
    String imageUrl = '',
    ImageType cacheImageType = ImageType.gameCover,
    String cacheImageId = '123',
    int? userRating,
    double? apiRating,
    bool isInCollection = false,
    ItemStatus? status,
    int? year,
    String? subtitle,
    MediaType? mediaType,
    IconData? placeholderIcon,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onOpenInCollection,
  }) {
    return MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 150,
          height: 250,
          child: MediaPosterCard(
            variant: variant,
            title: title,
            imageUrl: imageUrl,
            cacheImageType: cacheImageType,
            cacheImageId: cacheImageId,
            userRating: userRating,
            apiRating: apiRating,
            isInCollection: isInCollection,
            status: status,
            year: year,
            subtitle: subtitle,
            mediaType: mediaType,
            placeholderIcon: placeholderIcon,
            onTap: onTap,
            onLongPress: onLongPress,
            onOpenInCollection: onOpenInCollection,
          ),
        ),
      ),
    );
  }

  group('MediaPosterCard', () {
    group('CardVariant enum', () {
      test('содержит grid, compact, canvas', () {
        expect(CardVariant.values.length, 3);
        expect(CardVariant.values, contains(CardVariant.grid));
        expect(CardVariant.values, contains(CardVariant.compact));
        expect(CardVariant.values, contains(CardVariant.canvas));
      });
    });

    group('grid variant', () {
      testWidgets('должен показать название',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(title: 'The Witcher 3'));
        await tester.pumpAndSettle();

        expect(find.text('The Witcher 3'), findsOneWidget);
      });

      testWidgets('должен показать год и подзаголовок',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(year: 2015, subtitle: 'RPG'));
        await tester.pumpAndSettle();

        expect(find.text('2015 · RPG'), findsOneWidget);
      });

      testWidgets('должен показать только год без подзаголовка',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(year: 2015));
        await tester.pumpAndSettle();

        expect(find.text('2015'), findsOneWidget);
      });

      testWidgets('должен показать только подзаголовок без года',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(subtitle: 'Action'));
        await tester.pumpAndSettle();

        expect(find.text('Action'), findsOneWidget);
      });

      testWidgets('должен показать DualRatingBadge с рейтингами',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(userRating: 8, apiRating: 7.5));
        await tester.pumpAndSettle();

        expect(find.byType(DualRatingBadge), findsOneWidget);
        expect(find.text('8 / 7.5'), findsOneWidget);
      });

      testWidgets('не должен показывать DualRatingBadge без рейтингов',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard());
        await tester.pumpAndSettle();

        expect(find.byType(DualRatingBadge), findsNothing);
      });

      testWidgets('должен обработать onTap', (WidgetTester tester) async {
        bool tapped = false;
        await tester.pumpWidget(buildCard(onTap: () => tapped = true));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(GestureDetector).first);
        expect(tapped, isTrue);
      });

      testWidgets('должен обработать onLongPress',
          (WidgetTester tester) async {
        bool longPressed = false;
        await tester.pumpWidget(
          buildCard(onLongPress: () => longPressed = true),
        );
        await tester.pumpAndSettle();

        await tester.longPress(find.byType(GestureDetector).first);
        expect(longPressed, isTrue);
      });

      testWidgets('должен использовать click курсор при наличии onTap',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(onTap: () {}));
        await tester.pumpAndSettle();

        final Finder mouseRegions = find.descendant(
          of: find.byType(MediaPosterCard),
          matching: find.byType(MouseRegion),
        );
        expect(mouseRegions, findsAtLeastNWidgets(1));
        final MouseRegion region =
            tester.widget<MouseRegion>(mouseRegions.first);
        expect(region.cursor, SystemMouseCursors.click);
      });

      testWidgets('должен использовать basic курсор без onTap',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard());
        await tester.pumpAndSettle();

        final Finder mouseRegions = find.descendant(
          of: find.byType(MediaPosterCard),
          matching: find.byType(MouseRegion),
        );
        expect(mouseRegions, findsAtLeastNWidgets(1));
        final MouseRegion region =
            tester.widget<MouseRegion>(mouseRegions.first);
        expect(region.cursor, SystemMouseCursors.basic);
      });

      testWidgets('должен иметь Focus для keyboard навигации',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard());
        await tester.pumpAndSettle();

        final Finder focusWidgets = find.descendant(
          of: find.byType(MediaPosterCard),
          matching: find.byType(Focus),
        );
        expect(focusWidgets, findsOneWidget);
      });
    });

    group('compact variant', () {
      testWidgets('должен показать название',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          variant: CardVariant.compact,
          title: 'Compact Title',
        ));
        await tester.pumpAndSettle();

        expect(find.text('Compact Title'), findsOneWidget);
      });

      testWidgets('должен передавать compact=true в DualRatingBadge',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          variant: CardVariant.compact,
          userRating: 7,
        ));
        await tester.pumpAndSettle();

        final DualRatingBadge badge =
            tester.widget<DualRatingBadge>(find.byType(DualRatingBadge));
        expect(badge.compact, isTrue);
      });
    });

    group('canvas variant', () {
      testWidgets('должен показать название в Card',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          variant: CardVariant.canvas,
          title: 'Canvas Title',
          mediaType: MediaType.game,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Canvas Title'), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('не должен показывать DualRatingBadge на canvas',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          variant: CardVariant.canvas,
          userRating: 8,
          apiRating: 7.5,
          mediaType: MediaType.game,
        ));
        await tester.pumpAndSettle();

        expect(find.byType(DualRatingBadge), findsNothing);
      });

      testWidgets('не должен показывать год/подзаголовок на canvas',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          variant: CardVariant.canvas,
          year: 2015,
          subtitle: 'RPG',
          mediaType: MediaType.game,
        ));
        await tester.pumpAndSettle();

        expect(find.text('2015 · RPG'), findsNothing);
      });

      testWidgets('должен обработать onTap на canvas',
          (WidgetTester tester) async {
        bool tapped = false;
        await tester.pumpWidget(buildCard(
          variant: CardVariant.canvas,
          mediaType: MediaType.game,
          onTap: () => tapped = true,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(GestureDetector).first);
        expect(tapped, isTrue);
      });

      testWidgets('не должен иметь hover (MouseRegion) на canvas',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          variant: CardVariant.canvas,
          mediaType: MediaType.game,
        ));
        await tester.pumpAndSettle();

        final Finder mouseRegions = find.descendant(
          of: find.byType(MediaPosterCard),
          matching: find.byType(MouseRegion),
        );
        expect(mouseRegions, findsNothing);
      });

      testWidgets('Canvas title должен иметь maxLines: 2',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          variant: CardVariant.canvas,
          title: 'Very Long Canvas Title',
          mediaType: MediaType.game,
        ));
        await tester.pumpAndSettle();

        final Text titleText =
            tester.widget<Text>(find.text('Very Long Canvas Title'));
        expect(titleText.maxLines, 2);
        expect(titleText.overflow, TextOverflow.ellipsis);
      });
    });

    group('grid title', () {
      testWidgets('должен обрезать длинное название в 2 строки',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(title: 'A' * 200));
        await tester.pumpAndSettle();

        final Text text = tester.widget<Text>(find.text('A' * 200));
        expect(text.maxLines, 2);
        expect(text.overflow, TextOverflow.ellipsis);
      });

      testWidgets('должен показывать Tooltip с полным названием',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          title: 'Wolfenstein II: The New Colossus',
        ));
        await tester.pumpAndSettle();

        final Finder tooltipFinder = find.byType(Tooltip);
        expect(tooltipFinder, findsOneWidget);
        final Tooltip tooltip = tester.widget<Tooltip>(tooltipFinder);
        expect(tooltip.message, 'Wolfenstein II: The New Colossus');
      });
    });

    group('onOpenInCollection', () {
      testWidgets('должен вызвать onOpenInCollection при тапе',
          (WidgetTester tester) async {
        bool opened = false;
        await tester.pumpWidget(buildCard(
          isInCollection: true,
          onOpenInCollection: () => opened = true,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.open_in_new));
        await tester.pumpAndSettle();

        expect(opened, isTrue);
      });
    });
  });
}
