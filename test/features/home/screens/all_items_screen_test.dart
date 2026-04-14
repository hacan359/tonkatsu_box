// Тесты для AllItemsScreen — экран всех элементов (Home tab).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/features/home/screens/all_items_screen.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/features/settings/providers/profile_provider.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/shared/models/profile.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/platform.dart' as model;
import 'package:xerabora/shared/models/visual_novel.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockCollectionRepository mockRepo;
  late MockDatabaseService mockDb;
  late SharedPreferences prefs;

  final List<CollectionItem> testItems = <CollectionItem>[
    CollectionItem(
      id: 1,
      collectionId: 10,
      mediaType: MediaType.game,
      externalId: 100,
      platformId: 19,
      sortOrder: 0,
      status: ItemStatus.completed,
      addedAt: DateTime(2025, 1, 1),
      platform: const model.Platform(
        id: 19,
        name: 'Super Nintendo',
        abbreviation: 'SNES',
      ),
    ),
    CollectionItem(
      id: 2,
      collectionId: 10,
      mediaType: MediaType.movie,
      externalId: 200,
      sortOrder: 1,
      status: ItemStatus.inProgress,
      addedAt: DateTime(2025, 2, 1),
    ),
    CollectionItem(
      id: 3,
      collectionId: 20,
      mediaType: MediaType.tvShow,
      externalId: 300,
      sortOrder: 0,
      status: ItemStatus.notStarted,
      addedAt: DateTime(2025, 3, 1),
    ),
    CollectionItem(
      id: 4,
      collectionId: 10,
      mediaType: MediaType.game,
      externalId: 100,
      platformId: 24,
      sortOrder: 2,
      status: ItemStatus.notStarted,
      addedAt: DateTime(2025, 4, 1),
      platform: const model.Platform(
        id: 24,
        name: 'Game Boy Advance',
        abbreviation: 'GBA',
      ),
    ),
    CollectionItem(
      id: 5,
      collectionId: 20,
      mediaType: MediaType.visualNovel,
      externalId: 500,
      sortOrder: 1,
      status: ItemStatus.notStarted,
      addedAt: DateTime(2025, 5, 1),
      visualNovel: const VisualNovel(id: 'v500', title: 'Steins;Gate'),
    ),
  ];

  final List<Collection> testCollections = <Collection>[
    Collection(
      id: 10,
      name: 'My Games',
      author: 'User',
      type: CollectionType.own,
      createdAt: DateTime(2025),
    ),
    Collection(
      id: 20,
      name: 'Watch List',
      author: 'User',
      type: CollectionType.own,
      createdAt: DateTime(2025),
    ),
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'home_status_filter_test': 'all',
    });
    prefs = await SharedPreferences.getInstance();

    mockRepo = MockCollectionRepository();
    when(() => mockRepo.getAllItemsWithData(mediaType: any(named: 'mediaType')))
        .thenAnswer((_) async => testItems);
    when(() => mockRepo.getAll())
        .thenAnswer((_) async => testCollections);
    when(() => mockRepo.getStats(any()))
        .thenAnswer((_) async => CollectionStats.empty);

    mockDb = MockDatabaseService();
    when(() => mockDb.database).thenAnswer((_) async => MockDatabase());
    when(() => mockDb.getPlatformById(19)).thenAnswer(
      (_) async => const model.Platform(
        id: 19,
        name: 'Super Nintendo',
        abbreviation: 'SNES',
      ),
    );
    when(() => mockDb.getPlatformById(24)).thenAnswer(
      (_) async => const model.Platform(
        id: 24,
        name: 'Game Boy Advance',
        abbreviation: 'GBA',
      ),
    );
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: <Override>[
        collectionRepositoryProvider.overrideWithValue(mockRepo),
        databaseServiceProvider.overrideWithValue(mockDb),
        sharedPreferencesProvider.overrideWithValue(prefs),
        settingsNotifierProvider.overrideWith(
          () => _FakeSettingsNotifier(),
        ),
        currentProfileProvider.overrideWithValue(Profile(
          id: 'test',
          name: 'Test',
          color: '#FF0000',
          createdAt: DateTime(2025),
        )),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: AllItemsScreen()),
      ),
    );
  }

  group('AllItemsScreen', () {
    testWidgets('показывает сегменты типов медиа',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Бар multi-select — «All» сегмента нет (пустое состояние = все).
      expect(find.text('Games'), findsOneWidget);
      expect(find.text('Movies'), findsOneWidget);
      expect(find.text('TV Shows'), findsOneWidget);
      expect(find.text('Animation'), findsOneWidget);
      expect(find.text('Visual Novels'), findsOneWidget);
    });

    testWidgets('показывает счётчики на сегментах после загрузки',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 5 элементов: 2 games, 1 movie, 1 tvShow, 1 visualNovel
      expect(find.text('Games (2)'), findsOneWidget);
      expect(find.text('Movies (1)'), findsOneWidget);
      expect(find.text('TV Shows (1)'), findsOneWidget);
      expect(find.text('Visual Novels (1)'), findsOneWidget);
      // Animation = 0 → без счётчика, просто label
      expect(find.text('Animation'), findsOneWidget);
    });

    testWidgets('показывает chevron-dropdown статуса с текстом "All"',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Последний chevron-сегмент — dropdown статуса, по умолчанию "All"
      expect(find.text('All'), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsNothing);
    });

    testWidgets('dropdown статуса открывает popup и фильтрует',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Тап по "All" открывает popup
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Popup содержит опции статусов
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);

      // Выбираем Completed — только 1 элемент (item 1, game)
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.text('My Games (1)'), findsOneWidget);
      expect(find.textContaining('Watch List'), findsNothing);
    });

    testWidgets('выбор "All" в dropdown сбрасывает фильтр статуса',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Фильтруем по Completed
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Watch List'), findsNothing);

      // Сегмент теперь показывает "Completed" — тап открывает popup
      await tester.tap(find.text('Completed').first);
      await tester.pumpAndSettle();

      // Выбираем All — сбрасываем фильтр
      await tester.tap(find.text('All').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Watch List'), findsOneWidget);
    });

    testWidgets('показывает loading state при запуске',
        (WidgetTester tester) async {
      final Completer<List<CollectionItem>> completer =
          Completer<List<CollectionItem>>();
      when(() =>
              mockRepo.getAllItemsWithData(mediaType: any(named: 'mediaType')))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Завершаем Future чтобы не оставлять pending timer
      completer.complete(testItems);
      await tester.pumpAndSettle();
    });

    testWidgets('показывает empty state когда нет элементов',
        (WidgetTester tester) async {
      when(() =>
              mockRepo.getAllItemsWithData(mediaType: any(named: 'mediaType')))
          .thenAnswer((_) async => <CollectionItem>[]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No items yet'), findsOneWidget);
    });

    testWidgets('показывает grid после загрузки данных',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Элементы должны отображаться (CustomScrollView со slivers)
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('показывает разделители коллекций',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Разделители с названиями коллекций и количеством
      // My Games: 3 элемента (id 1,2,4 — collectionId = 10)
      // Watch List: 2 элемента (id 3,5 — collectionId = 20)
      expect(find.text('My Games (3)'), findsOneWidget);
      expect(find.text('Watch List (2)'), findsOneWidget);
    });

    testWidgets('разделители обновляются при фильтрации',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Фильтруем по Games — только коллекция My Games (2 игры)
      await tester.tap(find.text('Games (2)'));
      await tester.pumpAndSettle();

      // My Games с 2 играми, Watch List пуст (нет игр) — не показывается
      expect(find.text('My Games (2)'), findsOneWidget);
      expect(find.textContaining('Watch List'), findsNothing);
    });
  });

  group('AllItemsScreen фильтрация', () {
    testWidgets('нажатие на Games фильтрует по типу',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Нажимаем на чипс Games (2 игры в testItems)
      await tester.tap(find.text('Games (2)'));
      await tester.pumpAndSettle();

      // Чипс Games выбран — фильтрация применяется на уровне UI
      // Проверяем что CustomScrollView всё ещё есть (с меньшим количеством элементов)
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('повторное нажатие на Games сбрасывает фильтр',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Выбираем Games — отфильтрованы только игры
      await tester.tap(find.text('Games (2)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Watch List'), findsNothing);

      // Повторный тап по Games отменяет выбор — снова все коллекции
      await tester.tap(find.text('Games (2)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Watch List'), findsOneWidget);
    });

    testWidgets('можно выбрать несколько типов одновременно',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Выбираем Games — Watch List пропадает
      await tester.tap(find.text('Games (2)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Watch List'), findsNothing);

      // Добавляем TV Shows — Watch List появляется снова (tvShow лежит в ней)
      await tester.tap(find.text('TV Shows (1)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Watch List'), findsOneWidget);
      expect(find.textContaining('My Games'), findsOneWidget);
    });
  });

  group('AllItemsScreen платформенный фильтр', () {
    testWidgets('при выборе Games показывает мини-чипы платформ',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Нажимаем Games — появляется полоска мини-чипов платформ.
      await tester.tap(find.text('Games (2)'));
      await tester.pumpAndSettle();

      expect(find.text('SNES'), findsOneWidget);
      expect(find.text('GBA'), findsOneWidget);
    });

    testWidgets('при выборе Movies не показывает чипы платформ',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Movies (1)'));
      await tester.pumpAndSettle();

      expect(find.text('SNES'), findsNothing);
      expect(find.text('GBA'), findsNothing);
    });

    testWidgets('отмена выбора Games убирает чипы платформ',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Games (2)'));
      await tester.pumpAndSettle();
      expect(find.text('SNES'), findsOneWidget);

      // Повторный тап по Games отменяет выбор → чипы уходят.
      await tester.tap(find.text('Games (2)'));
      await tester.pumpAndSettle();
      expect(find.text('SNES'), findsNothing);
    });

    testWidgets('тап по мини-чипу платформы фильтрует элементы',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Фильтруем по Games
      await tester.tap(find.text('Games (2)'));
      await tester.pumpAndSettle();

      // Тап по SNES — фильтр по платформе
      await tester.tap(find.text('SNES'));
      await tester.pumpAndSettle();

      expect(find.byType(CustomScrollView), findsOneWidget);
    });
  });

  group('AllItemsScreen Visual Novel фильтр', () {
    testWidgets('нажатие на Visual Novels фильтрует по типу',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // VN чипс может быть за пределами экрана — прокручиваем
      final Finder vnChip = find.text('Visual Novels (1)');
      await tester.ensureVisible(vnChip);
      await tester.pumpAndSettle();

      await tester.tap(vnChip);
      await tester.pumpAndSettle();

      expect(find.byType(CustomScrollView), findsOneWidget);
      // Watch List видна (VN в collectionId 20)
      expect(find.textContaining('Watch List'), findsOneWidget);
      // My Games не видна (нет VN в collectionId 10)
      expect(find.textContaining('My Games'), findsNothing);
    });

    testWidgets('при выборе Visual Novels не показывает чипсы платформ',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final Finder vnChip = find.text('Visual Novels (1)');
      await tester.ensureVisible(vnChip);
      await tester.pumpAndSettle();

      await tester.tap(vnChip);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ChoiceChip, 'SNES'), findsNothing);
      expect(find.widgetWithText(ChoiceChip, 'GBA'), findsNothing);
    });
  });
}

class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() => const SettingsState();
}
