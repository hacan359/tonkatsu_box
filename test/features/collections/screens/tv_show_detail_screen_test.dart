// Виджет-тесты для TvShowDetailScreen.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/features/collections/screens/tv_show_detail_screen.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/tv_show.dart';
import 'package:xerabora/shared/widgets/media_detail_view.dart';
import 'package:xerabora/shared/widgets/source_badge.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

void main() {
  final DateTime testDate = DateTime(2024, 6, 10, 12, 0, 0);

  late MockCollectionRepository mockRepo;

  CollectionItem createTestCollectionItem({
    int id = 1,
    int collectionId = 1,
    int externalId = 200,
    ItemStatus status = ItemStatus.notStarted,
    int currentSeason = 0,
    int currentEpisode = 0,
    String? authorComment,
    String? userComment,
    TvShow? tvShow,
  }) {
    return CollectionItem(
      id: id,
      collectionId: collectionId,
      mediaType: MediaType.tvShow,
      externalId: externalId,
      status: status,
      currentSeason: currentSeason,
      currentEpisode: currentEpisode,
      addedAt: testDate,
      authorComment: authorComment,
      userComment: userComment,
      tvShow: tvShow,
    );
  }

  TvShow createTestTvShow({
    int tmdbId = 200,
    String title = 'Test Show',
    String? posterUrl,
    String? backdropUrl,
    String? overview,
    List<String>? genres,
    int? firstAirYear,
    int? totalSeasons,
    int? totalEpisodes,
    double? rating,
    String? status,
  }) {
    return TvShow(
      tmdbId: tmdbId,
      title: title,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      overview: overview,
      genres: genres,
      firstAirYear: firstAirYear,
      totalSeasons: totalSeasons,
      totalEpisodes: totalEpisodes,
      rating: rating,
      status: status,
    );
  }

  setUp(() {
    mockRepo = MockCollectionRepository();

    // Регистрируем fallback-значения для mocktail
    registerFallbackValue(ItemStatus.notStarted);
    registerFallbackValue(MediaType.tvShow);
  });

  Widget createTestWidget({
    required int collectionId,
    required int itemId,
    required bool isEditable,
    required List<CollectionItem> items,
  }) {
    when(() => mockRepo.getItemsWithData(
          collectionId,
          mediaType: any(named: 'mediaType'),
        )).thenAnswer((_) async => items);

    return ProviderScope(
      overrides: <Override>[
        collectionRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        home: TvShowDetailScreen(
          collectionId: collectionId,
          itemId: itemId,
          isEditable: isEditable,
        ),
      ),
    );
  }

  group('TvShowDetailScreen', () {
    group('отображение заголовка', () {
      testWidgets('должен отображать название сериала в app bar',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(title: 'Breaking Bad');
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Breaking Bad'), findsWidgets);
      });

      testWidgets('должен отображать тип медиа TV Show',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow();
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('TV Show'), findsOneWidget);
      });
    });

    group('отображение изображения', () {
      testWidgets(
          'должен показывать placeholder иконку когда нет постера и бэкдропа',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(
          posterUrl: null,
          backdropUrl: null,
        );
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.tv_outlined), findsWidgets);
      });

      testWidgets(
          'должен показывать placeholder когда tvShow равен null',
          (WidgetTester tester) async {
        final CollectionItem item = createTestCollectionItem(tvShow: null);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Placeholder cover + media type icon
        expect(find.byIcon(Icons.tv_outlined), findsWidgets);
      });
    });

    group('отображение информационных чипов', () {
      testWidgets('должен отображать чип с годом выхода',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(firstAirYear: 2008);
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('2008'), findsOneWidget);
      });

      testWidgets('должен отображать чип с количеством сезонов (множественное)',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(totalSeasons: 5);
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('5 seasons'), findsOneWidget);
      });

      testWidgets('должен отображать чип с количеством сезонов (единственное)',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(totalSeasons: 1);
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('1 season'), findsOneWidget);
      });

      testWidgets('должен отображать чип с количеством эпизодов',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(totalEpisodes: 62);
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('62 ep'), findsOneWidget);
      });

      testWidgets('должен отображать чип с жанрами',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(
          genres: <String>['Drama', 'Crime', 'Thriller'],
        );
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Drama, Crime, Thriller'), findsOneWidget);
      });

      testWidgets('должен отображать чип с рейтингом',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(rating: 8.9);
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('8.9/10'), findsOneWidget);
      });

      testWidgets('должен отображать чип со статусом сериала Returning Series',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(status: 'Returning Series');
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Returning Series'), findsOneWidget);
      });

      testWidgets('должен отображать чип со статусом сериала Ended',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(status: 'Ended');
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Ended'), findsOneWidget);
      });

      testWidgets('должен отображать чип со статусом сериала Canceled',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(status: 'Canceled');
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Canceled'), findsOneWidget);
      });

      testWidgets('не должен отображать чипы когда все поля null',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(
          firstAirYear: null,
          totalSeasons: null,
          totalEpisodes: null,
          genres: null,
          rating: null,
          status: null,
        );
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.calendar_today_outlined), findsNothing);
        expect(find.byIcon(Icons.video_library_outlined), findsNothing);
        expect(find.byIcon(Icons.playlist_play), findsNothing);
        expect(find.byIcon(Icons.category_outlined), findsNothing);
        expect(find.byIcon(Icons.star_outline), findsNothing);
        // Icons.info_outline appears in TabBar, so check chip absence by count
        // TabBar has 1 info_outline icon (Details tab), chips should add 0 more
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });
    });

    group('секция статуса', () {
      testWidgets('должен отображать ItemStatusDropdown с MediaType.tvShow',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow();
        final CollectionItem item = createTestCollectionItem(
          tvShow: tvShow,
          status: ItemStatus.inProgress,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Status'), findsOneWidget);
        // Для tvShow inProgress отображается как "Watching"
        expect(find.text('Watching'), findsOneWidget);
      });

      testWidgets('должен отображать статус Not Started',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow();
        final CollectionItem item = createTestCollectionItem(
          tvShow: tvShow,
          status: ItemStatus.notStarted,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Not Started'), findsOneWidget);
      });
    });

    group('секция прогресса', () {
      testWidgets('должен отображать секцию Progress с полями Season и Episode',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(
          totalSeasons: 5,
          totalEpisodes: 62,
        );
        final CollectionItem item = createTestCollectionItem(
          tvShow: tvShow,
          currentSeason: 3,
          currentEpisode: 7,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Progress'), findsOneWidget);
        expect(find.text('Season'), findsOneWidget);
        expect(find.text('Episode'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.text('7'), findsOneWidget);
      });

      testWidgets('должен отображать total рядом с текущим значением',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(
          totalSeasons: 5,
          totalEpisodes: 62,
        );
        final CollectionItem item = createTestCollectionItem(
          tvShow: tvShow,
          currentSeason: 2,
          currentEpisode: 15,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('/5'), findsOneWidget);
        expect(find.text('/62'), findsOneWidget);
      });

      testWidgets('должен отображать текст прогресса S/E',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(
          totalSeasons: 5,
          totalEpisodes: 62,
        );
        final CollectionItem item = createTestCollectionItem(
          tvShow: tvShow,
          currentSeason: 3,
          currentEpisode: 7,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Формат: S3/5 • E7/62
        expect(find.textContaining('S3/5'), findsOneWidget);
        expect(find.textContaining('E7/62'), findsOneWidget);
      });

      testWidgets('должен иметь кнопки + и - для изменения прогресса',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(
          totalSeasons: 5,
          totalEpisodes: 62,
        );
        final CollectionItem item = createTestCollectionItem(
          tvShow: tvShow,
          currentSeason: 1,
          currentEpisode: 5,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // 2 кнопки - (для season и episode) и 2 кнопки + (для season и episode)
        expect(find.byIcon(Icons.remove), findsNWidgets(2));
        expect(find.byIcon(Icons.add), findsNWidgets(2));
      });

      testWidgets('не должен показывать total когда значение 0',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(
          totalSeasons: null,
          totalEpisodes: null,
        );
        final CollectionItem item = createTestCollectionItem(
          tvShow: tvShow,
          currentSeason: 2,
          currentEpisode: 10,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Не должно быть /0 в тексте
        expect(find.text('/0'), findsNothing);
      });
    });

    group('секция описания', () {
      testWidgets('должен отображать текст описания',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(
          overview: 'A chemistry teacher diagnosed with lung cancer.',
        );
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(
          find.text('A chemistry teacher diagnosed with lung cancer.'),
          findsOneWidget,
        );
      });

      testWidgets('не должен отображать описание когда overview null',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(overview: null);
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // overview текст не должен отображаться
        expect(find.textContaining('chemistry'), findsNothing);
      });

      testWidgets(
          'не должен отображать описание когда overview пустая строка',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(overview: '');
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // пустой overview не рендерится
        expect(find.textContaining('chemistry'), findsNothing);
      });
    });

    group('секция комментария автора', () {
      testWidgets('должен отображать комментарий автора',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow();
        final CollectionItem item = createTestCollectionItem(
          tvShow: tvShow,
          authorComment: 'Must watch!',
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text("Author's Comment"), findsOneWidget);
        expect(find.text('Must watch!'), findsOneWidget);
      });

      testWidgets(
          'должен показывать placeholder когда нет комментария автора (editable)',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow();
        final CollectionItem item = createTestCollectionItem(
          tvShow: tvShow,
          authorComment: null,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(
          find.text('No comment yet. Tap Edit to add one.'),
          findsOneWidget,
        );
      });

      testWidgets(
          'должен показывать сообщение для readonly когда нет комментария',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow();
        final CollectionItem item = createTestCollectionItem(
          tvShow: tvShow,
          authorComment: null,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: false,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(
          find.text('No comment from the author.'),
          findsOneWidget,
        );
      });

      testWidgets(
          'должен показывать кнопку Edit для комментария автора если editable',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow();
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // 2 кнопки Edit: Author's Comment и My Notes
        expect(find.text('Edit'), findsNWidgets(2));
      });

      testWidgets(
          'не должен показывать кнопку Edit для комментария автора если not editable',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow();
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: false,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Только 1 кнопка Edit: для My Notes
        expect(find.text('Edit'), findsOneWidget);
      });
    });

    group('секция личных заметок', () {
      testWidgets('должен отображать личные заметки',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow();
        final CollectionItem item = createTestCollectionItem(
          tvShow: tvShow,
          userComment: 'Finished season 3 on 2024-06-10',
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('My Notes'), findsOneWidget);
        expect(
          find.text('Finished season 3 on 2024-06-10'),
          findsOneWidget,
        );
      });

      testWidgets(
          'должен показывать placeholder когда нет личных заметок',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow();
        final CollectionItem item = createTestCollectionItem(
          tvShow: tvShow,
          userComment: null,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(
          find.text('No notes yet. Tap Edit to add your personal notes.'),
          findsOneWidget,
        );
      });
    });

    group('обработка отсутствующих данных', () {
      testWidgets('должен показывать TV Show not found для несуществующего ID',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 999,
          isEditable: true,
          items: <CollectionItem>[],
        ));
        await tester.pumpAndSettle();

        expect(find.text('TV Show not found'), findsOneWidget);
      });

      testWidgets(
          'должен корректно отображать элемент без данных TvShow',
          (WidgetTester tester) async {
        final CollectionItem item = createTestCollectionItem(tvShow: null);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Должен показать itemName как "Unknown TV Show"
        expect(find.text('Unknown TV Show'), findsWidgets);
        // Секции Status и Progress должны быть
        expect(find.text('Status'), findsOneWidget);
        expect(find.text('Progress'), findsOneWidget);
      });

      testWidgets(
          'должен отображать все чипы для полностью заполненного TvShow',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(
          title: 'Breaking Bad',
          firstAirYear: 2008,
          totalSeasons: 5,
          totalEpisodes: 62,
          genres: <String>['Drama', 'Crime'],
          rating: 8.9,
          status: 'Ended',
          overview: 'A chemistry teacher turns to cooking meth.',
        );
        final CollectionItem item = createTestCollectionItem(
          tvShow: tvShow,
          currentSeason: 5,
          currentEpisode: 62,
          status: ItemStatus.completed,
          authorComment: 'Best series ever',
          userComment: 'Rewatched twice',
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Все чипы
        expect(find.text('2008'), findsOneWidget);
        expect(find.text('5 seasons'), findsOneWidget);
        expect(find.text('62 ep'), findsOneWidget);
        expect(find.text('Drama, Crime'), findsOneWidget);
        expect(find.text('8.9/10'), findsOneWidget);
        expect(find.text('Ended'), findsOneWidget);

        // Description
        expect(
          find.text('A chemistry teacher turns to cooking meth.'),
          findsOneWidget,
        );

        // Status
        expect(find.text('Completed'), findsOneWidget);

        // Author's comment & user notes — скролл к нижней части
        // Указываем scrollable MediaDetailView (второй после TabBarView)
        await tester.scrollUntilVisible(
          find.text('Rewatched twice'),
          200,
          scrollable: find.byType(Scrollable).at(1),
        );
        await tester.pumpAndSettle();
        expect(find.text('Best series ever'), findsOneWidget);
        expect(find.text('Rewatched twice'), findsOneWidget);
      });
    });

    group('состояния загрузки и ошибки', () {
      testWidgets('должен показывать индикатор загрузки',
          (WidgetTester tester) async {
        // Используем Completer, который никогда не завершится,
        // чтобы увидеть loading state без утечки таймеров.
        final Completer<List<CollectionItem>> completer =
            Completer<List<CollectionItem>>();

        when(() => mockRepo.getItemsWithData(
              1,
              mediaType: any(named: 'mediaType'),
            )).thenAnswer((_) => completer.future);

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              collectionRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: const MaterialApp(
              home: TvShowDetailScreen(
                collectionId: 1,
                itemId: 1,
                isEditable: true,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Завершаем Completer, чтобы не было утечки ресурсов.
        completer.complete(<CollectionItem>[]);
        await tester.pumpAndSettle();
      });

      testWidgets('должен показывать ошибку при сбое загрузки',
          (WidgetTester tester) async {
        when(() => mockRepo.getItemsWithData(
              1,
              mediaType: any(named: 'mediaType'),
            )).thenAnswer((_) async => throw Exception('Network error'));

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              collectionRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: const MaterialApp(
              home: TvShowDetailScreen(
                collectionId: 1,
                itemId: 1,
                isEditable: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Error:'), findsOneWidget);
      });
    });

    group('диалоги редактирования', () {
      testWidgets(
          'должен открывать диалог редактирования комментария автора при нажатии Edit',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow();
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Прокручиваем до секции Author's Comment
        await tester.ensureVisible(find.text("Author's Comment"));
        await tester.pumpAndSettle();

        // Нажимаем первую кнопку Edit (для Author's Comment)
        await tester.tap(find.text('Edit').first);
        await tester.pumpAndSettle();

        expect(find.text("Edit Author's Comment"), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
      });

      testWidgets('должен закрывать диалог при нажатии Cancel',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow();
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Прокручиваем до секции Author's Comment
        await tester.ensureVisible(find.text("Author's Comment"));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Edit').first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text("Edit Author's Comment"), findsNothing);
      });

      testWidgets(
          'должен открывать диалог редактирования заметок при нажатии Edit для My Notes',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow();
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: false,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Прокручиваем до секции My Notes
        await tester.ensureVisible(find.text('My Notes'));
        await tester.pumpAndSettle();

        // isEditable=false значит есть только 1 кнопка Edit (для My Notes)
        await tester.tap(find.text('Edit').first);
        await tester.pumpAndSettle();

        expect(find.text('Edit My Notes'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
      });
    });

    group('SourceBadge', () {
      testWidgets('должен отображать SourceBadge TMDB',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow(title: 'Breaking Bad');
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byType(SourceBadge), findsOneWidget);
        expect(find.text('TMDB'), findsOneWidget);
      });
    });

    group('TabBar', () {
      testWidgets('должен отображать TabBar с двумя вкладками',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow();
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byType(TabBar), findsOneWidget);
        expect(find.byType(Tab), findsNWidgets(2));
      });

      testWidgets('должен отображать иконки вкладок',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow();
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // info_outline appears both in TabBar and as status chip icon,
        // so we check at least one exists for tab icon
        expect(find.byIcon(Icons.info_outline), findsWidgets);
        expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
      });

      testWidgets('должен начинать с вкладки Details',
          (WidgetTester tester) async {
        final TvShow tvShow = createTestTvShow();
        final CollectionItem item = createTestCollectionItem(tvShow: tvShow);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byType(MediaDetailView), findsOneWidget);
      });
    });
  });
}
