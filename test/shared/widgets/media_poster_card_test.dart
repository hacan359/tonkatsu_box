import 'package:core/models/data_source.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/services/image_cache_service.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/utils/item_card_progress.dart';
import 'package:tonkatsu_box/shared/widgets/dual_rating_badge.dart';
import 'package:tonkatsu_box/shared/widgets/media_poster_card.dart';
import 'package:tonkatsu_box/shared/widgets/source_logo.dart';

void main() {
  Widget buildCard({
    CardVariant variant = CardVariant.grid,
    String title = 'Test Title',
    String imageUrl = '',
    ImageType cacheImageType = ImageType.gameCover,
    String cacheImageId = '123',
    double? userRating,
    double? apiRating,
    bool splitRatings = false,
    bool isInCollection = false,
    ItemStatus? status,
    int? year,
    String? subtitle,
    MediaType? mediaType,
    IconData? placeholderIcon,
    int? timeToBeatHours,
    ItemCardProgress? progress,
    bool isFavorite = false,
    bool showFavorite = false,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onOpenInCollection,
    VoidCallback? onToggleFavorite,
    TextScaler textScaler = TextScaler.noScaling,
    DataSource? source,
    VoidCallback? onSourceTap,
  }) {
    return MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: SizedBox(
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
                splitRatings: splitRatings,
                isInCollection: isInCollection,
                status: status,
                year: year,
                subtitle: subtitle,
                mediaType: mediaType,
                placeholderIcon: placeholderIcon,
                timeToBeatHours: timeToBeatHours,
                progress: progress,
                isFavorite: isFavorite,
                showFavorite: showFavorite,
                onTap: onTap,
                onLongPress: onLongPress,
                onOpenInCollection: onOpenInCollection,
                onToggleFavorite: onToggleFavorite,
                source: source,
                onSourceTap: onSourceTap,
              ),
            ),
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

      testWidgets(
          'should show both ratings in the subtitle line when not split',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(userRating: 8, apiRating: 7.5));
        await tester.pumpAndSettle();

        expect(find.byType(DualRatingBadge), findsNothing);
        expect(find.text('★8.0 / 7.5'), findsOneWidget);
      });

      testWidgets(
          'should keep the personal rating in the badge when split',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          userRating: 8,
          apiRating: 7.5,
          splitRatings: true,
        ));
        await tester.pumpAndSettle();

        expect(find.byType(DualRatingBadge), findsOneWidget);
        expect(find.text('★7.5'), findsOneWidget);
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

    group('progress', () {
      testWidgets('should show метку прогресса когда progress задан',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          status: ItemStatus.inProgress,
          progress: const ItemCardProgress(label: '12/24', fraction: 0.5),
        ));

        expect(find.text('12/24'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should show метку без бара когда fraction == null',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          progress: const ItemCardProgress(label: 'V2 · 12'),
        ));

        expect(find.text('V2 · 12'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('не should show метку без progress',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(status: ItemStatus.inProgress));

        expect(find.text('12/24'), findsNothing);
        expect(tester.takeException(), isNull);
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
          splitRatings: true,
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
        // A two-line title plus the subtitle must fit the fixed-height block.
        expect(tester.takeException(), isNull);
      });

      testWidgets('должен показывать логотип источника, когда он задан',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          title: 'Berserk',
          year: 1989,
          mediaType: MediaType.manga,
          source: DataSource.anilist,
        ));
        await tester.pumpAndSettle();

        expect(find.byType(SourceLogo), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('не должен показывать логотип без источника',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(title: 'Berserk', year: 1989));
        await tester.pumpAndSettle();

        expect(find.byType(SourceLogo), findsNothing);
      });

      testWidgets('должен вызывать onSourceTap по тапу на логотип',
          (WidgetTester tester) async {
        int taps = 0;
        await tester.pumpWidget(buildCard(
          title: 'Berserk',
          year: 1989,
          source: DataSource.anilist,
          onSourceTap: () => taps++,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(SourceLogo));
        await tester.pumpAndSettle();

        expect(taps, 1);
      });

      testWidgets('логотип не должен быть кликабельным без onSourceTap',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          title: 'Berserk',
          year: 1989,
          source: DataSource.anilist,
        ));
        await tester.pumpAndSettle();

        expect(
          find.ancestor(
            of: find.byType(SourceLogo),
            matching: find.byType(InkWell),
          ),
          findsNothing,
        );
      });

      testWidgets('логотип источника не должен ломать блок названия',
          (WidgetTester tester) async {
        // Two title lines plus the meta line must still fit the fixed block.
        await tester.pumpWidget(buildCard(
          title: 'A' * 200,
          year: 1989,
          subtitle: 'Seinen',
          mediaType: MediaType.manga,
          source: DataSource.anilist,
          onSourceTap: () {},
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('должен вмещать текст при увеличенном системном шрифте',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          title: 'A' * 200,
          year: 2017,
          subtitle: 'RPG',
          textScaler: const TextScaler.linear(2),
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('подпись должна идти сразу под однострочным названием',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(title: 'Dark', year: 2017));
        await tester.pumpAndSettle();

        final Rect title = tester.getRect(find.text('Dark'));
        final Rect subtitle = tester.getRect(find.text('2017'));
        expect(subtitle.top, lessThanOrEqualTo(title.bottom + 1));
      });

      testWidgets(
          'подпись должна идти сразу под однострочным названием (compact)',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildCard(
          variant: CardVariant.compact,
          title: 'Dark',
          year: 2017,
        ));
        await tester.pumpAndSettle();

        final Rect title = tester.getRect(find.text('Dark'));
        final Rect subtitle = tester.getRect(find.text('2017'));
        expect(subtitle.top, lessThanOrEqualTo(title.bottom + 1));
        expect(tester.takeException(), isNull);
      });

      testWidgets('должен отдавать полное название в Tooltip',
          (WidgetTester tester) async {
        final String title = 'A' * 200;
        await tester.pumpWidget(buildCard(title: title));
        await tester.pumpAndSettle();

        final Tooltip tooltip = tester.widget<Tooltip>(find.ancestor(
          of: find.text(title),
          matching: find.byType(Tooltip),
        ));
        expect(tooltip.message, title);
      });

      testWidgets('hover не ломает раскладку карточки',
          (WidgetTester tester) async {
        final String title = 'A' * 200;
        await tester.pumpWidget(buildCard(title: title));
        await tester.pumpAndSettle();

        final TestGesture gesture =
            await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await gesture.moveTo(tester.getCenter(find.byType(MediaPosterCard)));
        await tester.pumpAndSettle();

        final Text text = tester.widget<Text>(find.text(title));
        expect(text.maxLines, 2);
        expect(tester.takeException(), isNull);
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

    group('narrow compact layout', () {
      testWidgets(
          'should not overflow with status, progress and tag at 60px width',
          (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 60,
              height: 250,
              child: MediaPosterCard(
                variant: CardVariant.compact,
                title: 'Test Show',
                imageUrl: '',
                cacheImageType: ImageType.tvShowPoster,
                cacheImageId: '1',
                status: ItemStatus.inProgress,
                progress: ItemCardProgress(label: '12/22', fraction: 0.5),
                tagName: 'Very Long Tag Name',
                tagColor: 0xFF4CAF50,
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('should keep the progress label on the right, tag on the left',
          (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 150,
              height: 250,
              child: MediaPosterCard(
                variant: CardVariant.grid,
                title: 'Test Show',
                imageUrl: '',
                cacheImageType: ImageType.tvShowPoster,
                cacheImageId: '1',
                progress: ItemCardProgress(label: '12/22', fraction: 0.5),
                tagName: 'Tag',
                tagColor: 0xFF4CAF50,
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        final Rect card = tester.getRect(find.byType(MediaPosterCard));
        final Rect badge = tester.getRect(find.text('Tag'));
        final Rect progress = tester.getRect(find.text('12/22'));

        expect(badge.left - card.left, lessThan(20));
        expect(card.right - progress.right, lessThan(20));
        expect(badge.right, lessThanOrEqualTo(progress.left));
      });
    });
  });
}
