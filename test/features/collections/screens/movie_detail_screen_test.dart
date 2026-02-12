// Тесты виджета MovieDetailScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/features/collections/screens/movie_detail_screen.dart';
import 'package:xerabora/features/collections/widgets/item_status_dropdown.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/widgets/media_detail_view.dart';
import 'package:xerabora/shared/widgets/source_badge.dart';

// Mock-нотифайер для подмены collectionItemsNotifierProvider в тестах.
class MockCollectionItemsNotifier extends CollectionItemsNotifier {
  MockCollectionItemsNotifier(this._initialState);

  final AsyncValue<List<CollectionItem>> _initialState;

  @override
  AsyncValue<List<CollectionItem>> build(int arg) {
    return _initialState;
  }
}

void main() {
  final DateTime testDate = DateTime(2024, 1, 15, 12, 0, 0);

  // -- Фабрика для создания тестовых CollectionItem --

  CollectionItem createTestItem({
    int id = 1,
    int collectionId = 1,
    int externalId = 550,
    ItemStatus status = ItemStatus.notStarted,
    String? authorComment,
    String? userComment,
    Movie? movie,
  }) {
    return CollectionItem(
      id: id,
      collectionId: collectionId,
      mediaType: MediaType.movie,
      externalId: externalId,
      status: status,
      addedAt: testDate,
      authorComment: authorComment,
      userComment: userComment,
      movie: movie,
    );
  }

  // -- Фабрика для создания тестовых Movie --

  Movie createTestMovie({
    int tmdbId = 550,
    String title = 'Test Movie',
    String? overview,
    String? posterUrl,
    String? backdropUrl,
    List<String>? genres,
    int? releaseYear,
    double? rating,
    int? runtime,
  }) {
    return Movie(
      tmdbId: tmdbId,
      title: title,
      overview: overview,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      genres: genres,
      releaseYear: releaseYear,
      rating: rating,
      runtime: runtime,
    );
  }

  // -- Хелпер для создания тестового виджета --

  Widget createTestWidget({
    required int collectionId,
    required int itemId,
    required bool isEditable,
    required List<CollectionItem> items,
  }) {
    final AsyncValue<List<CollectionItem>> initialState =
        AsyncData<List<CollectionItem>>(items);

    return ProviderScope(
      overrides: <Override>[
        collectionItemsNotifierProvider.overrideWith(
          () => MockCollectionItemsNotifier(initialState),
        ),
      ],
      child: MaterialApp(
        home: MovieDetailScreen(
          collectionId: collectionId,
          itemId: itemId,
          isEditable: isEditable,
        ),
      ),
    );
  }

  group('MovieDetailScreen', () {
    group('Заголовок и AppBar', () {
      testWidgets('должен отображать название фильма в AppBar',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(title: 'Inception');
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Inception'), findsWidgets);
      });

      testWidgets('должен показывать "Movie not found" для несуществующего ID',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 999,
          isEditable: true,
          items: <CollectionItem>[],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Movie not found'), findsOneWidget);
      });

      testWidgets(
          'должен отображать "Movie" как тип медиа',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Movie'), findsOneWidget);
      });
    });

    group('Постер / бэкдроп', () {
      testWidgets(
          'должен показывать placeholder иконку когда нет posterUrl и backdropUrl',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(
          posterUrl: null,
          backdropUrl: null,
        );
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Placeholder использует Icons.movie_outlined
        // Один в AppBar placeholder, один в info row
        expect(find.byIcon(Icons.movie_outlined), findsWidgets);
      });

      testWidgets(
          'должен показывать placeholder когда movie == null',
          (WidgetTester tester) async {
        final CollectionItem item = createTestItem(movie: null);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.movie_outlined), findsWidgets);
      });
    });

    group('Info chips', () {
      testWidgets('должен отображать год выпуска когда releaseYear задан',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(releaseYear: 2010);
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('2010'), findsOneWidget);
        expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      });

      testWidgets(
          'не должен отображать чип года когда releaseYear == null',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(releaseYear: null);
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.calendar_today_outlined), findsNothing);
      });

      testWidgets(
          'должен отображать runtime в формате "Xh Ym" для часов и минут',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(runtime: 148);
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('2h 28m'), findsOneWidget);
        expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
      });

      testWidgets(
          'должен отображать runtime в формате "Xh" когда минут ровно 0',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(runtime: 120);
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('2h'), findsOneWidget);
      });

      testWidgets(
          'должен отображать runtime в формате "Ym" когда меньше часа',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(runtime: 45);
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('45m'), findsOneWidget);
      });

      testWidgets(
          'не должен отображать чип runtime когда runtime == null',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(runtime: null);
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.schedule_outlined), findsNothing);
      });

      testWidgets('должен отображать жанры через запятую',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(
          genres: <String>['Action', 'Sci-Fi', 'Thriller'],
        );
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Action, Sci-Fi, Thriller'), findsOneWidget);
        expect(find.byIcon(Icons.category_outlined), findsOneWidget);
      });

      testWidgets(
          'не должен отображать чип жанров когда genres == null',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(genres: null);
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.category_outlined), findsNothing);
      });

      testWidgets('должен отображать рейтинг в формате "X.X/10"',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(rating: 8.4);
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('8.4/10'), findsOneWidget);
        expect(find.byIcon(Icons.star_outline), findsOneWidget);
      });

      testWidgets(
          'не должен отображать чип рейтинга когда rating == null',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(rating: null);
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.star_outline), findsNothing);
      });
    });

    group('Описание (overview)', () {
      testWidgets('должен отображать описание фильма',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(
          overview: 'A thief who steals corporate secrets through dreams.',
        );
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(
          find.text('A thief who steals corporate secrets through dreams.'),
          findsOneWidget,
        );
      });

      testWidgets(
          'не должен отображать описание когда overview == null',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(overview: null);
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // overview текст не должен отображаться
        expect(find.textContaining('thief'), findsNothing);
      });

      testWidgets(
          'не должен отображать описание когда overview пуст',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(overview: '');
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // пустой overview не рендерится
        expect(find.textContaining('thief'), findsNothing);
      });
    });

    group('Статус (ItemStatusDropdown)', () {
      testWidgets('должен отображать секцию статуса с заголовком',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Status'), findsOneWidget);
      });

      testWidgets('должен содержать ItemStatusDropdown виджет',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byType(ItemStatusDropdown), findsOneWidget);
      });

      testWidgets(
          'ItemStatusDropdown должен использовать MediaType.movie',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
          status: ItemStatus.notStarted,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        final ItemStatusDropdown dropdown = tester.widget<ItemStatusDropdown>(
          find.byType(ItemStatusDropdown),
        );
        expect(dropdown.mediaType, MediaType.movie);
        expect(dropdown.status, ItemStatus.notStarted);
      });

      testWidgets(
          'должен показывать "Not Started" для статуса notStarted',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
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

      testWidgets(
          'должен показывать "Watching" для статуса inProgress (не "Playing")',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
          status: ItemStatus.inProgress,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Для movie.inProgress отображается "Watching", а не "Playing"
        expect(find.text('Watching'), findsOneWidget);
        expect(find.text('Playing'), findsNothing);
      });
    });

    group('Комментарий автора', () {
      testWidgets('должен отображать комментарий автора',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
          authorComment: 'Must watch masterpiece!',
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.text("Author's Comment"), findsOneWidget);
        expect(find.text('Must watch masterpiece!'), findsOneWidget);
      });

      testWidgets(
          'должен показывать placeholder когда нет комментария автора (editable)',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
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
          'должен показывать readonly сообщение когда нет комментария автора (не editable)',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
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
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Скролл вниз мимо ActivityDatesSection
        await tester.drag(find.byType(Scrollable).at(1), const Offset(0, -300));
        await tester.pumpAndSettle();

        // 2 кнопки Edit: для Author's Comment и My Notes
        expect(find.text('Edit'), findsNWidgets(2));
      });

      testWidgets(
          'не должен показывать кнопку Edit для комментария автора если не editable',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: false,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Скролл вниз мимо ActivityDatesSection
        await tester.drag(find.byType(Scrollable).at(1), const Offset(0, -300));
        await tester.pumpAndSettle();

        // Только 1 кнопка Edit: для My Notes
        expect(find.text('Edit'), findsOneWidget);
      });
    });

    group('Личные заметки', () {
      testWidgets('должен отображать личные заметки',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
          userComment: 'Watched on 2024-01-15',
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Скролл вниз мимо ActivityDatesSection
        await tester.drag(find.byType(Scrollable).at(1), const Offset(0, -300));
        await tester.pumpAndSettle();

        expect(find.text('My Notes'), findsOneWidget);
        expect(find.text('Watched on 2024-01-15'), findsOneWidget);
      });

      testWidgets(
          'должен показывать placeholder когда нет личных заметок',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(
          movie: movie,
          userComment: null,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Скролл вниз мимо ActivityDatesSection
        await tester.drag(find.byType(Scrollable).at(1), const Offset(0, -300));
        await tester.pumpAndSettle();

        expect(
          find.text('No notes yet. Tap Edit to add your personal notes.'),
          findsOneWidget,
        );
      });
    });

    group('Диалог редактирования', () {
      testWidgets(
          'должен открывать диалог редактирования комментария автора',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Нажимаем первую кнопку Edit (Author's Comment)
        await tester.tap(find.text('Edit').first);
        await tester.pumpAndSettle();

        expect(find.text("Edit Author's Comment"), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
      });

      testWidgets(
          'должен закрывать диалог при нажатии Cancel',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Edit').first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text("Edit Author's Comment"), findsNothing);
      });

      testWidgets(
          'должен открывать диалог редактирования личных заметок',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Прокручиваем до секции My Notes, чтобы кнопка Edit была видна
        final Finder myNotesEdit = find.text('Edit').last;
        await tester.scrollUntilVisible(
          myNotesEdit,
          200,
          scrollable: find.byType(Scrollable).at(1),
        );
        await tester.pumpAndSettle();

        // Нажимаем последнюю кнопку Edit (My Notes)
        await tester.tap(myNotesEdit);
        await tester.pumpAndSettle();

        expect(find.text('Edit My Notes'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
      });
    });

    group('Состояния загрузки и ошибок', () {
      testWidgets('должен показывать индикатор загрузки в состоянии loading',
          (WidgetTester tester) async {
        final Widget widget = ProviderScope(
          overrides: <Override>[
            collectionItemsNotifierProvider.overrideWith(
              () => MockCollectionItemsNotifier(
                const AsyncLoading<List<CollectionItem>>(),
              ),
            ),
          ],
          child: const MaterialApp(
            home: MovieDetailScreen(
              collectionId: 1,
              itemId: 1,
              isEditable: true,
            ),
          ),
        );

        await tester.pumpWidget(widget);
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('должен показывать ошибку в состоянии error',
          (WidgetTester tester) async {
        final Widget widget = ProviderScope(
          overrides: <Override>[
            collectionItemsNotifierProvider.overrideWith(
              () => MockCollectionItemsNotifier(
                AsyncError<List<CollectionItem>>(
                  'Connection failed',
                  StackTrace.current,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: MovieDetailScreen(
              collectionId: 1,
              itemId: 1,
              isEditable: true,
            ),
          ),
        );

        await tester.pumpWidget(widget);
        await tester.pump();

        expect(find.textContaining('Error:'), findsOneWidget);
        expect(find.textContaining('Connection failed'), findsOneWidget);
      });
    });

    group('Обработка пустых/отсутствующих опциональных полей', () {
      testWidgets(
          'должен корректно рендериться со всеми null-полями у Movie',
          (WidgetTester tester) async {
        const Movie movie = Movie(
          tmdbId: 1,
          title: 'Minimal Movie',
        );
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Название отображается
        expect(find.text('Minimal Movie'), findsWidgets);

        // Ни одного info-чипа (год, runtime, жанры, рейтинг)
        expect(find.byIcon(Icons.calendar_today_outlined), findsNothing);
        expect(find.byIcon(Icons.schedule_outlined), findsNothing);
        expect(find.byIcon(Icons.category_outlined), findsNothing);
        expect(find.byIcon(Icons.star_outline), findsNothing);

        // Нет описания
        expect(find.text('Description'), findsNothing);

        // Секция Status всё ещё отображается
        expect(find.text('Status'), findsOneWidget);

        // Скролл вниз мимо ActivityDatesSection
        await tester.drag(find.byType(Scrollable).at(1), const Offset(0, -300));
        await tester.pumpAndSettle();

        // Секции комментариев отображаются
        expect(find.text("Author's Comment"), findsOneWidget);
        expect(find.text('My Notes'), findsOneWidget);
      });

      testWidgets(
          'должен корректно рендериться со всеми заполненными полями',
          (WidgetTester tester) async {
        // Не указываем posterUrl/backdropUrl, чтобы CachedNetworkImage
        // не вызывал HTTP-запрос и pumpAndSettle не зависал.
        final Movie movie = createTestMovie(
          title: 'Full Movie',
          overview: 'A detailed plot description.',
          genres: <String>['Drama', 'Comedy'],
          releaseYear: 2023,
          rating: 7.5,
          runtime: 95,
        );
        final CollectionItem item = createTestItem(
          movie: movie,
          authorComment: 'Great comedy-drama!',
          userComment: 'Enjoyed it a lot.',
          status: ItemStatus.completed,
        );

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // Название
        expect(find.text('Full Movie'), findsWidgets);

        // Info chips
        expect(find.text('2023'), findsOneWidget);
        expect(find.text('1h 35m'), findsOneWidget);
        expect(find.text('Drama, Comedy'), findsOneWidget);
        expect(find.text('7.5/10'), findsOneWidget);

        // Описание
        expect(
          find.text('A detailed plot description.'),
          findsOneWidget,
        );

        // Скролл вниз мимо ActivityDatesSection
        await tester.drag(find.byType(Scrollable).at(1), const Offset(0, -300));
        await tester.pumpAndSettle();

        // Комментарий автора
        expect(find.text('Great comedy-drama!'), findsOneWidget);

        // Личные заметки
        expect(find.text('Enjoyed it a lot.'), findsOneWidget);

        // Статус (может быть 2: один в dropdown, один в ActivityDatesSection)
        expect(find.text('Completed'), findsWidgets);
      });

      testWidgets(
          'должен показывать "Unknown Movie" когда movie == null в CollectionItem',
          (WidgetTester tester) async {
        final CollectionItem item = createTestItem(movie: null);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        // itemName для movie == null возвращает 'Unknown Movie'
        expect(find.text('Unknown Movie'), findsWidgets);
      });
    });

    group('SourceBadge', () {
      testWidgets('должен отображать SourceBadge TMDB',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie(title: 'Test Movie');
        final CollectionItem item = createTestItem(movie: movie);

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
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(movie: movie);

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
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(movie: movie);

        await tester.pumpWidget(createTestWidget(
          collectionId: 1,
          itemId: 1,
          isEditable: true,
          items: <CollectionItem>[item],
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.info_outline), findsOneWidget);
        expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
      });

      testWidgets('должен начинать с вкладки Details',
          (WidgetTester tester) async {
        final Movie movie = createTestMovie();
        final CollectionItem item = createTestItem(movie: movie);

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
