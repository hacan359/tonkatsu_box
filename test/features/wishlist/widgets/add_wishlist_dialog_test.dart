import 'package:xerabora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/wishlist/widgets/add_wishlist_dialog.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/wishlist_item.dart';

void main() {
  group('AddWishlistForm', () {
    Future<void> pumpForm(
      WidgetTester tester, {
      WishlistItem? existing,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    AddWishlistForm.show(context, existing: existing);
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    group('режим создания', () {
      testWidgets('должен показывать кнопку Add в AppBar',
          (WidgetTester tester) async {
        await pumpForm(tester);

        expect(find.widgetWithText(TextButton, 'Add'), findsOneWidget);
      });

      testWidgets('должен показывать пустые поля',
          (WidgetTester tester) async {
        await pumpForm(tester);

        final TextField titleField = tester.widget<TextField>(
          find.widgetWithText(TextField, '').first,
        );
        expect(titleField.controller?.text, '');
      });

      testWidgets('должен показывать чипы типов медиа',
          (WidgetTester tester) async {
        await pumpForm(tester);

        expect(find.text('Any'), findsOneWidget);
        expect(find.text('Game'), findsOneWidget);
        expect(find.text('Movie'), findsOneWidget);
        expect(find.text('TV Show'), findsOneWidget);
        expect(find.text('Animation'), findsOneWidget);
      });

      testWidgets('не должен отправлять пустой текст',
          (WidgetTester tester) async {
        await pumpForm(tester);

        await tester.tap(find.widgetWithText(TextButton, 'Add'));
        await tester.pumpAndSettle();

        // Экран не закрылся, показывается ошибка.
        expect(find.byType(TextField), findsWidgets);
        expect(find.text('At least 2 characters'), findsOneWidget);
      });

      testWidgets('не должен отправлять текст из 1 символа',
          (WidgetTester tester) async {
        await pumpForm(tester);

        await tester.enterText(
          find.widgetWithText(TextField, '').first,
          'A',
        );
        await tester.tap(find.widgetWithText(TextButton, 'Add'));
        await tester.pumpAndSettle();

        expect(find.text('At least 2 characters'), findsOneWidget);
      });

      testWidgets('ошибка исчезает при вводе текста',
          (WidgetTester tester) async {
        await pumpForm(tester);

        // Вызываем ошибку.
        await tester.tap(find.widgetWithText(TextButton, 'Add'));
        await tester.pumpAndSettle();
        expect(find.text('At least 2 characters'), findsOneWidget);

        // Начинаем вводить — ошибка исчезает.
        await tester.enterText(
          find.widgetWithText(TextField, '').first,
          'Te',
        );
        await tester.pumpAndSettle();
        expect(find.text('At least 2 characters'), findsNothing);
      });

      testWidgets('должен выбирать тип медиа',
          (WidgetTester tester) async {
        await pumpForm(tester);

        await tester.tap(find.text('Game'));
        await tester.pumpAndSettle();

        final ChoiceChip gameChip = tester.widget<ChoiceChip>(
          find.ancestor(
            of: find.text('Game'),
            matching: find.byType(ChoiceChip),
          ),
        );
        expect(gameChip.selected, true);
      });

      testWidgets('должен снимать выбор при повторном нажатии на Any',
          (WidgetTester tester) async {
        await pumpForm(tester);

        await tester.tap(find.text('Game'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Any'));
        await tester.pumpAndSettle();

        final ChoiceChip anyChip = tester.widget<ChoiceChip>(
          find.ancestor(
            of: find.text('Any'),
            matching: find.byType(ChoiceChip),
          ),
        );
        expect(anyChip.selected, true);
      });

      testWidgets('чипы не показывают checkmark',
          (WidgetTester tester) async {
        await pumpForm(tester);

        await tester.tap(find.text('Game'));
        await tester.pumpAndSettle();

        final ChoiceChip gameChip = tester.widget<ChoiceChip>(
          find.ancestor(
            of: find.text('Game'),
            matching: find.byType(ChoiceChip),
          ),
        );
        expect(gameChip.showCheckmark, false);
      });

      testWidgets('кнопка Add — TextButton в AppBar',
          (WidgetTester tester) async {
        await pumpForm(tester);

        expect(
          find.widgetWithText(TextButton, 'Add'),
          findsOneWidget,
        );
      });

      testWidgets('должен закрыться при отправке валидного текста',
          (WidgetTester tester) async {
        await pumpForm(tester);

        await tester.enterText(
          find.widgetWithText(TextField, '').first,
          'Chrono Trigger',
        );
        await tester.tap(find.widgetWithText(TextButton, 'Add'));
        await tester.pumpAndSettle();

        // Форма закрылась — вернулись на предыдущий экран.
        expect(find.widgetWithText(TextButton, 'Add'), findsNothing);
        expect(find.text('Open'), findsOneWidget);
      });

      testWidgets('должен отправить note если заполнена',
          (WidgetTester tester) async {
        await pumpForm(tester);

        // Заполняем Title.
        await tester.enterText(
          find.widgetWithText(TextField, '').first,
          'Chrono Trigger',
        );
        // Заполняем Note.
        final Finder noteField = find.widgetWithText(TextField, '').last;
        await tester.enterText(noteField, 'SNES RPG');

        await tester.tap(find.widgetWithText(TextButton, 'Add'));
        await tester.pumpAndSettle();

        // Форма закрылась.
        expect(find.text('Open'), findsOneWidget);
      });

      testWidgets('onChanged не вызывает setState если ошибки нет',
          (WidgetTester tester) async {
        await pumpForm(tester);

        // Вводим текст без предварительной ошибки — не должно падать.
        await tester.enterText(
          find.widgetWithText(TextField, '').first,
          'Test',
        );
        await tester.pumpAndSettle();

        // Ошибки не было и нет.
        expect(find.text('At least 2 characters'), findsNothing);
      });

      testWidgets('показывает breadcrumb Add',
          (WidgetTester tester) async {
        await pumpForm(tester);

        // Breadcrumb "Add" от BreadcrumbScope.
        expect(find.text('Add'), findsWidgets);
      });
    });

    group('режим редактирования', () {
      final WishlistItem existing = WishlistItem(
        id: 1,
        text: 'Chrono Trigger',
        mediaTypeHint: MediaType.game,
        note: 'SNES RPG',
        createdAt: DateTime(2024, 6, 15),
      );

      testWidgets('должен показывать кнопку Save',
          (WidgetTester tester) async {
        await pumpForm(tester, existing: existing);

        expect(find.text('Save'), findsOneWidget);
      });

      testWidgets('должен предзаполнять текст',
          (WidgetTester tester) async {
        await pumpForm(tester, existing: existing);

        expect(find.text('Chrono Trigger'), findsOneWidget);
      });

      testWidgets('должен предзаполнять заметку',
          (WidgetTester tester) async {
        await pumpForm(tester, existing: existing);

        expect(find.text('SNES RPG'), findsOneWidget);
      });

      testWidgets('должен предвыбирать тип медиа',
          (WidgetTester tester) async {
        await pumpForm(tester, existing: existing);

        final ChoiceChip gameChip = tester.widget<ChoiceChip>(
          find.ancestor(
            of: find.text('Game'),
            matching: find.byType(ChoiceChip),
          ),
        );
        expect(gameChip.selected, true);
      });

      testWidgets('показывает breadcrumb Edit',
          (WidgetTester tester) async {
        await pumpForm(tester, existing: existing);

        expect(find.text('Edit'), findsWidgets);
      });
    });
  });
}
