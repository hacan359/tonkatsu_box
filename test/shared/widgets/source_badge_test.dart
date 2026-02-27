import 'package:xerabora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/widgets/source_badge.dart';

void main() {
  Widget buildTestWidget({
    required DataSource source,
    SourceBadgeSize size = SourceBadgeSize.small,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: SourceBadge(
          source: source,
          size: size,
          onTap: onTap,
        ),
      ),
    );
  }

  group('DataSource', () {
    test('igdb должен иметь правильный label и цвет', () {
      expect(DataSource.igdb.label, 'IGDB');
      expect(DataSource.igdb.color, const Color(0xFF9147FF));
    });

    test('tmdb должен иметь правильный label и цвет', () {
      expect(DataSource.tmdb.label, 'TMDB');
      expect(DataSource.tmdb.color, const Color(0xFF01D277));
    });

    test('steamGridDb должен иметь правильный label и цвет', () {
      expect(DataSource.steamGridDb.label, 'SGDB');
      expect(DataSource.steamGridDb.color, const Color(0xFF3A9BDC));
    });

    test('vgMaps должен иметь правильный label и цвет', () {
      expect(DataSource.vgMaps.label, 'VGMaps');
      expect(DataSource.vgMaps.color, const Color(0xFFE57C23));
    });

    test('все значения enum перечислены', () {
      expect(DataSource.values.length, 4);
    });
  });

  group('SourceBadgeSize', () {
    test('small должен иметь правильные размеры', () {
      expect(SourceBadgeSize.small.fontSize, 8);
      expect(SourceBadgeSize.small.horizontalPadding, 4);
      expect(SourceBadgeSize.small.verticalPadding, 2);
      expect(SourceBadgeSize.small.borderRadius, 3);
    });

    test('medium должен иметь правильные размеры', () {
      expect(SourceBadgeSize.medium.fontSize, 10);
      expect(SourceBadgeSize.medium.horizontalPadding, 6);
      expect(SourceBadgeSize.medium.verticalPadding, 3);
      expect(SourceBadgeSize.medium.borderRadius, 4);
    });

    test('large должен иметь правильные размеры', () {
      expect(SourceBadgeSize.large.fontSize, 12);
      expect(SourceBadgeSize.large.horizontalPadding, 8);
      expect(SourceBadgeSize.large.verticalPadding, 4);
      expect(SourceBadgeSize.large.borderRadius, 6);
    });

    test('все значения enum перечислены', () {
      expect(SourceBadgeSize.values.length, 3);
    });
  });

  group('SourceBadge', () {
    group('рендеринг', () {
      testWidgets('должен показывать текст IGDB',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(source: DataSource.igdb));

        expect(find.text('IGDB'), findsOneWidget);
      });

      testWidgets('должен показывать текст TMDB',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(source: DataSource.tmdb));

        expect(find.text('TMDB'), findsOneWidget);
      });

      testWidgets('должен показывать текст SGDB',
          (WidgetTester tester) async {
        await tester
            .pumpWidget(buildTestWidget(source: DataSource.steamGridDb));

        expect(find.text('SGDB'), findsOneWidget);
      });

      testWidgets('должен показывать текст VGMaps',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(source: DataSource.vgMaps));

        expect(find.text('VGMaps'), findsOneWidget);
      });
    });

    group('стили текста', () {
      testWidgets('должен использовать цвет источника для текста',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(source: DataSource.igdb));

        final Text text = tester.widget<Text>(find.text('IGDB'));
        final TextStyle style = text.style!;
        expect(style.color, DataSource.igdb.color);
      });

      testWidgets('должен использовать жирный шрифт',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(source: DataSource.tmdb));

        final Text text = tester.widget<Text>(find.text('TMDB'));
        final TextStyle style = text.style!;
        expect(style.fontWeight, FontWeight.w700);
      });

      testWidgets('должен иметь letterSpacing 0.5',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(source: DataSource.tmdb));

        final Text text = tester.widget<Text>(find.text('TMDB'));
        final TextStyle style = text.style!;
        expect(style.letterSpacing, 0.5);
      });

      testWidgets('должен иметь height 1', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(source: DataSource.igdb));

        final Text text = tester.widget<Text>(find.text('IGDB'));
        final TextStyle style = text.style!;
        expect(style.height, 1);
      });
    });

    group('размеры', () {
      testWidgets('small должен использовать fontSize 8',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          source: DataSource.igdb,
          size: SourceBadgeSize.small,
        ));

        final Text text = tester.widget<Text>(find.text('IGDB'));
        expect(text.style!.fontSize, 8);
      });

      testWidgets('medium должен использовать fontSize 10',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          source: DataSource.tmdb,
          size: SourceBadgeSize.medium,
        ));

        final Text text = tester.widget<Text>(find.text('TMDB'));
        expect(text.style!.fontSize, 10);
      });

      testWidgets('large должен использовать fontSize 12',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          source: DataSource.steamGridDb,
          size: SourceBadgeSize.large,
        ));

        final Text text = tester.widget<Text>(find.text('SGDB'));
        expect(text.style!.fontSize, 12);
      });

      testWidgets('по умолчанию должен быть small',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Scaffold(
              body: SourceBadge(source: DataSource.igdb),
            ),
          ),
        );

        final Text text = tester.widget<Text>(find.text('IGDB'));
        expect(text.style!.fontSize, 8);
      });
    });

    group('декорация контейнера', () {
      testWidgets('должен иметь фон с alpha 0.15',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(source: DataSource.igdb));

        final Container container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final BoxDecoration decoration =
            container.decoration! as BoxDecoration;
        expect(
          decoration.color,
          DataSource.igdb.color.withValues(alpha: 0.15),
        );
      });

      testWidgets('должен иметь border с alpha 0.4',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(source: DataSource.tmdb));

        final Container container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final BoxDecoration decoration =
            container.decoration! as BoxDecoration;
        final Border border = decoration.border! as Border;
        expect(
          border.top.color,
          DataSource.tmdb.color.withValues(alpha: 0.4),
        );
        expect(border.top.width, 0.5);
      });

      testWidgets('должен иметь borderRadius для small',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          source: DataSource.igdb,
          size: SourceBadgeSize.small,
        ));

        final Container container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final BoxDecoration decoration =
            container.decoration! as BoxDecoration;
        expect(
          decoration.borderRadius,
          BorderRadius.circular(3),
        );
      });

      testWidgets('должен иметь borderRadius для large',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          source: DataSource.steamGridDb,
          size: SourceBadgeSize.large,
        ));

        final Container container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final BoxDecoration decoration =
            container.decoration! as BoxDecoration;
        expect(
          decoration.borderRadius,
          BorderRadius.circular(6),
        );
      });

      testWidgets('должен иметь правильные padding для small',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          source: DataSource.igdb,
          size: SourceBadgeSize.small,
        ));

        final Container container = tester.widget<Container>(
          find.byType(Container).first,
        );
        expect(
          container.padding,
          const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        );
      });

      testWidgets('должен иметь правильные padding для medium',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          source: DataSource.igdb,
          size: SourceBadgeSize.medium,
        ));

        final Container container = tester.widget<Container>(
          find.byType(Container).first,
        );
        expect(
          container.padding,
          const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        );
      });

      testWidgets('должен иметь правильные padding для large',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          source: DataSource.vgMaps,
          size: SourceBadgeSize.large,
        ));

        final Container container = tester.widget<Container>(
          find.byType(Container).first,
        );
        expect(
          container.padding,
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        );
      });
    });

    group('все источники рендерятся', () {
      for (final DataSource source in DataSource.values) {
        testWidgets('${source.name} должен рендериться без ошибок',
            (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(source: source));

          expect(find.text(source.label), findsOneWidget);
          expect(find.byType(SourceBadge), findsOneWidget);
        });
      }
    });

    group('все размеры рендерятся', () {
      for (final SourceBadgeSize size in SourceBadgeSize.values) {
        testWidgets('${size.name} должен рендериться без ошибок',
            (WidgetTester tester) async {
          await tester.pumpWidget(buildTestWidget(
            source: DataSource.igdb,
            size: size,
          ));

          expect(find.byType(SourceBadge), findsOneWidget);
        });
      }
    });

    group('onTap', () {
      testWidgets('не должен показывать иконку open_in_new без onTap',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(source: DataSource.igdb));

        expect(find.byIcon(Icons.open_in_new), findsNothing);
      });

      testWidgets('должен показывать иконку open_in_new с onTap',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          source: DataSource.igdb,
          onTap: () {},
        ));

        expect(find.byIcon(Icons.open_in_new), findsOneWidget);
      });

      testWidgets('не должен оборачивать в InkWell без onTap',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(source: DataSource.igdb));

        expect(find.byType(InkWell), findsNothing);
      });

      testWidgets('должен оборачивать в InkWell с onTap',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          source: DataSource.igdb,
          onTap: () {},
        ));

        expect(find.byType(InkWell), findsOneWidget);
      });

      testWidgets('должен вызывать onTap при нажатии',
          (WidgetTester tester) async {
        bool tapped = false;
        await tester.pumpWidget(buildTestWidget(
          source: DataSource.igdb,
          onTap: () => tapped = true,
        ));

        await tester.tap(find.byType(InkWell));
        expect(tapped, isTrue);
      });

      testWidgets('иконка open_in_new должна использовать цвет источника',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          source: DataSource.tmdb,
          size: SourceBadgeSize.medium,
          onTap: () {},
        ));

        final Icon icon = tester.widget<Icon>(
          find.byIcon(Icons.open_in_new),
        );
        expect(icon.color, DataSource.tmdb.color);
        expect(icon.size, SourceBadgeSize.medium.fontSize);
      });
    });
  });
}
