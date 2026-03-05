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
    test('igdb должен иметь правильный label', () {
      expect(DataSource.igdb.label, 'IGDB');
    });

    test('tmdb должен иметь правильный label', () {
      expect(DataSource.tmdb.label, 'TMDB');
    });

    test('steamGridDb должен иметь правильный label', () {
      expect(DataSource.steamGridDb.label, 'SGDB');
    });

    test('vgMaps должен иметь правильный label', () {
      expect(DataSource.vgMaps.label, 'VGMaps');
    });

    test('anilist должен иметь правильный label', () {
      expect(DataSource.anilist.label, 'AniList');
    });

    test('все значения enum перечислены', () {
      expect(DataSource.values.length, 6);
    });
  });

  group('SourceBadge', () {
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
    });
  });
}
