// Тесты для SettingsScreen (единый grouped-list лейаут).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/features/settings/screens/settings_screen.dart';
import 'package:xerabora/features/settings/widgets/settings_group.dart';
import 'package:xerabora/features/settings/widgets/settings_tile.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/features/settings/widgets/inline_text_field.dart';
import 'package:xerabora/shared/widgets/auto_breadcrumb_app_bar.dart';
import 'package:xerabora/shared/widgets/breadcrumb_scope.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  Widget createWidget({double width = 400}) {
    return ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: const BreadcrumbScope(
            label: 'Settings',
            child: SettingsScreen(),
          ),
        ),
      ),
    );
  }

  group('SettingsScreen', () {
    group('Layout', () {
      testWidgets('shows breadcrumb with Settings label',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byType(AutoBreadcrumbAppBar), findsOneWidget);
        expect(find.text('Settings'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows SettingsGroup widgets',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Appearance, Data Sources, Storage, Import, Profile + more (some may need scroll)
        expect(find.byType(SettingsGroup), findsAtLeastNWidgets(4));
      });

      testWidgets('shows SettingsTile widgets',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byType(SettingsTile), findsAtLeastNWidgets(5));
      });

      testWidgets('uses same grouped-list layout on wide screens',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(width: 900));
        await tester.pumpAndSettle();

        // Same groups are shown, no sidebar
        expect(find.byType(SettingsGroup), findsAtLeastNWidgets(4));
        expect(find.byType(SettingsTile), findsAtLeastNWidgets(5));
      });

      testWidgets('wide layout constrains content width',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(width: 1200));
        await tester.pumpAndSettle();

        // Find the ConstrainedBox with maxWidth 600
        final Finder boxes = find.byType(ConstrainedBox);
        bool found600 = false;
        for (int i = 0; i < boxes.evaluate().length; i++) {
          final ConstrainedBox box =
              tester.widget<ConstrainedBox>(boxes.at(i));
          if (box.constraints.maxWidth == 600) {
            found600 = true;
            break;
          }
        }
        expect(found600, isTrue);
      });
    });

    group('Appearance section', () {
      testWidgets('shows App Language tile with current value',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('App Language'), findsOneWidget);
        expect(find.text('English'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows Content Language tile',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Content Language'), findsOneWidget);
      });

      testWidgets('shows Recommendations switch',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Recommendations'), findsOneWidget);
        expect(find.byType(Switch), findsOneWidget);
      });

      testWidgets('tapping App Language opens picker dialog',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder langTile = find.ancestor(
          of: find.text('App Language'),
          matching: find.byType(SettingsTile),
        );
        await tester.tap(langTile);
        await tester.pumpAndSettle();

        expect(find.byType(SimpleDialog), findsOneWidget);
      });

      testWidgets('tapping Content Language opens picker dialog',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder contentLangTile = find.ancestor(
          of: find.text('Content Language'),
          matching: find.byType(SettingsTile),
        );
        await tester.tap(contentLangTile);
        await tester.pumpAndSettle();

        expect(find.byType(SimpleDialog), findsOneWidget);
      });
    });

    group('Data Sources section', () {
      testWidgets('shows API Keys tile',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('API Keys'), findsOneWidget);
      });
    });

    group('Storage section', () {
      testWidgets('shows Cache and Database tiles',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Cache'), findsOneWidget);
        expect(find.text('Database'), findsOneWidget);
      });
    });

    group('Import section', () {
      testWidgets('shows Trakt Import tile',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();

        expect(find.text('Trakt Import'), findsOneWidget);
      });
    });

    group('Profile section', () {
      testWidgets('shows InlineTextField with author name',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byType(InlineTextField), findsOneWidget);
        expect(find.text('Author name'), findsOneWidget);
        expect(find.text('User'), findsOneWidget);
      });

      testWidgets('shows custom author name when set',
          (WidgetTester tester) async {
        await prefs.setString(SettingsKeys.defaultAuthor, 'Hacan');

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Hacan'), findsOneWidget);
      });
    });

    group('About section', () {
      testWidgets('shows About group after scrolling',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        expect(find.text('Welcome Guide'), findsOneWidget);
        expect(find.text('Credits & Licenses'), findsOneWidget);
        expect(find.text('Version'), findsOneWidget);
      });
    });


    group('Navigation', () {
      testWidgets('API Keys tile is tappable',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder apiKeysTile = find.ancestor(
          of: find.text('API Keys'),
          matching: find.byType(SettingsTile),
        );
        await tester.tap(apiKeysTile);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('Cache tile is tappable', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder cacheTile = find.ancestor(
          of: find.text('Cache'),
          matching: find.byType(SettingsTile),
        );
        await tester.tap(cacheTile);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('Database tile is tappable',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();

        final Finder databaseTile = find.ancestor(
          of: find.text('Database'),
          matching: find.byType(SettingsTile),
        );
        await tester.tap(databaseTile);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('Trakt Import tile is tappable',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();

        final Finder traktTile = find.ancestor(
          of: find.text('Trakt Import'),
          matching: find.byType(SettingsTile),
        );
        await tester.tap(traktTile);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('shows chevrons on tiles with onTap',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chevron_right), findsAtLeastNWidgets(3));
      });
    });

    group('Error handling', () {
      testWidgets('does not show error section by default',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -1500));
        await tester.pumpAndSettle();

        expect(find.text('ERROR'), findsNothing);
      });

      testWidgets('shows error section when errorMessage is set',
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
            child: const MaterialApp(
              localizationsDelegates: S.localizationsDelegates,
              supportedLocales: S.supportedLocales,
              home: MediaQuery(
                data: MediaQueryData(size: Size(400, 800)),
                child: BreadcrumbScope(
                  label: 'Settings',
                  child: SettingsScreen(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -1500));
        await tester.pumpAndSettle();

        expect(find.text('ERROR'), findsOneWidget);
        expect(find.text(errorMessage), findsOneWidget);
      });
    });

    group('Version', () {
      testWidgets('shows version placeholder before PackageInfo loads',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pump();

        expect(find.text('...'), findsOneWidget);
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
    ref.watch(sharedPreferencesProvider);
    return SettingsState(errorMessage: _errorMessage);
  }
}
