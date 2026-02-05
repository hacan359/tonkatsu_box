import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/widgets/platform_filter_sheet.dart';
import 'package:xerabora/shared/models/platform.dart';

void main() {
  // Тестовые данные
  const List<Platform> testPlatforms = <Platform>[
    Platform(id: 1, name: 'PlayStation 5', abbreviation: 'PS5'),
    Platform(id: 2, name: 'Xbox Series X', abbreviation: 'XSX'),
    Platform(id: 3, name: 'Nintendo Switch', abbreviation: 'Switch'),
    Platform(id: 4, name: 'PC (Microsoft Windows)'),
    Platform(id: 5, name: 'PlayStation 4', abbreviation: 'PS4'),
  ];

  Widget buildTestWidget({
    List<Platform> platforms = testPlatforms,
    List<int> selectedIds = const <int>[],
    void Function(List<int>)? onApply,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return ElevatedButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => PlatformFilterSheet(
                    platforms: platforms,
                    selectedIds: selectedIds,
                    onApply: onApply ?? (_) {},
                  ),
                );
              },
              child: const Text('Open Sheet'),
            );
          },
        ),
      ),
    );
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();
  }

  group('PlatformFilterSheet', () {
    group('рендеринг', () {
      testWidgets('должен показывать заголовок', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        expect(find.text('Select Platforms'), findsOneWidget);
      });

      testWidgets('должен показывать поле поиска', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Search platforms...'), findsOneWidget);
      });

      testWidgets('должен показывать список платформ', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        expect(find.text('PlayStation 5'), findsOneWidget);
        expect(find.text('Xbox Series X'), findsOneWidget);
        expect(find.text('Nintendo Switch'), findsOneWidget);
      });

      testWidgets('должен показывать abbreviation как subtitle', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        expect(find.text('PS5'), findsOneWidget);
        expect(find.text('XSX'), findsOneWidget);
      });

      testWidgets('должен не показывать subtitle для платформ без abbreviation', (WidgetTester tester) async {
        // Используем только платформу без abbreviation для теста
        const List<Platform> platformWithoutAbbr = <Platform>[
          Platform(id: 4, name: 'PC Windows'),
        ];

        await tester.pumpWidget(buildTestWidget(platforms: platformWithoutAbbr));
        await openSheet(tester);

        expect(find.text('PC Windows'), findsOneWidget);
        // Проверяем что subtitle отсутствует (нет Text с abbreviation)
        final Finder tile = find.byType(ListTile);
        expect(tile, findsOneWidget);

        final ListTile listTile = tester.widget<ListTile>(tile);
        expect(listTile.subtitle, isNull);
      });

      testWidgets('должен показывать кнопки Cancel и Apply', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Show All'), findsOneWidget);
      });

      testWidgets('должен показывать счётчик выбранных платформ', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        expect(find.text('0 selected'), findsOneWidget);
        expect(find.text('5 platforms'), findsOneWidget);
      });

      testWidgets('должен показывать количество выбранных на кнопке Apply', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(selectedIds: <int>[1, 2]));
        await openSheet(tester);

        expect(find.text('Apply (2)'), findsOneWidget);
      });
    });

    group('фильтрация по поиску', () {
      testWidgets('должен фильтровать по имени платформы', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        await tester.enterText(find.byType(TextField), 'play');
        await tester.pumpAndSettle();

        expect(find.text('PlayStation 5'), findsOneWidget);
        expect(find.text('PlayStation 4'), findsOneWidget);
        expect(find.text('Xbox Series X'), findsNothing);
        expect(find.text('Nintendo Switch'), findsNothing);
      });

      testWidgets('должен фильтровать по abbreviation', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        await tester.enterText(find.byType(TextField), 'ps5');
        await tester.pumpAndSettle();

        expect(find.text('PlayStation 5'), findsOneWidget);
        expect(find.text('PlayStation 4'), findsNothing);
      });

      testWidgets('должен быть case-insensitive', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        await tester.enterText(find.byType(TextField), 'XBOX');
        await tester.pumpAndSettle();

        expect(find.text('Xbox Series X'), findsOneWidget);
      });

      testWidgets('должен обновлять счётчик платформ при фильтрации', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        await tester.enterText(find.byType(TextField), 'play');
        await tester.pumpAndSettle();

        expect(find.text('2 platforms'), findsOneWidget);
      });

      testWidgets('должен показывать кнопку очистки поиска когда есть текст', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        // Изначально кнопки очистки нет
        expect(find.byIcon(Icons.clear), findsNothing);

        await tester.enterText(find.byType(TextField), 'test');
        await tester.pumpAndSettle();

        // Теперь кнопка очистки должна появиться
        expect(find.byIcon(Icons.clear), findsOneWidget);
      });

      testWidgets('должен очищать поиск при нажатии на кнопку очистки', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        await tester.enterText(find.byType(TextField), 'play');
        await tester.pumpAndSettle();

        expect(find.text('2 platforms'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();

        expect(find.text('5 platforms'), findsOneWidget);
      });
    });

    group('пустое состояние', () {
      testWidgets('должен показывать empty state когда нет результатов поиска', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        await tester.enterText(find.byType(TextField), 'nonexistent');
        await tester.pumpAndSettle();

        expect(find.text('No platforms found'), findsOneWidget);
        expect(find.text('Try a different search term'), findsOneWidget);
        expect(find.byIcon(Icons.search_off), findsOneWidget);
      });

      testWidgets('должен показывать empty state когда список платформ пуст', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(platforms: <Platform>[]));
        await openSheet(tester);

        expect(find.text('No platforms found'), findsOneWidget);
        expect(find.text('0 platforms'), findsOneWidget);
      });
    });

    group('выбор платформ', () {
      testWidgets('должен выбирать платформу при нажатии на checkbox', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        expect(find.text('0 selected'), findsOneWidget);

        await tester.tap(find.text('PlayStation 5'));
        await tester.pumpAndSettle();

        expect(find.text('1 selected'), findsOneWidget);
        expect(find.text('Apply (1)'), findsOneWidget);
      });

      testWidgets('должен снимать выбор при повторном нажатии', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(selectedIds: <int>[1]));
        await openSheet(tester);

        expect(find.text('1 selected'), findsOneWidget);

        await tester.tap(find.text('PlayStation 5'));
        await tester.pumpAndSettle();

        expect(find.text('0 selected'), findsOneWidget);
        expect(find.text('Show All'), findsOneWidget);
      });

      testWidgets('должен выбирать несколько платформ', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        await tester.tap(find.text('PlayStation 5'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Xbox Series X'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Nintendo Switch'));
        await tester.pumpAndSettle();

        expect(find.text('3 selected'), findsOneWidget);
        expect(find.text('Apply (3)'), findsOneWidget);
      });

      testWidgets('должен отображать предвыбранные платформы', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(selectedIds: <int>[1, 3]));
        await openSheet(tester);

        expect(find.text('2 selected'), findsOneWidget);

        // Проверяем что чекбоксы отмечены
        // Находим ListTile для каждой платформы и проверяем trailing Checkbox
        final List<Checkbox> checkboxWidgets = tester.widgetList<Checkbox>(
          find.byType(Checkbox),
        ).toList();

        // Порядок: PS5 (id:1), Xbox (id:2), Switch (id:3)
        // PS5 (index 0) - выбран
        expect(checkboxWidgets[0].value, isTrue);
        // Xbox (index 1) - не выбран
        expect(checkboxWidgets[1].value, isFalse);
        // Switch (index 2) - выбран
        expect(checkboxWidgets[2].value, isTrue);
      });
    });

    group('Clear All', () {
      testWidgets('должен показывать кнопку Clear All когда есть выбранные', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(selectedIds: <int>[1]));
        await openSheet(tester);

        expect(find.text('Clear All'), findsOneWidget);
      });

      testWidgets('должен скрывать кнопку Clear All когда нет выбранных', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        expect(find.text('Clear All'), findsNothing);
      });

      testWidgets('должен очищать все выбранные при нажатии Clear All', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(selectedIds: <int>[1, 2, 3]));
        await openSheet(tester);

        expect(find.text('3 selected'), findsOneWidget);

        await tester.tap(find.text('Clear All'));
        await tester.pumpAndSettle();

        expect(find.text('0 selected'), findsOneWidget);
        expect(find.text('Clear All'), findsNothing);
        expect(find.text('Show All'), findsOneWidget);
      });
    });

    group('Apply', () {
      testWidgets('должен вызывать onApply с выбранными ID', (WidgetTester tester) async {
        List<int>? appliedIds;

        await tester.pumpWidget(buildTestWidget(
          onApply: (List<int> ids) {
            appliedIds = ids;
          },
        ));
        await openSheet(tester);

        await tester.tap(find.text('PlayStation 5'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Nintendo Switch'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Apply (2)'));
        await tester.pumpAndSettle();

        expect(appliedIds, isNotNull);
        expect(appliedIds, containsAll(<int>[1, 3]));
        expect(appliedIds!.length, 2);
      });

      testWidgets('должен вызывать onApply с пустым списком когда ничего не выбрано', (WidgetTester tester) async {
        List<int>? appliedIds;

        await tester.pumpWidget(buildTestWidget(
          onApply: (List<int> ids) {
            appliedIds = ids;
          },
        ));
        await openSheet(tester);

        await tester.tap(find.text('Show All'));
        await tester.pumpAndSettle();

        expect(appliedIds, isNotNull);
        expect(appliedIds, isEmpty);
      });

      testWidgets('должен сохранять изменения после Apply', (WidgetTester tester) async {
        List<int>? appliedIds;

        await tester.pumpWidget(buildTestWidget(
          selectedIds: <int>[1],
          onApply: (List<int> ids) {
            appliedIds = ids;
          },
        ));
        await openSheet(tester);

        // Снимаем выбор с PS5 и добавляем Xbox
        await tester.tap(find.text('PlayStation 5'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Xbox Series X'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Apply (1)'));
        await tester.pumpAndSettle();

        expect(appliedIds, <int>[2]); // Только Xbox
      });
    });

    group('Cancel', () {
      testWidgets('должен закрывать sheet при нажатии Cancel', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        expect(find.text('Select Platforms'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('Select Platforms'), findsNothing);
      });

      testWidgets('должен не вызывать onApply при Cancel', (WidgetTester tester) async {
        bool onApplyCalled = false;

        await tester.pumpWidget(buildTestWidget(
          onApply: (_) {
            onApplyCalled = true;
          },
        ));
        await openSheet(tester);

        await tester.tap(find.text('PlayStation 5'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(onApplyCalled, isFalse);
      });
    });

    group('edge cases', () {
      testWidgets('должен работать с одной платформой', (WidgetTester tester) async {
        const List<Platform> singlePlatform = <Platform>[
          Platform(id: 1, name: 'Test Platform'),
        ];

        await tester.pumpWidget(buildTestWidget(platforms: singlePlatform));
        await openSheet(tester);

        expect(find.text('Test Platform'), findsOneWidget);
        expect(find.text('1 platforms'), findsOneWidget);
      });

      testWidgets('должен работать с платформами без abbreviation при поиске', (WidgetTester tester) async {
        const List<Platform> noAbbr = <Platform>[
          Platform(id: 1, name: 'Platform Without Abbr'),
        ];

        await tester.pumpWidget(buildTestWidget(platforms: noAbbr));
        await openSheet(tester);

        // Поиск по имени работает
        await tester.enterText(find.byType(TextField), 'platform');
        await tester.pumpAndSettle();

        expect(find.text('Platform Without Abbr'), findsOneWidget);
        expect(find.text('1 platforms'), findsOneWidget);

        // Поиск по несуществующему тексту показывает empty state
        await tester.enterText(find.byType(TextField), 'nonexistent');
        await tester.pumpAndSettle();

        expect(find.text('No platforms found'), findsOneWidget);
      });

      testWidgets('должен сохранять выбор при фильтрации', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        // Выбираем PS5 и Xbox
        await tester.tap(find.text('PlayStation 5'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Xbox Series X'));
        await tester.pumpAndSettle();

        expect(find.text('2 selected'), findsOneWidget);

        // Фильтруем только по PlayStation
        await tester.enterText(find.byType(TextField), 'play');
        await tester.pumpAndSettle();

        // Выбор должен сохраниться
        expect(find.text('2 selected'), findsOneWidget);

        // Очищаем фильтр
        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();

        // Оба всё ещё выбраны
        expect(find.text('2 selected'), findsOneWidget);
      });

      testWidgets('должен работать с несуществующими selectedIds', (WidgetTester tester) async {
        // Передаём ID которых нет в списке платформ
        await tester.pumpWidget(buildTestWidget(selectedIds: <int>[999, 1000]));
        await openSheet(tester);

        // Должен показать счётчик, хотя платформ с такими ID нет
        expect(find.text('2 selected'), findsOneWidget);
      });
    });
  });
}
