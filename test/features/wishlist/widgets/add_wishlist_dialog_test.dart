import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/wishlist/widgets/add_wishlist_dialog.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/wishlist_item.dart';

void main() {
  group('AddWishlistDialog', () {
    Future<void> pumpDialog(
      WidgetTester tester, {
      WishlistItem? existing,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    AddWishlistDialog.show(context, existing: existing);
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
      testWidgets('должен показывать заголовок Add to Wishlist',
          (WidgetTester tester) async {
        await pumpDialog(tester);

        expect(find.text('Add to Wishlist'), findsOneWidget);
        expect(find.text('Add'), findsOneWidget);
      });

      testWidgets('должен показывать пустые поля',
          (WidgetTester tester) async {
        await pumpDialog(tester);

        final TextField titleField = tester.widget<TextField>(
          find.widgetWithText(TextField, '').first,
        );
        expect(titleField.controller?.text, '');
      });

      testWidgets('должен показывать чипы типов медиа',
          (WidgetTester tester) async {
        await pumpDialog(tester);

        expect(find.text('Any'), findsOneWidget);
        expect(find.text('Game'), findsOneWidget);
        expect(find.text('Movie'), findsOneWidget);
        expect(find.text('TV Show'), findsOneWidget);
        expect(find.text('Animation'), findsOneWidget);
      });

      testWidgets('не должен отправлять пустой текст',
          (WidgetTester tester) async {
        await pumpDialog(tester);

        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        // Диалог не закрылся
        expect(find.text('Add to Wishlist'), findsOneWidget);
      });

      testWidgets('должен закрываться при Cancel',
          (WidgetTester tester) async {
        await pumpDialog(tester);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('Add to Wishlist'), findsNothing);
      });

      testWidgets('должен выбирать тип медиа',
          (WidgetTester tester) async {
        await pumpDialog(tester);

        // Нажимаем на Game чип
        await tester.tap(find.text('Game'));
        await tester.pumpAndSettle();

        // Game чип должен быть selected
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
        await pumpDialog(tester);

        // Выбираем Game
        await tester.tap(find.text('Game'));
        await tester.pumpAndSettle();

        // Нажимаем Any — снимает выбор
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
    });

    group('режим редактирования', () {
      final WishlistItem existing = WishlistItem(
        id: 1,
        text: 'Chrono Trigger',
        mediaTypeHint: MediaType.game,
        note: 'SNES RPG',
        createdAt: DateTime(2024, 6, 15),
      );

      testWidgets('должен показывать заголовок Edit',
          (WidgetTester tester) async {
        await pumpDialog(tester, existing: existing);

        expect(find.text('Edit Wishlist Item'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
      });

      testWidgets('должен предзаполнять текст',
          (WidgetTester tester) async {
        await pumpDialog(tester, existing: existing);

        expect(find.text('Chrono Trigger'), findsOneWidget);
      });

      testWidgets('должен предзаполнять заметку',
          (WidgetTester tester) async {
        await pumpDialog(tester, existing: existing);

        expect(find.text('SNES RPG'), findsOneWidget);
      });

      testWidgets('должен предвыбирать тип медиа',
          (WidgetTester tester) async {
        await pumpDialog(tester, existing: existing);

        final ChoiceChip gameChip = tester.widget<ChoiceChip>(
          find.ancestor(
            of: find.text('Game'),
            matching: find.byType(ChoiceChip),
          ),
        );
        expect(gameChip.selected, true);
      });
    });
  });
}
