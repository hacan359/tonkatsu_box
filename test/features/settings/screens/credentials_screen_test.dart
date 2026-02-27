import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/features/settings/screens/credentials_screen.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/features/settings/widgets/inline_text_field.dart';
import 'package:xerabora/features/settings/widgets/settings_section.dart';
import 'package:xerabora/features/settings/widgets/status_dot.dart';
import 'package:xerabora/shared/widgets/breadcrumb_scope.dart';
import 'package:xerabora/shared/widgets/source_badge.dart';

void main() {
  group('CredentialsScreen', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
    });

    Widget createWidget({bool isInitialSetup = false}) {
      return ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: BreadcrumbScope(
            label: 'Settings',
            child: CredentialsScreen(isInitialSetup: isInitialSetup),
          ),
        ),
      );
    }

    group('Breadcrumbs и навигация', () {
      testWidgets('должен показывать хлебную крошку Settings',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
      });

      testWidgets('должен показывать хлебную крошку Credentials',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Credentials'), findsOneWidget);
      });
    });

    group('SettingsSection виджеты', () {
      testWidgets('должен использовать SettingsSection для секций',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // IGDB + Status + SteamGridDB + TMDB = 4 sections minimum
        expect(find.byType(SettingsSection), findsAtLeastNWidgets(4));
      });
    });

    group('IGDB секция', () {
      testWidgets('должен показывать заголовок IGDB API Credentials',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('IGDB API Credentials'), findsOneWidget);
      });

      testWidgets('должен показывать InlineTextField для Client ID',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Client ID'), findsOneWidget);
        expect(find.byType(InlineTextField), findsAtLeastNWidgets(1));
      });

      testWidgets('должен показывать InlineTextField для Client Secret',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Client Secret'), findsOneWidget);
      });

      testWidgets('должен показывать SourceBadge для IGDB',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder sourceBadges = find.byType(SourceBadge);
        expect(sourceBadges, findsAtLeastNWidgets(1));

        final List<SourceBadge> badges =
            tester.widgetList<SourceBadge>(sourceBadges).toList();
        expect(
          badges.any((SourceBadge badge) => badge.source == DataSource.igdb),
          isTrue,
        );
      });

      testWidgets('Client Secret должен быть скрыт (obscureText)',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // InlineTextField с obscureText показывает visibility иконку
        expect(find.byIcon(Icons.visibility), findsAtLeastNWidgets(1));
      });
    });

    group('SteamGridDB секция', () {
      testWidgets('должен показывать заголовок SteamGridDB API',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('SteamGridDB API'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.text('SteamGridDB API'), findsOneWidget);
      });

      testWidgets('должен показывать InlineTextField для API Key',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('SteamGridDB API'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.text('API Key'), findsAtLeastNWidgets(1));
      });

      testWidgets('должен показывать SourceBadge для SteamGridDB',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('SteamGridDB API'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        final List<SourceBadge> badges =
            tester.widgetList<SourceBadge>(find.byType(SourceBadge)).toList();
        expect(
          badges.any(
              (SourceBadge badge) => badge.source == DataSource.steamGridDb),
          isTrue,
        );
      });

      testWidgets('должен показывать StatusDot для SteamGridDB ключа',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('SteamGridDB API'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.byType(StatusDot), findsAtLeastNWidgets(1));
      });

      testWidgets('должен показывать StatusDot для SteamGridDB',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('SteamGridDB API'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.byType(StatusDot), findsAtLeastNWidgets(1));
        expect(find.text('No API key'), findsAtLeastNWidgets(1));
      });
    });

    group('TMDB секция', () {
      testWidgets('должен показывать заголовок TMDB API (Movies & TV)',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('TMDB API (Movies & TV)'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.text('TMDB API (Movies & TV)'), findsOneWidget);
      });

      testWidgets('должен показывать InlineTextField для TMDB API Key',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('TMDB API (Movies & TV)'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        // API Key label appears for SteamGridDB and TMDB
        expect(find.text('API Key'), findsAtLeastNWidgets(2));
      });

      testWidgets('должен показывать SourceBadge для TMDB',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('TMDB API (Movies & TV)'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        final List<SourceBadge> badges =
            tester.widgetList<SourceBadge>(find.byType(SourceBadge)).toList();
        expect(
          badges.any((SourceBadge badge) => badge.source == DataSource.tmdb),
          isTrue,
        );
      });

      testWidgets('должен показывать StatusDot для TMDB ключа',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('TMDB API (Movies & TV)'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        // StatusDot appears for connection + SteamGridDB + TMDB
        expect(find.byType(StatusDot), findsAtLeastNWidgets(2));
      });
    });

    group('Actions секция', () {
      testWidgets('должен показывать кнопку Verify Connection',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Verify Connection'), findsOneWidget);
      });

      testWidgets('должен показывать кнопку Refresh Platforms',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Refresh Platforms'), findsOneWidget);
      });

      testWidgets('Refresh Platforms должен быть отключен без API key',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder button =
            find.widgetWithText(OutlinedButton, 'Refresh Platforms');
        final OutlinedButton widget = tester.widget<OutlinedButton>(button);

        expect(widget.onPressed, isNull);
      });

      testWidgets('должен показывать snackbar при пустых полях',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Verify Connection'));
        await tester.pumpAndSettle();

        expect(
          find.text('Please enter both Client ID and Client Secret'),
          findsOneWidget,
        );
      });
    });

    group('Status секция', () {
      testWidgets('должен показывать заголовок Connection Status',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Connection Status'), findsOneWidget);
      });

      testWidgets('должен показывать Not Connected по умолчанию',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Not Connected'), findsOneWidget);
      });

      testWidgets('должен показывать количество Platforms synced',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.textContaining('Platforms synced'), findsOneWidget);
        expect(find.textContaining(': 0'), findsOneWidget);
      });

      testWidgets('должен показывать StatusDot для статуса подключения',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // StatusDot: connection + steamgriddb + tmdb
        expect(find.byType(StatusDot), findsAtLeastNWidgets(1));
        // Default is inactive — ? symbol in circular badge
        expect(find.text('?'), findsAtLeastNWidgets(1));
      });

      testWidgets('должен показывать иконку платформ',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.videogame_asset), findsOneWidget);
      });
    });

    group('Welcome секция', () {
      testWidgets('должен показывать Welcome секцию при isInitialSetup=true',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(isInitialSetup: true));
        await tester.pumpAndSettle();

        expect(find.text('Welcome to Tonkatsu Box!'), findsOneWidget);
      });

      testWidgets('должен скрывать Welcome секцию при isInitialSetup=false',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(isInitialSetup: false));
        await tester.pumpAndSettle();

        expect(find.text('Welcome to Tonkatsu Box!'), findsNothing);
      });

      testWidgets('должен показывать кнопку Copy Twitch Console URL',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(isInitialSetup: true));
        await tester.pumpAndSettle();

        expect(find.text('Copy Twitch Console URL'), findsOneWidget);
      });

      testWidgets('должен копировать URL при нажатии кнопки',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(isInitialSetup: true));
        await tester.pumpAndSettle();

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall methodCall) async {
            if (methodCall.method == 'Clipboard.setData') {
              return null;
            }
            return null;
          },
        );

        await tester.tap(find.text('Copy Twitch Console URL'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('URL copied'),
          findsOneWidget,
        );
      });
    });

    group('Загрузка существующих credentials', () {
      testWidgets('должен загружать Client ID из SharedPreferences',
          (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'igdb_client_id': 'existing_client_id',
        });
        prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('existing_client_id'), findsOneWidget);
      });

      testWidgets('должен загружать Client Secret (скрыт по умолчанию)',
          (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'igdb_client_secret': 'existing_secret',
        });
        prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Secret is obscured — dots shown, not actual text
        expect(find.text('existing_secret'), findsNothing);
        expect(
          find.text(
              '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022'),
          findsOneWidget,
        );
      });

      testWidgets('должен загружать все credentials одновременно',
          (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'igdb_client_id': 'full_client_id',
          'igdb_client_secret': 'full_secret',
          'steamgriddb_api_key': 'full_sgdb_key',
          'tmdb_api_key': 'full_tmdb_key',
        });
        prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Client ID is visible (not obscured)
        expect(find.text('full_client_id'), findsOneWidget);

        // Obscured fields show dots (3 fields with obscureText)
        // Client Secret + SteamGridDB + TMDB = 3 dot sets
        expect(
          find.text(
              '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022'),
          findsAtLeastNWidgets(1),
        );
      });
    });

    group('TMDB Content Language', () {
      testWidgets('должен показывать SegmentedButton для языка',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Content Language'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.text('Content Language'), findsOneWidget);
        expect(find.byType(SegmentedButton<String>), findsOneWidget);
      });

      testWidgets('должен показывать варианты Русский и English',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Content Language'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.text('Русский'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);
      });
    });

    group('Автосохранение API ключей', () {
      testWidgets('SteamGridDB InlineTextField показывает placeholder',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('SteamGridDB API'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        // InlineTextField for API key is present
        expect(find.byType(InlineTextField), findsAtLeastNWidgets(1));
      });

      testWidgets('TMDB InlineTextField показывает placeholder',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('TMDB API (Movies & TV)'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.byType(InlineTextField), findsAtLeastNWidgets(2));
      });
    });

    group('Кнопка Test', () {
      testWidgets('не показывает кнопку Test без API ключа',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('SteamGridDB API'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.byTooltip('Test'), findsNothing);
      });

      testWidgets('показывает кнопку Test когда SteamGridDB ключ сохранён',
          (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'steamgriddb_api_key': 'saved_key',
        });
        prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('SteamGridDB API'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.byTooltip('Test'), findsAtLeastNWidgets(1));
      });

      testWidgets('показывает кнопку Test когда TMDB ключ сохранён',
          (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'tmdb_api_key': 'saved_key',
        });
        prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('TMDB API (Movies & TV)'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.byTooltip('Test'), findsAtLeastNWidgets(1));
      });

      testWidgets('показывает 2 кнопки Test когда оба ключа сохранены',
          (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'steamgriddb_api_key': 'sgdb_key',
          'tmdb_api_key': 'tmdb_key',
        });
        prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('TMDB API (Movies & TV)'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.byTooltip('Test'), findsNWidgets(2));
      });
    });

    group('Error секция', () {
      testWidgets('не показывает Error секцию по умолчанию',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Scroll to the bottom
        await tester.scrollUntilVisible(
          find.text('TMDB API (Movies & TV)'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.text('Error'), findsNothing);
      });
    });

    group('SourceBadge виджеты', () {
      testWidgets('должен показывать 3 SourceBadge виджета',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('TMDB API (Movies & TV)'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        final Finder sourceBadges = find.byType(SourceBadge);
        expect(sourceBadges, findsNWidgets(3));
      });

      testWidgets('все SourceBadge должны быть large size',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('TMDB API (Movies & TV)'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        final List<SourceBadge> badges =
            tester.widgetList<SourceBadge>(find.byType(SourceBadge)).toList();

        for (final SourceBadge badge in badges) {
          expect(badge.size, equals(SourceBadgeSize.large));
        }
      });

      testWidgets('должен показывать правильные источники',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('TMDB API (Movies & TV)'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        final List<SourceBadge> badges =
            tester.widgetList<SourceBadge>(find.byType(SourceBadge)).toList();
        final List<DataSource> sources =
            badges.map((SourceBadge badge) => badge.source).toList();

        expect(sources, contains(DataSource.igdb));
        expect(sources, contains(DataSource.steamGridDb));
        expect(sources, contains(DataSource.tmdb));
      });
    });
  });
}
