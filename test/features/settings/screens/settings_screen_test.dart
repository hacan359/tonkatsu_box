// Тесты для SettingsScreen (hub с 4 плитками навигации).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/features/settings/screens/settings_screen.dart';
import 'package:xerabora/shared/widgets/auto_breadcrumb_app_bar.dart';
import 'package:xerabora/shared/widgets/breadcrumb_scope.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  Widget createWidget() {
    return ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(
        home: BreadcrumbScope(
          label: 'Settings',
          child: SettingsScreen(),
        ),
      ),
    );
  }

  group('SettingsScreen', () {
    group('UI components', () {
      testWidgets('shows breadcrumb with Settings label', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byType(AutoBreadcrumbAppBar), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
      });

      testWidgets('shows Credentials tile with correct icon and subtitle',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder credentialsTile = find.ancestor(
          of: find.text('Credentials'),
          matching: find.byType(ListTile),
        );

        expect(credentialsTile, findsOneWidget);
        expect(
          find.descendant(
            of: credentialsTile,
            matching: find.text('IGDB, SteamGridDB, TMDB API keys'),
          ),
          findsOneWidget,
        );

        // Проверяем leading icon
        final ListTile tile = tester.widget<ListTile>(credentialsTile);
        final Icon? leadingIcon = tile.leading as Icon?;
        expect(leadingIcon, isNotNull);
        expect(leadingIcon!.icon, equals(Icons.key));
      });

      testWidgets('shows Cache tile with correct icon and subtitle',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder cacheTile = find.ancestor(
          of: find.text('Cache'),
          matching: find.byType(ListTile),
        );

        expect(cacheTile, findsOneWidget);
        expect(
          find.descendant(
            of: cacheTile,
            matching: find.text('Image cache settings'),
          ),
          findsOneWidget,
        );

        final ListTile tile = tester.widget<ListTile>(cacheTile);
        final Icon? leadingIcon = tile.leading as Icon?;
        expect(leadingIcon, isNotNull);
        expect(leadingIcon!.icon, equals(Icons.cached));
      });

      testWidgets('shows Database tile with correct icon and subtitle',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder databaseTile = find.ancestor(
          of: find.text('Database'),
          matching: find.byType(ListTile),
        );

        expect(databaseTile, findsOneWidget);
        expect(
          find.descendant(
            of: databaseTile,
            matching: find.text('Export, import, reset'),
          ),
          findsOneWidget,
        );

        final ListTile tile = tester.widget<ListTile>(databaseTile);
        final Icon? leadingIcon = tile.leading as Icon?;
        expect(leadingIcon, isNotNull);
        expect(leadingIcon!.icon, equals(Icons.storage));
      });

      testWidgets('shows Debug tile with correct icon and subtitle when in debug mode',
          (WidgetTester tester) async {
        // В тестах kDebugMode всегда true
        expect(kDebugMode, isTrue);

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder debugTile = find.ancestor(
          of: find.text('Debug'),
          matching: find.byType(ListTile),
        );

        expect(debugTile, findsOneWidget);

        // Без SteamGridDB ключа показывает предупреждение
        expect(
          find.text('Set SteamGridDB key first for some tools'),
          findsOneWidget,
        );

        final ListTile tile = tester.widget<ListTile>(debugTile);
        final Icon? leadingIcon = tile.leading as Icon?;
        expect(leadingIcon, isNotNull);
        expect(leadingIcon!.icon, equals(Icons.bug_report));
      });

      testWidgets('Debug tile subtitle changes when SteamGridDB key is set',
          (WidgetTester tester) async {
        // Устанавливаем SteamGridDB ключ
        await prefs.setString(SettingsKeys.steamGridDbApiKey, 'test-key');

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Developer tools'), findsOneWidget);
        expect(
          find.text('Set SteamGridDB key first for some tools'),
          findsNothing,
        );
      });

      testWidgets('shows Author name tile with edit icon',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder authorTile = find.ancestor(
          of: find.text('Author name'),
          matching: find.byType(ListTile),
        );
        expect(authorTile, findsOneWidget);

        final ListTile tile = tester.widget<ListTile>(authorTile);
        final Icon? trailingIcon = tile.trailing as Icon?;
        expect(trailingIcon!.icon, equals(Icons.edit));

        // Дефолтное имя автора
        expect(find.text('User'), findsOneWidget);
      });

      testWidgets('shows chevron_right trailing icons for navigation tiles',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // 5 плиток всего: Author name + Credentials + Cache + Database + Debug
        final Iterable<ListTile> allTiles = tester.widgetList<ListTile>(
          find.byType(ListTile),
        );
        expect(allTiles.length, equals(5));

        // 4 навигационные плитки имеют chevron_right + 1 breadcrumb separator
        expect(find.byIcon(Icons.chevron_right), findsNWidgets(5));
      });
    });

    group('Navigation', () {
      testWidgets('all tiles have onTap callback', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Iterable<ListTile> tiles = tester.widgetList<ListTile>(
          find.byType(ListTile),
        );

        for (final ListTile tile in tiles) {
          expect(tile.onTap, isNotNull, reason: 'Tile "${tile.title}" should have onTap');
        }
      });

      testWidgets('Credentials tile is tappable', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder credentialsTile = find.ancestor(
          of: find.text('Credentials'),
          matching: find.byType(ListTile),
        );

        // Tap не должен вызвать ошибку (навигация работает)
        await tester.tap(credentialsTile);
        await tester.pumpAndSettle();

        // После навигации SettingsScreen в стеке, но перекрыт новым экраном
        expect(tester.takeException(), isNull);
      });

      testWidgets('Cache tile is tappable', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder cacheTile = find.ancestor(
          of: find.text('Cache'),
          matching: find.byType(ListTile),
        );

        await tester.tap(cacheTile);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('Database tile is tappable', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder databaseTile = find.ancestor(
          of: find.text('Database'),
          matching: find.byType(ListTile),
        );

        await tester.tap(databaseTile);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('Debug tile is tappable', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder debugTile = find.ancestor(
          of: find.text('Debug'),
          matching: find.byType(ListTile),
        );

        await tester.tap(debugTile);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('Author name tile opens edit dialog', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder authorTile = find.ancestor(
          of: find.text('Author name'),
          matching: find.byType(ListTile),
        );

        await tester.tap(authorTile);
        await tester.pumpAndSettle();

        expect(find.text('Author name'), findsNWidgets(2)); // tile + dialog title
        expect(find.text('Save'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('Author name shows custom name when set', (WidgetTester tester) async {
        await prefs.setString(SettingsKeys.defaultAuthor, 'Hacan');

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Hacan'), findsOneWidget);
      });
    });

    group('Error handling', () {
      testWidgets('does not show error card by default', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.warning_amber), findsNothing);
      });

      testWidgets('shows error card when errorMessage is set',
          (WidgetTester tester) async {
        const String errorMessage = 'Test error message';

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              sharedPreferencesProvider.overrideWithValue(prefs),
              settingsNotifierProvider.overrideWith(
                () => _TestSettingsNotifier(errorMessage),
              ),
            ],
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.warning_amber), findsOneWidget);
        expect(find.text(errorMessage), findsOneWidget);
      });
    });

  });
}

/// Тестовый notifier с кастомным errorMessage.
class _TestSettingsNotifier extends SettingsNotifier {
  _TestSettingsNotifier(this._errorMessage);

  final String _errorMessage;

  @override
  SettingsState build() {
    return SettingsState(errorMessage: _errorMessage);
  }
}
