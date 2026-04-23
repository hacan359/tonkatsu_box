// Виджет-тесты для CollectionItemTile.
// Фокус: данные из модели доходят до UI, коллбэки вызываются, опциональные
// секции появляются/скрываются. Не проверяем конкретные иконки/цвета/отступы —
// это design decisions, тесты не должны ломаться от их изменения.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/widgets/collection_item_tile.dart';
import 'package:xerabora/features/collections/widgets/status_ribbon.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/platform.dart';
import 'package:xerabora/shared/models/tv_show.dart';
import 'package:xerabora/shared/widgets/dual_rating_badge.dart';

CollectionItem _makeItem({
  int id = 1,
  int? collectionId = 10,
  MediaType mediaType = MediaType.game,
  int externalId = 100,
  ItemStatus status = ItemStatus.notStarted,
  int? platformId,
  String? authorComment,
  String? userComment,
  int? userRating,
  Game? game,
  Movie? movie,
  TvShow? tvShow,
  Platform? platform,
}) {
  return CollectionItem(
    id: id,
    collectionId: collectionId,
    mediaType: mediaType,
    externalId: externalId,
    status: status,
    addedAt: DateTime(2024),
    platformId: platformId,
    authorComment: authorComment,
    userComment: userComment,
    userRating: userRating,
    game: game,
    movie: movie,
    tvShow: tvShow,
    platform: platform,
  );
}

Game _makeGame({
  int id = 100,
  String name = 'Test Game',
  double? rating,
  String? summary,
  String? coverUrl,
  DateTime? releaseDate,
  List<String>? genres,
}) {
  return Game(
    id: id,
    name: name,
    rating: rating,
    summary: summary,
    coverUrl: coverUrl,
    releaseDate: releaseDate,
    genres: genres,
  );
}

Movie _makeMovie({
  int tmdbId = 200,
  String title = 'Test Movie',
  double? rating,
  int? releaseYear,
  int? runtime,
  String? overview,
  String? posterUrl,
}) {
  return Movie(
    tmdbId: tmdbId,
    title: title,
    rating: rating,
    releaseYear: releaseYear,
    runtime: runtime,
    overview: overview,
    posterUrl: posterUrl,
  );
}

TvShow _makeTvShow({
  int tmdbId = 300,
  String title = 'Test TV Show',
  double? rating,
  int? firstAirYear,
  int? totalSeasons,
  int? totalEpisodes,
  String? overview,
  String? posterUrl,
}) {
  return TvShow(
    tmdbId: tmdbId,
    title: title,
    rating: rating,
    firstAirYear: firstAirYear,
    totalSeasons: totalSeasons,
    totalEpisodes: totalEpisodes,
    overview: overview,
    posterUrl: posterUrl,
  );
}

Platform _makePlatform({
  int id = 1,
  String name = 'Super Nintendo',
  String? abbreviation = 'SNES',
}) {
  return Platform(
    id: id,
    name: name,
    abbreviation: abbreviation,
  );
}

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('CollectionItemTile', () {
    group('название', () {
      testWidgets('показывает имя игры из данных',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Chrono Trigger'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Chrono Trigger'), findsOneWidget);
      });

      testWidgets('показывает название фильма из данных',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          mediaType: MediaType.movie,
          movie: _makeMovie(title: 'Inception'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Inception'), findsOneWidget);
      });

      testWidgets('показывает fallback-текст когда игра не загружена',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem();

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Unknown Game'), findsOneWidget);
      });
    });

    group('подзаголовок', () {
      testWidgets('показывает аббревиатуру платформы для игры',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Final Fantasy VI'),
          platform: _makePlatform(abbreviation: 'SNES'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        expect(find.text('SNES'), findsOneWidget);
      });

      testWidgets('показывает fallback-текст когда платформа не задана',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Some Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Unknown Platform'), findsOneWidget);
      });

      testWidgets('форматирует год и runtime фильма (148 мин → 2h 28m)',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          mediaType: MediaType.movie,
          movie: _makeMovie(
            title: 'Inception',
            releaseYear: 2010,
            runtime: 148,
          ),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        expect(find.text('2010 • 2h 28m'), findsOneWidget);
      });

      testWidgets('показывает только год если runtime не задан',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          mediaType: MediaType.movie,
          movie: _makeMovie(title: 'Some Movie', releaseYear: 2023),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        expect(find.text('2023'), findsOneWidget);
      });

      testWidgets('форматирует runtime как "2h" когда минуты = 0',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          mediaType: MediaType.movie,
          movie: _makeMovie(title: 'Short Movie', runtime: 120),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        expect(find.text('2h'), findsOneWidget);
      });

      testWidgets('форматирует runtime как "45m" когда часов < 1',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          mediaType: MediaType.movie,
          movie: _makeMovie(title: 'Short Film', runtime: 45),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        expect(find.text('45m'), findsOneWidget);
      });

      testWidgets('форматирует подзаголовок сериала с годом и сезонами',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          mediaType: MediaType.tvShow,
          tvShow: _makeTvShow(
            title: 'Breaking Bad',
            firstAirYear: 2008,
            totalSeasons: 5,
          ),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        expect(find.text('2008 • 5 seasons'), findsOneWidget);
      });

      testWidgets('использует единственное число "1 season" для одного сезона',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          mediaType: MediaType.tvShow,
          tvShow: _makeTvShow(title: 'Mini Series', totalSeasons: 1),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        expect(find.text('1 season'), findsOneWidget);
      });
    });

    group('рейтинги', () {
      testWidgets('показывает DualRatingBadge при наличии userRating',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          userRating: 8,
          game: _makeGame(name: 'Rated Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(DualRatingBadge), findsOneWidget);
      });

      testWidgets('показывает DualRatingBadge при наличии apiRating',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'API Rated', rating: 75.0),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(DualRatingBadge), findsOneWidget);
      });

      testWidgets('не показывает DualRatingBadge без рейтингов',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'No Rating'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(DualRatingBadge), findsNothing);
      });

      testWidgets('не показывает DualRatingBadge при apiRating == 0',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Zero Rating', rating: 0.0),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(DualRatingBadge), findsNothing);
      });

      testWidgets(
          'передаёт userRating и apiRating в DualRatingBadge (85.0 → 8.5)',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          userRating: 9,
          game: _makeGame(name: 'Both Ratings', rating: 85.0),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        final DualRatingBadge badge = tester.widget<DualRatingBadge>(
          find.byType(DualRatingBadge),
        );
        expect(badge.userRating, 9);
        expect(badge.apiRating, 8.5);
        expect(badge.inline, isTrue);
      });
    });

    group('комментарии', () {
      testWidgets('показывает текст авторского комментария',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          authorComment: 'Шедевр 90-х!',
          game: _makeGame(name: 'Great Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Шедевр 90-х!'), findsOneWidget);
      });

      testWidgets('не показывает пустой авторский комментарий как текст',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          authorComment: '',
          game: _makeGame(name: 'Empty Comment'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        expect(find.text(''), findsNothing);
      });

      testWidgets('показывает текст пользовательского комментария',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          userComment: 'Моя заметка',
          game: _makeGame(name: 'Noted Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Моя заметка'), findsOneWidget);
      });
    });

    group('контекстное меню (PopupMenuButton)', () {
      testWidgets('показывается когда задан onMove',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Movable Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: true, onMove: () {}),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      });

      testWidgets('показывается когда задан onRemove',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Removable Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: true, onRemove: () {}),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      });

      testWidgets('не показывается без onMove/onClone/onRemove',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'No Actions Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: true),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(PopupMenuButton<String>), findsNothing);
      });

      testWidgets('onClone вызывается при выборе пункта Clone',
          (WidgetTester tester) async {
        bool cloned = false;
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Clone Callback Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: true,
            onMove: () {},
            onClone: () => cloned = true,
            onRemove: () {},
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        // value 'clone' задан в collection_item_tile.dart — это контракт
        // PopupMenuButton, не UI-деталь.
        await tester.tap(find.byWidgetPredicate(
          (Widget w) => w is PopupMenuItem<String> && w.value == 'clone',
        ));
        await tester.pumpAndSettle();

        expect(cloned, isTrue);
      });

      testWidgets('onMove вызывается при выборе пункта Move',
          (WidgetTester tester) async {
        bool moved = false;
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Move Test Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: true,
            onMove: () => moved = true,
            onRemove: () {},
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.byWidgetPredicate(
          (Widget w) => w is PopupMenuItem<String> && w.value == 'move',
        ));
        await tester.pumpAndSettle();

        expect(moved, isTrue);
      });

      testWidgets('onRemove вызывается при выборе пункта Remove',
          (WidgetTester tester) async {
        bool removed = false;
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Remove Test Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: true,
            onMove: () {},
            onRemove: () => removed = true,
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.byWidgetPredicate(
          (Widget w) => w is PopupMenuItem<String> && w.value == 'remove',
        ));
        await tester.pumpAndSettle();

        expect(removed, isTrue);
      });

      testWidgets('пункт Move отсутствует когда onMove == null',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Remove Only Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: true,
            onRemove: () {},
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (Widget w) => w is PopupMenuItem<String> && w.value == 'move',
          ),
          findsNothing,
        );
        expect(
          find.byWidgetPredicate(
            (Widget w) => w is PopupMenuItem<String> && w.value == 'remove',
          ),
          findsOneWidget,
        );
      });

      testWidgets('пункт Remove отсутствует когда onRemove == null',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Move Only Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: true,
            onMove: () {},
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (Widget w) => w is PopupMenuItem<String> && w.value == 'move',
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (Widget w) => w is PopupMenuItem<String> && w.value == 'remove',
          ),
          findsNothing,
        );
      });
    });

    group('onTap', () {
      testWidgets('вызывает onTap при клике по карточке',
          (WidgetTester tester) async {
        bool tapped = false;
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Tappable Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
            onTap: () => tapped = true,
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(InkWell));
        expect(tapped, isTrue);
      });

      testWidgets('не падает без onTap', (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'No Tap Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });

    group('статус', () {
      testWidgets('рендерит StatusRibbon', (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          status: ItemStatus.completed,
          game: _makeGame(name: 'Completed Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(StatusRibbon), findsOneWidget);
      });

      testWidgets('передаёт status и mediaType в StatusRibbon',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          status: ItemStatus.inProgress,
          game: _makeGame(name: 'In Progress Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        final StatusRibbon ribbon = tester.widget<StatusRibbon>(
          find.byType(StatusRibbon),
        );
        expect(ribbon.status, ItemStatus.inProgress);
        expect(ribbon.mediaType, MediaType.game);
      });

      testWidgets('передаёт mediaType фильма в StatusRibbon',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          mediaType: MediaType.movie,
          status: ItemStatus.completed,
          movie: _makeMovie(title: 'Completed Movie'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        final StatusRibbon ribbon = tester.widget<StatusRibbon>(
          find.byType(StatusRibbon),
        );
        expect(ribbon.status, ItemStatus.completed);
        expect(ribbon.mediaType, MediaType.movie);
      });
    });

    group('описание', () {
      testWidgets('показывает summary игры', (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(
            name: 'Game With Summary',
            summary: 'An epic RPG adventure.',
          ),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        expect(find.text('An epic RPG adventure.'), findsOneWidget);
      });
    });

    group('комбинированные сценарии', () {
      testWidgets('полный item: все данные доходят до UI',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          status: ItemStatus.completed,
          userRating: 10,
          authorComment: 'Must play!',
          userComment: 'My favourite',
          game: _makeGame(
            name: 'Perfect Game',
            rating: 95.0,
            summary: 'The best game ever made.',
          ),
          platform: _makePlatform(abbreviation: 'PS1'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: true,
            onMove: () {},
            onRemove: () {},
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Perfect Game'), findsOneWidget);
        expect(find.text('PS1'), findsOneWidget);
        expect(find.text('The best game ever made.'), findsOneWidget);
        expect(find.text('Must play!'), findsOneWidget);
        expect(find.text('My favourite'), findsOneWidget);
        expect(find.byType(DualRatingBadge), findsOneWidget);
        expect(find.byType(StatusRibbon), findsOneWidget);
        expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      });

      testWidgets('минимальный item: нет рейтинга, меню, комментариев',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Minimal Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Minimal Game'), findsOneWidget);
        expect(find.byType(DualRatingBadge), findsNothing);
        expect(find.byType(PopupMenuButton<String>), findsNothing);
      });

      testWidgets('TV Show: data-driven текст и рейтинг',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          mediaType: MediaType.tvShow,
          status: ItemStatus.inProgress,
          tvShow: _makeTvShow(
            title: 'Breaking Bad',
            firstAirYear: 2008,
            totalSeasons: 5,
            rating: 8.9,
          ),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Breaking Bad'), findsOneWidget);
        expect(find.text('2008 • 5 seasons'), findsOneWidget);
        expect(find.byType(DualRatingBadge), findsOneWidget);
      });
    });

    group('onSecondaryTap (ПКМ)', () {
      testWidgets('вызывает onSecondaryTap при правом клике',
          (WidgetTester tester) async {
        Offset? receivedPosition;
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Right Click Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: true,
            onSecondaryTap: (Offset pos) => receivedPosition = pos,
          ),
        ));
        await tester.pumpAndSettle();

        final Offset center = tester.getCenter(find.byType(Card));
        final TestGesture gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryMouseButton,
        );
        await gesture.addPointer(location: center);
        await gesture.down(center);
        await gesture.up();
        await tester.pumpAndSettle();

        expect(receivedPosition, isNotNull);
      });

      testWidgets('ПКМ не ломает виджет когда onSecondaryTap == null',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'No Context Menu'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(item: item, isEditable: false),
        ));
        await tester.pumpAndSettle();

        final Offset center = tester.getCenter(find.byType(Card));
        final TestGesture gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryMouseButton,
        );
        await gesture.addPointer(location: center);
        await gesture.down(center);
        await gesture.up();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });
  });
}
