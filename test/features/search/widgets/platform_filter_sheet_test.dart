import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/widgets/platform_filter_sheet.dart';
import 'package:xerabora/l10n/app_localizations.dart';
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
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
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
      testWidgets('должен показывать поле поиска', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('должен показывать список платформ как ListTile',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        expect(find.byType(ListTile), findsNWidgets(5));
      });

      testWidgets('должен показывать количество выбранных на кнопке Apply',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(selectedIds: <int>[1, 2]));
        await openSheet(tester);

        expect(find.byType(FilledButton), findsOneWidget);
      });
    });

    group('фильтрация по поиску', () {
      testWidgets('должен фильтровать по имени платформы',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        await tester.enterText(find.byType(TextField), 'play');
        await tester.pumpAndSettle();

        // 2 из 5 платформ содержат "play"
        expect(find.byType(ListTile), findsNWidgets(2));
      });

      testWidgets('должен фильтровать по abbreviation',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        await tester.enterText(find.byType(TextField), 'ps5');
        await tester.pumpAndSettle();

        expect(find.byType(ListTile), findsNWidgets(1));
      });

      testWidgets('должен быть case-insensitive',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        await tester.enterText(find.byType(TextField), 'XBOX');
        await tester.pumpAndSettle();

        expect(find.byType(ListTile), findsNWidgets(1));
      });

      testWidgets('должен показывать кнопку очистки когда есть текст',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        expect(find.byIcon(Icons.clear), findsNothing);

        await tester.enterText(find.byType(TextField), 'test');
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.clear), findsOneWidget);
      });

      testWidgets('должен очищать поиск при нажатии кнопки очистки',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        await tester.enterText(find.byType(TextField), 'play');
        await tester.pumpAndSettle();

        expect(find.byType(ListTile), findsNWidgets(2));

        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();

        expect(find.byType(ListTile), findsNWidgets(5));
      });
    });

    group('пустое состояние', () {
      testWidgets('должен показывать empty state когда нет результатов',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        await tester.enterText(find.byType(TextField), 'nonexistent');
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.search_off), findsOneWidget);
        expect(find.byType(ListTile), findsNothing);
      });

      testWidgets('должен показывать empty state когда список пуст',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(platforms: <Platform>[]));
        await openSheet(tester);

        expect(find.byType(ListTile), findsNothing);
      });
    });

    group('выбор платформ', () {
      testWidgets('должен выбирать платформу при нажатии на ListTile',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        final List<Checkbox> before = tester
            .widgetList<Checkbox>(find.byType(Checkbox))
            .toList();
        expect(before.where((Checkbox c) => c.value == true).length, 0);

        await tester.tap(find.byType(ListTile).first);
        await tester.pumpAndSettle();

        final List<Checkbox> after = tester
            .widgetList<Checkbox>(find.byType(Checkbox))
            .toList();
        expect(after.where((Checkbox c) => c.value == true).length, 1);
      });

      testWidgets('должен снимать выбор при повторном нажатии',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(selectedIds: <int>[1]));
        await openSheet(tester);

        final List<Checkbox> before = tester
            .widgetList<Checkbox>(find.byType(Checkbox))
            .toList();
        expect(before[0].value, isTrue);

        await tester.tap(find.byType(ListTile).first);
        await tester.pumpAndSettle();

        final List<Checkbox> after = tester
            .widgetList<Checkbox>(find.byType(Checkbox))
            .toList();
        expect(after[0].value, isFalse);
      });

      testWidgets('должен отображать предвыбранные платформы',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(selectedIds: <int>[1, 3]));
        await openSheet(tester);

        final List<Checkbox> checkboxes = tester
            .widgetList<Checkbox>(find.byType(Checkbox))
            .toList();

        // PS5 (id:1) — выбран, Xbox (id:2) — нет, Switch (id:3) — выбран
        expect(checkboxes[0].value, isTrue);
        expect(checkboxes[1].value, isFalse);
        expect(checkboxes[2].value, isTrue);
      });
    });

    group('Clear All', () {
      testWidgets('должен очищать все выбранные',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(selectedIds: <int>[1, 2, 3]));
        await openSheet(tester);

        final int selectedBefore = tester
            .widgetList<Checkbox>(find.byType(Checkbox))
            .where((Checkbox c) => c.value == true)
            .length;
        expect(selectedBefore, 3);

        await tester.tap(find.textContaining('Clear'));
        await tester.pumpAndSettle();

        final int selectedAfter = tester
            .widgetList<Checkbox>(find.byType(Checkbox))
            .where((Checkbox c) => c.value == true)
            .length;
        expect(selectedAfter, 0);
      });
    });

    group('Apply', () {
      testWidgets('должен вызывать onApply с выбранными ID',
          (WidgetTester tester) async {
        List<int>? appliedIds;

        await tester.pumpWidget(buildTestWidget(
          onApply: (List<int> ids) => appliedIds = ids,
        ));
        await openSheet(tester);

        // Выбираем первую и третью платформу
        await tester.tap(find.byType(ListTile).at(0));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(ListTile).at(2));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        expect(appliedIds, isNotNull);
        expect(appliedIds, containsAll(<int>[1, 3]));
        expect(appliedIds!.length, 2);
      });

      testWidgets('должен вызывать onApply с пустым списком при Show All',
          (WidgetTester tester) async {
        List<int>? appliedIds;

        await tester.pumpWidget(buildTestWidget(
          onApply: (List<int> ids) => appliedIds = ids,
        ));
        await openSheet(tester);

        // Нажимаем Show All (FilledButton когда ничего не выбрано)
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        expect(appliedIds, isNotNull);
        expect(appliedIds, isEmpty);
      });
    });

    group('Cancel', () {
      testWidgets('должен не вызывать onApply при Cancel',
          (WidgetTester tester) async {
        bool onApplyCalled = false;

        await tester.pumpWidget(buildTestWidget(
          onApply: (_) => onApplyCalled = true,
        ));
        await openSheet(tester);

        await tester.tap(find.byType(ListTile).first);
        await tester.pumpAndSettle();

        await tester.tap(find.byType(TextButton));
        await tester.pumpAndSettle();

        expect(onApplyCalled, isFalse);
      });
    });

    group('edge cases', () {
      testWidgets('должен сохранять выбор при фильтрации',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await openSheet(tester);

        // Выбираем первые 2
        await tester.tap(find.byType(ListTile).at(0));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ListTile).at(1));
        await tester.pumpAndSettle();

        final int selectedBefore = tester
            .widgetList<Checkbox>(find.byType(Checkbox))
            .where((Checkbox c) => c.value == true)
            .length;
        expect(selectedBefore, 2);

        // Фильтруем
        await tester.enterText(find.byType(TextField), 'play');
        await tester.pumpAndSettle();

        // Очищаем фильтр
        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();

        // Выбор сохранился
        final int selectedAfter = tester
            .widgetList<Checkbox>(find.byType(Checkbox))
            .where((Checkbox c) => c.value == true)
            .length;
        expect(selectedAfter, 2);
      });
    });
  });
}
