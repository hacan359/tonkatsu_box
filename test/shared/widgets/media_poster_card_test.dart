import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/services/image_cache_service.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/models/item_status.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/widgets/dual_rating_badge.dart';
import 'package:tonkatsu_box/shared/widgets/media_poster_card.dart';

void main() {
  Widget buildCard({
    CardVariant variant = CardVariant.grid,
    String title = 'Test Title',
    String imageUrl = '',
    ImageType cacheImageType = ImageType.gameCover,
    String cacheImageId = '123',
    double? userRating,
    double? apiRating,
    bool isInCollection = false,
    ItemStatus? status,
    int? year,
    String? subtitle,
    MediaType? mediaType,
    IconData? placeholderIcon,
    int? timeToBeatHours,
    bool isFavorite = false,
    bool showFavorite = false,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onOpenInCollection,
    VoidCallback? onToggleFavorite,
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
            timeToBeatHours: timeToBeatHours,
            isFavorite: isFavorite,
            showFavorite: showFavorite,
            onTap: onTap,
            onLongPress: onLongPress,
            onOpenInCollection: onOpenInCollection,
            onToggleFavorite: onToggleFavorite,
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
      testWidgets('should show название',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(title: 'The Witcher 3'));
        await tester.pumpAndSettle();

        expect(find.text('The Witcher 3'), findsOneWidget);
      });

      testWidgets('should show год и подзаголовок',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(year: 2015, subtitle: 'RPG'));
        await tester.pumpAndSettle();

        expect(find.text('2015 · RPG'), findsOneWidget);
      });

      testWidgets('should show только год без подзаголовка',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(year: 2015));
        await tester.pumpAndSettle();

        expect(find.text('2015'), findsOneWidget);
      });

      testWidgets('should show только подзаголовок без года',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(subtitle: 'Action'));
        await tester.pumpAndSettle();

        expect(find.text('Action'), findsOneWidget);
      });

      testWidgets('should show DualRatingBadge с рейтингами',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(userRating: 8, apiRating: 7.5));
        await tester.pumpAndSettle();

        expect(find.byType(DualRatingBadge), findsOneWidget);
        expect(find.text('8.0 / 7.5'), findsOneWidget);
      });

      testWidgets('не should show DualRatingBadge без рейтингов',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard());
        await tester.pumpAndSettle();

        expect(find.byType(DualRatingBadge), findsNothing);
      });

      testWidgets('should handle onTap', (WidgetTester tester) async {
        bool tapped = false;
        await tester.pumpWidget(buildCard(onTap: () => tapped = true));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(GestureDetector).first);
        expect(tapped, isTrue);
      });

      testWidgets('should handle onLongPress',
          (WidgetTester tester) async {
        bool longPressed = false;
        await tester.pumpWidget(
          buildCard(onLongPress: () => longPressed = true),
        );
        await tester.pumpAndSettle();

        await tester.longPress(find.byType(GestureDetector).first);
        expect(longPressed, isTrue);
      });

      testWidgets('should use click курсор при наличии onTap',
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

      testWidgets('should use basic курсор без onTap',
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

    group('favorite heart', () {
      // The heart is the only InkWell in a plain grid card, so locating it by
      // type stays robust if the icon/colour changes.
      testWidgets('tapping the heart fires onToggleFavorite, not onTap',
          (WidgetTester tester) async {
        bool toggled = false;
        bool cardTapped = false;
        await tester.pumpWidget(buildCard(
          onTap: () => cardTapped = true,
          onToggleFavorite: () => toggled = true,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(toggled, isTrue);
        expect(cardTapped, isFalse);
      });

      testWidgets('renders a static indicator when forced without a callback',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildCard(isFavorite: true, showFavorite: true),
        );
        await tester.pumpAndSettle();

        // Forced indicator is not interactive — no InkWell tap target.
        expect(find.byType(InkWell), findsNothing);
        expect(tester.takeException(), isNull);
      });
    });

    group('compact variant', () {
      testWidgets('should show название',
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
      testWidgets('should show название в Card',
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

      testWidgets('не should show DualRatingBadge на canvas',
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

      testWidgets('не should show год/подзаголовок на canvas',
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

      testWidgets('should handle onTap на canvas',
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

      testWidgets('should show Tooltip с полным названием',
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

    group('time-to-beat badge', () {
      testWidgets('shows the formatted hours when timeToBeatHours is set',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(timeToBeatHours: 71));
        await tester.pumpAndSettle();

        expect(find.text('71h'), findsOneWidget);
      });

      testWidgets('is hidden when timeToBeatHours is null',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.schedule), findsNothing);
      });

      testWidgets('is hidden when a status badge is shown',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          timeToBeatHours: 71,
          status: ItemStatus.inProgress,
        ));
        await tester.pumpAndSettle();

        expect(find.text('71h'), findsNothing);
      });

      testWidgets('is not rendered on the canvas variant',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          variant: CardVariant.canvas,
          mediaType: MediaType.game,
          timeToBeatHours: 71,
        ));
        await tester.pumpAndSettle();

        expect(find.text('71h'), findsNothing);
      });
    });

    group('onOpenInCollection', () {
      testWidgets('should call onOpenInCollection when tapped',
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
