// Тесты для SettingsScreen — логика, навигация, состояние.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/core/services/api_key_initializer.dart';
import 'package:xerabora/core/api/ra_api.dart';
import 'package:xerabora/core/services/discord_rpc_service.dart';

import '../../../helpers/mocks.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/features/settings/providers/profile_provider.dart';
import 'package:xerabora/features/settings/screens/settings_screen.dart';
import 'package:xerabora/features/settings/widgets/settings_tile.dart';
import 'package:xerabora/shared/models/profile.dart';
import 'package:xerabora/l10n/app_localizations.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  Widget createWidget({double width = 400, double height = 2000}) {
    return ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        apiKeysProvider.overrideWithValue(const ApiKeys()),
        profilesDataProvider.overrideWith(
          (Ref ref) => ProfilesData.defaultData(),
        ),
        discordRpcServiceProvider.overrideWithValue(MockDiscordRpcService()),
        raApiProvider.overrideWithValue(MockRaApi()),
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, height)),
          child: const SettingsScreen(),
        ),
      ),
    );
  }

  /// Скроллит ListView до элемента с текстом [text] и возвращает Finder.
  Future<Finder> scrollTo(WidgetTester tester, String text) async {
    final Finder finder = find.text(text);
    await tester.scrollUntilVisible(finder, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    return finder;
  }

  group('SettingsScreen', () {
    group('Layout', () {
      testWidgets('renders without errors', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('wide layout constrains content width',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(width: 1200));
        await tester.pumpAndSettle();

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
      testWidgets('tapping App Language opens picker dialog',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Appearance секция теперь ниже Data-секций — скроллим до него.
        await tester.scrollUntilVisible(
          find.text('App Language'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('App Language'), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.byType(SimpleDialog), findsOneWidget);
      });

      testWidgets('tapping Content Language opens picker dialog',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Content Language'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Content Language'), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.byType(SimpleDialog), findsOneWidget);
      });
    });

    group('Profile section', () {
      testWidgets('shows custom author name from SharedPreferences',
          (WidgetTester tester) async {
        await prefs.setString(SettingsKeys.defaultAuthor, 'Hacan');

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Hacan'), findsOneWidget);
      });
    });

    group('Navigation', () {
      testWidgets('Database tile navigates without crash',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await scrollTo(tester, 'Database');
        final Finder databaseTile = find.ancestor(
          of: find.text('Database'),
          matching: find.byType(SettingsTile),
        );
        await tester.tap(databaseTile);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('Trakt Import tile navigates without crash',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await scrollTo(tester, 'Trakt Import');
        final Finder traktTile = find.ancestor(
          of: find.text('Trakt Import'),
          matching: find.byType(SettingsTile),
        );
        await tester.tap(traktTile);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });

    // Error-секция удалена в v0.28 (ошибки логируются + показываются
    // SnackBar'ом, отдельная группа не нужна).

    group('Version', () {
      testWidgets('shows version placeholder before PackageInfo loads',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        await scrollTo(tester, '...');
        expect(find.text('...'), findsWidgets);
      });
    });
  });
}

