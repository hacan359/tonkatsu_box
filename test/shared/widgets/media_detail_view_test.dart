import 'package:xerabora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/widgets/media_detail_view.dart';
import 'package:xerabora/shared/widgets/source_badge.dart';

void main() {
  Widget buildTestWidget({
    String title = 'Test Title',
    String? coverUrl,
    IconData placeholderIcon = Icons.videogame_asset,
    DataSource source = DataSource.igdb,
    IconData typeIcon = Icons.sports_esports,
    String typeLabel = 'SNES',
    List<MediaDetailChip> infoChips = const <MediaDetailChip>[],
    String? description,
    Widget? statusWidget,
    List<Widget>? extraSections,
    String? authorComment,
    String? userComment,
    bool hasAuthorComment = false,
    bool hasUserComment = false,
    bool isEditable = true,
    ValueChanged<String?>? onAuthorCommentSave,
    ValueChanged<String?>? onUserCommentSave,
  }) {
    return MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
      home: MediaDetailView(
        title: title,
        coverUrl: coverUrl,
        placeholderIcon: placeholderIcon,
        source: source,
        typeIcon: typeIcon,
        typeLabel: typeLabel,
        infoChips: infoChips,
        description: description,
        statusWidget: statusWidget,
        extraSections: extraSections,
        authorComment: authorComment,
        userComment: userComment,
        hasAuthorComment: hasAuthorComment,
        hasUserComment: hasUserComment,
        isEditable: isEditable,
        onAuthorCommentSave: onAuthorCommentSave ?? (_) {},
        onUserCommentSave: onUserCommentSave ?? (_) {},
      ),
    );
  }

  group('MediaDetailChip', () {
    test('должен хранить icon и text', () {
      const MediaDetailChip chip = MediaDetailChip(
        icon: Icons.star,
        text: '8.5/10',
      );

      expect(chip.icon, Icons.star);
      expect(chip.text, '8.5/10');
    });
  });

  group('MediaDetailView', () {
    group('AppBar', () {
      testWidgets('должен отображать title', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(title: 'Chrono Trigger'));
        await tester.pumpAndSettle();

        expect(find.text('Chrono Trigger'), findsOneWidget);
      });
    });

    group('Header', () {
      testWidgets('должен отображать placeholder когда coverUrl == null',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          placeholderIcon: Icons.movie_outlined,
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
      });

      testWidgets('должен отображать SourceBadge',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(source: DataSource.igdb));
        await tester.pumpAndSettle();

        expect(find.byType(SourceBadge), findsOneWidget);
        expect(find.text('IGDB'), findsOneWidget);
      });

      testWidgets('должен отображать SourceBadge TMDB',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(source: DataSource.tmdb));
        await tester.pumpAndSettle();

        expect(find.text('TMDB'), findsOneWidget);
      });

      testWidgets('должен отображать typeIcon',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          typeIcon: Icons.tv_outlined,
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.tv_outlined), findsOneWidget);
      });

      testWidgets('должен отображать typeLabel',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(typeLabel: 'TV Show'));
        await tester.pumpAndSettle();

        expect(find.text('TV Show'), findsOneWidget);
      });
    });

    group('Info Chips', () {
      testWidgets('должен отображать чипы когда список не пуст',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          infoChips: const <MediaDetailChip>[
            MediaDetailChip(icon: Icons.calendar_today, text: '1995'),
            MediaDetailChip(icon: Icons.star, text: '8.5/10'),
          ],
        ));
        await tester.pumpAndSettle();

        expect(find.text('1995'), findsOneWidget);
        expect(find.text('8.5/10'), findsOneWidget);
      });

      testWidgets('не должен отображать Wrap когда список пуст',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          infoChips: const <MediaDetailChip>[],
        ));
        await tester.pumpAndSettle();

        expect(find.byType(Wrap), findsNothing);
      });
    });

    group('Description', () {
      testWidgets('должен отображать описание когда не null',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          description: 'A great RPG adventure.',
        ));
        await tester.pumpAndSettle();

        expect(find.text('A great RPG adventure.'), findsOneWidget);
      });

      testWidgets('не должен отображать описание когда null',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Нет текста описания, только стандартные секции
        expect(find.text("Author's Review"), findsOneWidget);
        expect(find.text('My Notes'), findsOneWidget);
      });

      testWidgets('не должен отображать описание когда пустая строка',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(description: ''));
        await tester.pumpAndSettle();

        // Пустое описание не рендерится
        expect(find.text(''), findsNothing);
      });
    });

    group('Status Section', () {
      testWidgets('должен отображать секцию статуса когда statusWidget != null',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          statusWidget: const Text('Playing'),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Status'), findsOneWidget);
        expect(find.text('Playing'), findsOneWidget);
      });

      testWidgets('не должен отображать секцию статуса когда statusWidget == null',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Status'), findsNothing);
      });
    });

    group('Extra Sections', () {
      testWidgets('должен отображать дополнительные секции в ExpansionTile',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          extraSections: <Widget>[
            const Text('Progress Section'),
            const Text('Another Section'),
          ],
        ));
        await tester.pumpAndSettle();

        // Extra sections are inside collapsed "Activity & Progress" ExpansionTile
        expect(find.text('Activity & Progress'), findsOneWidget);
        // Раскрываем ExpansionTile
        await tester.tap(find.text('Activity & Progress'));
        await tester.pumpAndSettle();

        expect(find.text('Progress Section'), findsOneWidget);
        expect(find.text('Another Section'), findsOneWidget);
      });

      testWidgets('не должен отображать секции когда extraSections == null',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Activity & Progress'), findsNothing);
        expect(find.text('Progress Section'), findsNothing);
      });
    });

    group("Author's Review Section", () {
      testWidgets('должен отображать заголовок',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text("Author's Review"), findsOneWidget);
      });

      testWidgets('должен отображать комментарий когда есть',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          authorComment: 'Best RPG ever!',
          hasAuthorComment: true,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Best RPG ever!'), findsOneWidget);
      });

      testWidgets('должен показывать placeholder для editable без комментария',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          isEditable: true,
          hasAuthorComment: false,
        ));
        await tester.pumpAndSettle();

        expect(
          find.text('No review yet. Tap Edit to add one.'),
          findsOneWidget,
        );
      });

      testWidgets('должен показывать placeholder для readonly без комментария',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          isEditable: false,
          hasAuthorComment: false,
        ));
        await tester.pumpAndSettle();

        expect(
          find.text('No review from the author.'),
          findsOneWidget,
        );
      });

      testWidgets('должен показывать кнопку Edit когда isEditable',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(isEditable: true));
        await tester.pumpAndSettle();

        // 2 кнопки Edit: author comment + user notes
        expect(find.text('Edit'), findsNWidgets(2));
      });

      testWidgets('не должен показывать кнопку Edit автора когда !isEditable',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(isEditable: false));
        await tester.pumpAndSettle();

        // Только 1 кнопка Edit: user notes
        expect(find.text('Edit'), findsOneWidget);
      });
    });

    group('User Notes Section', () {
      testWidgets('должен отображать заголовок',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('My Notes'), findsOneWidget);
      });

      testWidgets('должен отображать заметки когда есть',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          userComment: 'Finished on Jan 15',
          hasUserComment: true,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Finished on Jan 15'), findsOneWidget);
      });

      testWidgets('должен показывать placeholder когда нет заметок',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(hasUserComment: false));
        await tester.pumpAndSettle();

        expect(
          find.text('No notes yet. Tap Edit to add your personal notes.'),
          findsOneWidget,
        );
      });

      testWidgets('должен всегда показывать кнопку Edit',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(isEditable: false));
        await tester.pumpAndSettle();

        // Кнопка Edit для заметок всегда видна
        expect(find.text('Edit'), findsOneWidget);
      });
    });

    group('Edit Dialog', () {
      // Порядок секций: My Notes (first Edit) → Author's Review (last Edit)

      testWidgets('должен открывать диалог при нажатии Edit заметок',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(isEditable: true));
        await tester.pumpAndSettle();

        // My Notes is first section → first Edit button
        await tester.tap(find.text('Edit').first);
        await tester.pumpAndSettle();

        expect(find.text('Edit My Notes'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
      });

      testWidgets('должен открывать диалог при нажатии Edit автора',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(isEditable: true));
        await tester.pumpAndSettle();

        // Author's Review is second section → last Edit button
        await tester.tap(find.text('Edit').last);
        await tester.pumpAndSettle();

        expect(find.text("Edit Author's Review"), findsOneWidget);
      });

      testWidgets('должен закрывать диалог при Cancel',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(isEditable: true));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Edit').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text("Edit Author's Review"), findsNothing);
      });

      testWidgets('не должен вызывать onSave при Cancel',
          (WidgetTester tester) async {
        bool wasCalled = false;
        await tester.pumpWidget(buildTestWidget(
          isEditable: true,
          onAuthorCommentSave: (_) => wasCalled = true,
        ));
        await tester.pumpAndSettle();

        // Author's Review → last Edit button
        await tester.tap(find.text('Edit').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(wasCalled, isFalse);
      });

      testWidgets('должен вызывать onSave с текстом при Save',
          (WidgetTester tester) async {
        String? savedValue;
        await tester.pumpWidget(buildTestWidget(
          isEditable: true,
          onAuthorCommentSave: (String? value) => savedValue = value,
        ));
        await tester.pumpAndSettle();

        // Author's Review → last Edit button
        await tester.tap(find.text('Edit').last);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'New comment');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(savedValue, 'New comment');
      });

      testWidgets('должен вызывать onSave с null при пустом тексте',
          (WidgetTester tester) async {
        String? savedValue = 'initial';
        await tester.pumpWidget(buildTestWidget(
          isEditable: true,
          onAuthorCommentSave: (String? value) => savedValue = value,
        ));
        await tester.pumpAndSettle();

        // Author's Review → last Edit button
        await tester.tap(find.text('Edit').last);
        await tester.pumpAndSettle();

        // Поле уже пустое, нажимаем Save
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(savedValue, isNull);
      });

      testWidgets('должен показывать initialValue в поле',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          isEditable: true,
          authorComment: 'Existing comment',
          hasAuthorComment: true,
        ));
        await tester.pumpAndSettle();

        // Author's Review → last Edit button
        await tester.tap(find.text('Edit').last);
        await tester.pumpAndSettle();

        final TextField textField =
            tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, 'Existing comment');
      });

      testWidgets('должен вызывать onUserCommentSave для заметок',
          (WidgetTester tester) async {
        String? savedValue;
        await tester.pumpWidget(buildTestWidget(
          isEditable: true,
          onUserCommentSave: (String? value) => savedValue = value,
        ));
        await tester.pumpAndSettle();

        // My Notes → first Edit button
        await tester.tap(find.text('Edit').first);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'My note');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(savedValue, 'My note');
      });
    });

    group('Полный layout', () {
      testWidgets('должен рендерить все секции',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          title: 'Full Test',
          typeLabel: 'Platform',
          infoChips: const <MediaDetailChip>[
            MediaDetailChip(icon: Icons.star, text: '9.0'),
          ],
          description: 'Test description',
          statusWidget: const Text('Status Widget'),
          extraSections: <Widget>[const Text('Extra')],
          authorComment: 'Author text',
          hasAuthorComment: true,
          userComment: 'User text',
          hasUserComment: true,
          isEditable: true,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Full Test'), findsOneWidget);
        expect(find.text('Platform'), findsOneWidget);
        expect(find.text('9.0'), findsOneWidget);
        expect(find.text('Test description'), findsOneWidget);
        expect(find.text('Status'), findsOneWidget);
        expect(find.text('Status Widget'), findsOneWidget);
        expect(find.text("Author's Review"), findsOneWidget);
        expect(find.text('Author text'), findsOneWidget);
        expect(find.text('My Notes'), findsOneWidget);
        expect(find.text('User text'), findsOneWidget);
        // Extra sections inside collapsed ExpansionTile
        expect(find.text('Activity & Progress'), findsOneWidget);
        await tester.tap(find.text('Activity & Progress'));
        await tester.pumpAndSettle();
        expect(find.text('Extra'), findsOneWidget);
      });
    });
  });
}
