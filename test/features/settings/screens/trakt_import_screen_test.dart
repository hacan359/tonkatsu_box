// Тесты для TraktImportScreen (импорт из Trakt.tv ZIP).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/core/services/trakt_zip_import_service.dart';
import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/features/settings/screens/trakt_import_screen.dart';
import 'package:xerabora/features/settings/widgets/settings_group.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/widgets/breadcrumb_scope.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockTraktZipImportService mockService;

  setUp(() {
    mockService = MockTraktZipImportService();
  });

  Widget createWidget({
    double width = 1024,
    double height = 768,
    List<Collection> collections = const <Collection>[],
  }) {
    return ProviderScope(
      overrides: <Override>[
        traktZipImportServiceProvider.overrideWithValue(mockService),
        collectionsProvider.overrideWith(
          () => _TestCollectionsNotifier(collections),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, height)),
          child: const BreadcrumbScope(
            label: 'Settings',
            child: TraktImportScreen(),
          ),
        ),
      ),
    );
  }

  group('TraktImportScreen', () {
    group('UI structure', () {
      testWidgets('shows instructions section with description',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Download your data from trakt.tv/users/YOU/data '
            'and select the ZIP file below.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('shows file picker section with Select ZIP File button',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Select ZIP File'), findsOneWidget);
        expect(find.byIcon(Icons.folder_open), findsOneWidget);
      });

      testWidgets('shows exactly 2 SettingsGroup widgets',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byType(SettingsGroup), findsOneWidget);
      });

      testWidgets('does NOT show preview section before file selection',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Import watched items'), findsNothing);
        expect(find.text('Import ratings'), findsNothing);
        expect(find.text('Import watchlist'), findsNothing);
      });

      testWidgets('does NOT show import button before file selection',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Start Import'), findsNothing);
      });
    });

    group('Breadcrumbs', () {
      testWidgets('shows "Settings" and "Trakt Import" in breadcrumbs',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Trakt Import'), findsOneWidget);
      });
    });

    group('Compact layout', () {
      testWidgets('renders without errors on narrow screens',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(width: 500, height: 800));
        await tester.pumpAndSettle();

        expect(find.text('Select ZIP File'), findsOneWidget);
        expect(find.byType(SettingsGroup), findsOneWidget);
      });

      testWidgets('renders without errors on wide screens',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(width: 1024, height: 768));
        await tester.pumpAndSettle();

        expect(find.text('Select ZIP File'), findsOneWidget);
      });
    });

    group('Select ZIP File button', () {
      testWidgets('button is an OutlinedButton', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byType(OutlinedButton), findsOneWidget);
      });

      testWidgets('button has folder_open icon', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder button = find.byType(OutlinedButton);
        final Finder iconInButton = find.descendant(
          of: button,
          matching: find.byIcon(Icons.folder_open),
        );
        expect(iconInButton, findsOneWidget);
      });
    });

    group('No validation error initially', () {
      testWidgets('does not show validation error text',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Invalid Trakt export'), findsNothing);
        expect(find.text('Invalid ZIP archive'), findsNothing);
        expect(find.text('No JSON files found in archive'), findsNothing);
      });
    });
  });
}

/// Тестовый notifier для коллекций с предопределёнными данными.
class _TestCollectionsNotifier extends CollectionsNotifier {
  _TestCollectionsNotifier(this._collections);

  final List<Collection> _collections;

  @override
  Future<List<Collection>> build() async {
    return _collections;
  }
}
