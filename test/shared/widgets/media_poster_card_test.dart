import 'package:xerabora/l10n/app_localizations.dart';
// Виджет-тесты для MediaPosterCard.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/core/services/image_cache_service.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/theme/app_colors.dart';
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
          ),
        ),
      ),
    );
  }

  group('MediaPosterCard', () {
    group('CardVariant enum', () {
      test('должен содержать 3 варианта', () {
        expect(CardVariant.values.length, 3);
      });

      test('должен содержать grid, compact, canvas', () {
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
        await tester.pumpWidget(buildCard(
          year: 2015,
          subtitle: 'RPG',
        ));
        await tester.pumpAndSettle();

        expect(find.text('2015 \u00b7 RPG'), findsOneWidget);
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

      testWidgets('не должен показывать подзаголовок без года и subtitle',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard());
        await tester.pumpAndSettle();

        // Только заголовок, без subtitle row
        final Finder columnFinder = find.byType(Column);
        expect(columnFinder, findsWidgets);
      });

      testWidgets('должен показать DualRatingBadge с рейтингами',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          userRating: 8,
          apiRating: 7.5,
        ));
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

      testWidgets('должен показать бейдж "в коллекции"',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(isInCollection: true));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('не должен показывать бейдж "в коллекции" по умолчанию',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check), findsNothing);
      });

      testWidgets('должен показать иконку статуса (inProgress)',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          status: ItemStatus.inProgress,
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(ItemStatus.inProgress.materialIcon), findsOneWidget);
      });

      testWidgets('не должен показывать статус notStarted',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          status: ItemStatus.notStarted,
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(ItemStatus.notStarted.materialIcon), findsNothing);
      });

      testWidgets('не должен показывать статус null',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard());
        await tester.pumpAndSettle();

        // Никаких статус-иконок
        for (final ItemStatus status in ItemStatus.values) {
          if (status != ItemStatus.notStarted) {
            expect(find.byIcon(status.materialIcon), findsNothing);
          }
        }
      });

      testWidgets('должен показать placeholder иконку при пустом imageUrl',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(imageUrl: ''));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      });

      testWidgets('должен показать кастомную placeholder иконку',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          imageUrl: '',
          placeholderIcon: Icons.gamepad,
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.gamepad), findsOneWidget);
      });

      testWidgets('должен обработать onTap',
          (WidgetTester tester) async {
        bool tapped = false;
        await tester.pumpWidget(buildCard(
          onTap: () => tapped = true,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(GestureDetector).first);
        expect(tapped, isTrue);
      });

      testWidgets('должен обработать onLongPress',
          (WidgetTester tester) async {
        bool longPressed = false;
        await tester.pumpWidget(buildCard(
          onLongPress: () => longPressed = true,
        ));
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
        expect(mouseRegions, findsOneWidget);
        final MouseRegion region =
            tester.widget<MouseRegion>(mouseRegions);
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
        expect(mouseRegions, findsOneWidget);
        final MouseRegion region =
            tester.widget<MouseRegion>(mouseRegions);
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

      testWidgets('должен показать затемнение на постере',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard());
        await tester.pumpAndSettle();

        // ColoredBox с 0x30000000 (затемнение)
        final Finder coloredBoxes = find.byType(ColoredBox);
        bool foundDimOverlay = false;
        for (int i = 0; i < tester.widgetList(coloredBoxes).length; i++) {
          final ColoredBox box =
              tester.widget<ColoredBox>(coloredBoxes.at(i));
          if (box.color == const Color(0x30000000)) {
            foundDimOverlay = true;
            break;
          }
        }
        expect(foundDimOverlay, isTrue);
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

      testWidgets('должен показать DualRatingBadge с compact=true',
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

      testWidgets('должен показать уменьшенный check badge',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          variant: CardVariant.compact,
          isInCollection: true,
        ));
        await tester.pumpAndSettle();

        final Icon checkIcon =
            tester.widget<Icon>(find.byIcon(Icons.check));
        expect(checkIcon.size, 8.0);
      });

      testWidgets('должен показать placeholder с уменьшенной иконкой',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          variant: CardVariant.compact,
          imageUrl: '',
        ));
        await tester.pumpAndSettle();

        final Icon icon =
            tester.widget<Icon>(find.byIcon(Icons.image_outlined));
        expect(icon.size, 16.0);
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

      testWidgets('должен иметь Card с elevation 2',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          variant: CardVariant.canvas,
          mediaType: MediaType.game,
        ));
        await tester.pumpAndSettle();

        final Card card = tester.widget<Card>(find.byType(Card));
        expect(card.elevation, 2.0);
      });

      testWidgets('должен иметь Card с clipBehavior antiAlias',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          variant: CardVariant.canvas,
          mediaType: MediaType.game,
        ));
        await tester.pumpAndSettle();

        final Card card = tester.widget<Card>(find.byType(Card));
        expect(card.clipBehavior, Clip.antiAlias);
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

      testWidgets('не должен показывать check badge на canvas',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          variant: CardVariant.canvas,
          isInCollection: true,
          mediaType: MediaType.game,
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check), findsNothing);
      });

      testWidgets('не должен показывать статус на canvas',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          variant: CardVariant.canvas,
          status: ItemStatus.inProgress,
          mediaType: MediaType.game,
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(ItemStatus.inProgress.materialIcon), findsNothing);
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

        expect(find.text('2015 \u00b7 RPG'), findsNothing);
      });

      testWidgets('должен показать placeholder при пустом imageUrl',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          variant: CardVariant.canvas,
          imageUrl: '',
          mediaType: MediaType.game,
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.image_outlined), findsOneWidget);
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

      testWidgets('не должен иметь MouseRegion (hover) на canvas',
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

      testWidgets('Card должен иметь рамку с шириной 2',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          variant: CardVariant.canvas,
          mediaType: MediaType.game,
        ));
        await tester.pumpAndSettle();

        final Card card = tester.widget<Card>(find.byType(Card));
        final RoundedRectangleBorder shape =
            card.shape! as RoundedRectangleBorder;
        final BorderSide side = shape.side;
        expect(side.width, 2.0);
      });

      testWidgets('Card без mediaType должен использовать surfaceBorder',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          variant: CardVariant.canvas,
        ));
        await tester.pumpAndSettle();

        final Card card = tester.widget<Card>(find.byType(Card));
        final RoundedRectangleBorder shape =
            card.shape! as RoundedRectangleBorder;
        expect(shape.side.color, AppColors.surfaceBorder);
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

    group('все статусы кроме notStarted', () {
      for (final ItemStatus status in ItemStatus.values) {
        if (status == ItemStatus.notStarted) continue;

        testWidgets('должен показать иконку для $status',
            (WidgetTester tester) async {
          await tester.pumpWidget(buildCard(status: status));
          await tester.pumpAndSettle();

          expect(find.byIcon(status.materialIcon), findsOneWidget);
        });
      }
    });

    group('grid title', () {
      testWidgets('должен обрезать длинное название',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          title: 'A' * 200,
        ));
        await tester.pumpAndSettle();

        final Text text = tester.widget<Text>(find.text('A' * 200));
        expect(text.maxLines, 1);
        expect(text.overflow, TextOverflow.ellipsis);
      });
    });

    group('collection check badge цвет', () {
      testWidgets('должен использовать AppColors.success',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(isInCollection: true));
        await tester.pumpAndSettle();

        // Ищем Container с success цветом
        final Finder containers = find.byType(Container);
        bool foundSuccessBadge = false;
        for (int i = 0; i < tester.widgetList(containers).length; i++) {
          final Container container =
              tester.widget<Container>(containers.at(i));
          if (container.decoration is BoxDecoration) {
            final BoxDecoration deco =
                container.decoration! as BoxDecoration;
            if (deco.color == AppColors.success &&
                deco.shape == BoxShape.circle) {
              foundSuccessBadge = true;
              break;
            }
          }
        }
        expect(foundSuccessBadge, isTrue);
      });
    });
  });
}
