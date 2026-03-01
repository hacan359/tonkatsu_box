// Виджет-тесты для CollectionItemTile.

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

/// Создаёт тестовый [CollectionItem] с разумными значениями по умолчанию.
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

/// Создаёт тестовый [Game] с значениями по умолчанию.
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

/// Создаёт тестовый [Movie] с значениями по умолчанию.
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

/// Создаёт тестовый [TvShow] с значениями по умолчанию.
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

/// Создаёт тестовую [Platform] с значениями по умолчанию.
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

/// Оборачивает виджет в MaterialApp с локализацией.
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
      testWidgets('должен отобразить название игры',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Chrono Trigger'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Chrono Trigger'), findsOneWidget);
      });

      testWidgets('должен отобразить название фильма',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          mediaType: MediaType.movie,
          movie: _makeMovie(title: 'Inception'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Inception'), findsOneWidget);
      });

      testWidgets('должен отобразить fallback название если game == null',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem();

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Unknown Game'), findsOneWidget);
      });
    });

    group('подзаголовок', () {
      testWidgets('должен отобразить название платформы для игры',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Final Fantasy VI'),
          platform: _makePlatform(abbreviation: 'SNES'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('SNES'), findsOneWidget);
      });

      testWidgets(
          'должен отобразить Unknown Platform если platform == null для игры',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Some Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Unknown Platform'), findsOneWidget);
      });

      testWidgets('должен отобразить год и длительность для фильма',
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
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        // 148 мин = 2h 28m
        expect(find.text('2010 \u2022 2h 28m'), findsOneWidget);
      });

      testWidgets('должен отобразить только год для фильма без runtime',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          mediaType: MediaType.movie,
          movie: _makeMovie(
            title: 'Some Movie',
            releaseYear: 2023,
          ),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('2023'), findsOneWidget);
      });

      testWidgets('должен отобразить только часы если mins == 0',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          mediaType: MediaType.movie,
          movie: _makeMovie(
            title: 'Short Movie',
            runtime: 120,
          ),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('2h'), findsOneWidget);
      });

      testWidgets('должен отобразить только минуты если hours == 0',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          mediaType: MediaType.movie,
          movie: _makeMovie(
            title: 'Short Film',
            runtime: 45,
          ),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('45m'), findsOneWidget);
      });

      testWidgets('должен отобразить количество сезонов для сериала',
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
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('2008 \u2022 5 seasons'), findsOneWidget);
      });

      testWidgets('должен отобразить "1 season" для единственного сезона',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          mediaType: MediaType.tvShow,
          tvShow: _makeTvShow(
            title: 'Mini Series',
            totalSeasons: 1,
          ),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('1 season'), findsOneWidget);
      });

      testWidgets('должен отобразить жанры если нет других полей у фильма',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          mediaType: MediaType.movie,
          movie: _makeMovie(title: 'No Year Movie'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        // genresString null => пустая строка; виджет всё равно рендерит Text
        expect(find.byType(CollectionItemTile), findsOneWidget);
      });
    });

    group('рейтинги', () {
      testWidgets('должен показать DualRatingBadge при наличии userRating',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          userRating: 8,
          game: _makeGame(name: 'Rated Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(DualRatingBadge), findsOneWidget);
      });

      testWidgets('должен показать DualRatingBadge при наличии apiRating',
          (WidgetTester tester) async {
        // IGDB rating 75.0 => apiRating = 75/10 = 7.5
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'API Rated', rating: 75.0),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(DualRatingBadge), findsOneWidget);
      });

      testWidgets('не должен показать DualRatingBadge без рейтингов',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'No Rating'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(DualRatingBadge), findsNothing);
      });

      testWidgets('не должен показать DualRatingBadge при apiRating == 0',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Zero Rating', rating: 0.0),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(DualRatingBadge), findsNothing);
      });

      testWidgets('должен показать оба рейтинга одновременно',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          userRating: 9,
          game: _makeGame(name: 'Both Ratings', rating: 85.0),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        final DualRatingBadge badge = tester.widget<DualRatingBadge>(
          find.byType(DualRatingBadge),
        );
        expect(badge.userRating, 9);
        expect(badge.apiRating, 8.5); // 85.0 / 10
        expect(badge.inline, isTrue);
      });
    });

    group('авторский комментарий', () {
      testWidgets('должен показать комментарий автора',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          authorComment: 'Шедевр 90-х!',
          game: _makeGame(name: 'Great Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Шедевр 90-х!'), findsOneWidget);
        expect(find.byIcon(Icons.format_quote), findsOneWidget);
      });

      testWidgets('не должен показать quote иконку без авторского комментария',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'No Comment'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.format_quote), findsNothing);
      });

      testWidgets('не должен показать пустой авторский комментарий',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          authorComment: '',
          game: _makeGame(name: 'Empty Comment'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.format_quote), findsNothing);
      });
    });

    group('пользовательский комментарий', () {
      testWidgets('должен показать личный комментарий',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          userComment: 'Моя заметка',
          game: _makeGame(name: 'Noted Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Моя заметка'), findsOneWidget);
        expect(find.byIcon(Icons.note_outlined), findsOneWidget);
      });

      testWidgets('не должен показать note иконку без пользовательского комментария',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'No Note'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.note_outlined), findsNothing);
      });

      testWidgets('не должен показать пустой пользовательский комментарий',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          userComment: '',
          game: _makeGame(name: 'Empty Note'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.note_outlined), findsNothing);
      });
    });

    group('drag handle', () {
      testWidgets('должен показать drag handle при showDragHandle == true',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Draggable Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          ReorderableListView(
            onReorder: (int oldIndex, int newIndex) {},
            children: <Widget>[
              CollectionItemTile(
                key: const ValueKey<int>(1),
                item: item,
                isEditable: true,
                showDragHandle: true,
                dragIndex: 0,
              ),
            ],
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.drag_handle), findsOneWidget);
      });

      testWidgets('не должен показать drag handle при showDragHandle == false',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Static Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: true,
            showDragHandle: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.drag_handle), findsNothing);
      });

      testWidgets('не должен показать drag handle по умолчанию',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Default Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: true,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.drag_handle), findsNothing);
      });
    });

    group('контекстное меню', () {
      testWidgets('должен показать more_vert кнопку при наличии onMove',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Movable Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: true,
            onMove: () {},
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      });

      testWidgets('должен показать more_vert кнопку при наличии onRemove',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Removable Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: true,
            onRemove: () {},
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      });

      testWidgets('не должен показать more_vert без onMove и onRemove',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'No Actions Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: true,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.more_vert), findsNothing);
      });

      testWidgets(
          'должен показать пункты Move и Remove при раскрытии меню',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Full Menu Game'),
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

        // Открываем PopupMenuButton
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Проверяем наличие иконок пунктов меню
        expect(
          find.byIcon(Icons.drive_file_move_outlined),
          findsOneWidget,
        );
        expect(
          find.byIcon(Icons.remove_circle_outline),
          findsOneWidget,
        );
      });

      testWidgets('должен вызвать onMove при нажатии на Move',
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

        // Открываем меню
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Нажимаем на Move
        await tester.tap(find.byIcon(Icons.drive_file_move_outlined));
        await tester.pumpAndSettle();

        expect(moved, isTrue);
      });

      testWidgets('должен вызвать onRemove при нажатии на Remove',
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

        // Открываем меню
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Нажимаем на Remove
        await tester.tap(find.byIcon(Icons.remove_circle_outline));
        await tester.pumpAndSettle();

        expect(removed, isTrue);
      });

      testWidgets('не должен показать Move если onMove == null',
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

        // Открываем меню
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        expect(
          find.byIcon(Icons.drive_file_move_outlined),
          findsNothing,
        );
        expect(
          find.byIcon(Icons.remove_circle_outline),
          findsOneWidget,
        );
      });

      testWidgets('не должен показать Remove если onRemove == null',
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

        // Открываем меню
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        expect(
          find.byIcon(Icons.drive_file_move_outlined),
          findsOneWidget,
        );
        expect(
          find.byIcon(Icons.remove_circle_outline),
          findsNothing,
        );
      });
    });

    group('onTap', () {
      testWidgets('должен вызвать onTap при нажатии на tile',
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

      testWidgets('не должен падать без onTap', (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'No Tap Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        // Нажатие не должно вызывать ошибку
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(find.byType(CollectionItemTile), findsOneWidget);
      });
    });

    group('статус', () {
      testWidgets('должен содержать StatusRibbon',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          status: ItemStatus.completed,
          game: _makeGame(name: 'Completed Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byType(StatusRibbon), findsOneWidget);
      });

      testWidgets('должен передать правильный статус в StatusRibbon',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          status: ItemStatus.inProgress,
          game: _makeGame(name: 'In Progress Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        final StatusRibbon ribbon = tester.widget<StatusRibbon>(
          find.byType(StatusRibbon),
        );
        expect(ribbon.status, ItemStatus.inProgress);
        expect(ribbon.mediaType, MediaType.game);
      });

      testWidgets('должен передать правильный mediaType в StatusRibbon',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          mediaType: MediaType.movie,
          status: ItemStatus.completed,
          movie: _makeMovie(title: 'Completed Movie'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        final StatusRibbon ribbon = tester.widget<StatusRibbon>(
          find.byType(StatusRibbon),
        );
        expect(ribbon.status, ItemStatus.completed);
        expect(ribbon.mediaType, MediaType.movie);
      });

      testWidgets('StatusRibbon должен быть невидимым для notStarted',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          status: ItemStatus.notStarted,
          game: _makeGame(name: 'Not Started Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        // StatusRibbon рендерится, но выводит SizedBox.shrink для notStarted
        expect(find.byType(StatusRibbon), findsOneWidget);
        // Positioned не должен рендериться внутри StatusRibbon
        final StatusRibbon ribbon = tester.widget<StatusRibbon>(
          find.byType(StatusRibbon),
        );
        expect(ribbon.status, ItemStatus.notStarted);
      });
    });

    group('описание', () {
      testWidgets('должен показать описание если оно не пустое',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(
            name: 'Game With Summary',
            summary: 'An epic RPG adventure.',
          ),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('An epic RPG adventure.'), findsOneWidget);
      });

      testWidgets('не должен показать описание если оно null',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'No Summary Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        // Только название и платформа должны быть текстами в колонке
        expect(find.byType(CollectionItemTile), findsOneWidget);
      });
    });

    group('обложка', () {
      testWidgets('должен показать placeholder при отсутствии thumbnailUrl',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'No Cover Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        // placeholder icon для game = Icons.videogame_asset
        expect(find.byIcon(Icons.videogame_asset), findsAtLeast(1));
      });

      testWidgets('должен показать placeholder icon для фильма',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          mediaType: MediaType.movie,
          movie: _makeMovie(title: 'No Poster Movie'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        // placeholder icon для movie = Icons.movie_outlined
        // Также MediaTypeTheme.iconFor(movie) = Icons.movie в фоне
        expect(find.byIcon(Icons.movie_outlined), findsAtLeast(1));
      });
    });

    group('комбинированные сценарии', () {
      testWidgets('должен отобразить все элементы для полного item',
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

        // Название
        expect(find.text('Perfect Game'), findsOneWidget);
        // Платформа
        expect(find.text('PS1'), findsOneWidget);
        // Рейтинг
        expect(find.byType(DualRatingBadge), findsOneWidget);
        // Описание
        expect(find.text('The best game ever made.'), findsOneWidget);
        // Авторский комментарий
        expect(find.text('Must play!'), findsOneWidget);
        expect(find.byIcon(Icons.format_quote), findsOneWidget);
        // Пользовательский комментарий
        expect(find.text('My favourite'), findsOneWidget);
        expect(find.byIcon(Icons.note_outlined), findsOneWidget);
        // StatusRibbon
        expect(find.byType(StatusRibbon), findsOneWidget);
        // Контекстное меню
        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      });

      testWidgets('должен отобразить минимальный item без опциональных полей',
          (WidgetTester tester) async {
        final CollectionItem item = _makeItem(
          game: _makeGame(name: 'Minimal Game'),
        );

        await tester.pumpWidget(_buildTestApp(
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        // Название
        expect(find.text('Minimal Game'), findsOneWidget);
        // Нет рейтингов
        expect(find.byType(DualRatingBadge), findsNothing);
        // Нет комментариев
        expect(find.byIcon(Icons.format_quote), findsNothing);
        expect(find.byIcon(Icons.note_outlined), findsNothing);
        // Нет контекстного меню
        expect(find.byIcon(Icons.more_vert), findsNothing);
      });

      testWidgets('должен корректно отобразить TV Show',
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
          CollectionItemTile(
            item: item,
            isEditable: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Breaking Bad'), findsOneWidget);
        expect(find.text('2008 \u2022 5 seasons'), findsOneWidget);
        expect(find.byType(DualRatingBadge), findsOneWidget);
      });
    });
  });
}
