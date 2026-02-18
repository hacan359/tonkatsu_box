import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/features/settings/screens/credentials_screen.dart';
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
          home: CredentialsScreen(isInitialSetup: isInitialSetup),
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

    group('IGDB секция', () {
      testWidgets('должен показывать заголовок IGDB API Credentials',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('IGDB API Credentials'), findsOneWidget);
      });

      testWidgets('должен показывать поле Client ID',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Client ID'), findsOneWidget);
        expect(
          find.widgetWithText(TextField, 'Client ID'),
          findsOneWidget,
        );
      });

      testWidgets('должен показывать поле Client Secret',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Client Secret'), findsOneWidget);
        expect(
          find.widgetWithText(TextField, 'Client Secret'),
          findsOneWidget,
        );
      });

      testWidgets('должен показывать SourceBadge для IGDB',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder sourceBadges = find.byType(SourceBadge);
        expect(sourceBadges, findsAtLeastNWidgets(1));

        // Проверяем, что есть бейдж IGDB
        final List<SourceBadge> badges =
            tester.widgetList<SourceBadge>(sourceBadges).toList();
        expect(
          badges.any((SourceBadge badge) => badge.source == DataSource.igdb),
          isTrue,
        );
      });

      testWidgets('должен позволять вводить Client ID',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder clientIdField = find.widgetWithText(TextField, 'Client ID');
        await tester.enterText(clientIdField, 'test_client_id');

        expect(find.text('test_client_id'), findsOneWidget);
      });

      testWidgets('должен позволять вводить Client Secret',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder secretField =
            find.widgetWithText(TextField, 'Client Secret');
        await tester.enterText(secretField, 'test_secret');

        // Текст скрыт, но виджет содержит значение
        final TextField textField = tester.widget<TextField>(secretField);
        expect(textField.controller?.text, equals('test_secret'));
      });

      testWidgets('должен скрывать Client Secret по умолчанию',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final Finder secretField =
            find.widgetWithText(TextField, 'Client Secret');
        final TextField textField = tester.widget<TextField>(secretField);
        expect(textField.obscureText, isTrue);
      });

      testWidgets('должен переключать видимость Client Secret',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Изначально пароль скрыт
        Finder secretField = find.widgetWithText(TextField, 'Client Secret');
        TextField textField = tester.widget<TextField>(secretField);
        expect(textField.obscureText, isTrue);

        // Нажимаем на первую иконку видимости (Client Secret)
        await tester.tap(find.byIcon(Icons.visibility).first);
        await tester.pumpAndSettle();

        // Теперь пароль виден
        secretField = find.widgetWithText(TextField, 'Client Secret');
        textField = tester.widget<TextField>(secretField);
        expect(textField.obscureText, isFalse);
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

      testWidgets('должен показывать поле API Key для SteamGridDB',
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
          badges.any((SourceBadge badge) => badge.source == DataSource.steamGridDb),
          isTrue,
        );
      });

      testWidgets('должен показывать кнопку Save для SteamGridDB',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('SteamGridDB API'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.text('Save'), findsAtLeastNWidgets(1));
      });

      testWidgets('должен скрывать SteamGridDB API Key по умолчанию',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('SteamGridDB API'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        // Находим текстовое поле в SteamGridDB секции
        final List<TextField> textFields =
            tester.widgetList<TextField>(find.byType(TextField)).toList();
        // Client ID, Client Secret, SteamGridDB Key, TMDB Key = 4
        expect(textFields.length, greaterThanOrEqualTo(3));

        // SteamGridDB ключ - третий TextField
        final TextField steamGridField = textFields[2];
        expect(steamGridField.obscureText, isTrue);
      });

      testWidgets('должен переключать видимость SteamGridDB API Key',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('SteamGridDB API'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        // Находим все иконки visibility
        final List<Icon> visibilityIcons =
            tester.widgetList<Icon>(find.byIcon(Icons.visibility)).toList();

        // SteamGridDB visibility icon - второй (после Client Secret)
        expect(visibilityIcons.length, greaterThanOrEqualTo(2));

        // Нажимаем на вторую иконку видимости (SteamGridDB)
        await tester.tap(find.byIcon(Icons.visibility).at(1));
        await tester.pumpAndSettle();

        // Проверяем что иконка изменилась на visibility_off
        final List<TextField> textFields =
            tester.widgetList<TextField>(find.byType(TextField)).toList();
        final TextField steamGridField = textFields[2];
        expect(steamGridField.obscureText, isFalse);
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

      testWidgets('должен показывать поле API Key для TMDB',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('TMDB API (Movies & TV)'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        // API Key label встречается для SteamGridDB и TMDB
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

      testWidgets('должен показывать кнопку Save для TMDB',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('TMDB API (Movies & TV)'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        // Save встречается для SteamGridDB и TMDB
        expect(find.text('Save'), findsAtLeastNWidgets(2));
      });

      testWidgets('должен скрывать TMDB API Key по умолчанию',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('TMDB API (Movies & TV)'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        // Находим все текстовые поля
        final List<TextField> textFields =
            tester.widgetList<TextField>(find.byType(TextField)).toList();
        // Client ID, Client Secret, SteamGridDB Key, TMDB Key = 4
        expect(textFields.length, equals(4));

        // TMDB ключ - четвёртый TextField
        final TextField tmdbField = textFields[3];
        expect(tmdbField.obscureText, isTrue);
      });

      testWidgets('должен переключать видимость TMDB API Key',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('TMDB API (Movies & TV)'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        // Нажимаем на третью иконку видимости (TMDB)
        await tester.tap(find.byIcon(Icons.visibility).at(2));
        await tester.pumpAndSettle();

        // Проверяем что obscureText изменился
        final List<TextField> textFields =
            tester.widgetList<TextField>(find.byType(TextField)).toList();
        final TextField tmdbField = textFields[3];
        expect(tmdbField.obscureText, isFalse);
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
        expect(find.text('0'), findsOneWidget);
      });

      testWidgets('должен показывать иконку статуса',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // По умолчанию статус unknown - иконка help_outline
        // Проверяем что есть хотя бы одна иконка
        expect(find.byIcon(Icons.help_outline), findsAtLeastNWidgets(1));
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

        // Мокаем clipboard
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

      testWidgets('должен загружать Client Secret из SharedPreferences',
          (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'igdb_client_secret': 'existing_secret',
        });
        prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        // Secret скрыт, проверяем через контроллер
        final Finder secretField =
            find.widgetWithText(TextField, 'Client Secret');
        final TextField textField = tester.widget<TextField>(secretField);
        expect(textField.controller?.text, equals('existing_secret'));
      });

      testWidgets('должен загружать SteamGridDB API Key из SharedPreferences',
          (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'steamgriddb_api_key': 'existing_sgdb_key',
        });
        prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('SteamGridDB API'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        // Проверяем через контроллер (ключ скрыт)
        final List<TextField> textFields =
            tester.widgetList<TextField>(find.byType(TextField)).toList();
        final TextField steamGridField = textFields[2];
        expect(steamGridField.controller?.text, equals('existing_sgdb_key'));
      });

      testWidgets('должен загружать TMDB API Key из SharedPreferences',
          (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'tmdb_api_key': 'existing_tmdb_key',
        });
        prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('TMDB API (Movies & TV)'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        // Проверяем через контроллер (ключ скрыт)
        final List<TextField> textFields =
            tester.widgetList<TextField>(find.byType(TextField)).toList();
        final TextField tmdbField = textFields[3];
        expect(tmdbField.controller?.text, equals('existing_tmdb_key'));
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

        // Проверяем Client ID
        expect(find.text('full_client_id'), findsOneWidget);

        // Проверяем Client Secret через контроллер
        final Finder secretField =
            find.widgetWithText(TextField, 'Client Secret');
        final TextField secretTextField = tester.widget<TextField>(secretField);
        expect(secretTextField.controller?.text, equals('full_secret'));

        // Скроллим до остальных полей
        await tester.scrollUntilVisible(
          find.text('TMDB API (Movies & TV)'),
          200,
          scrollable: find.byType(Scrollable).first,
        );

        // Проверяем все текстовые поля
        final List<TextField> textFields =
            tester.widgetList<TextField>(find.byType(TextField)).toList();
        expect(textFields[2].controller?.text, equals('full_sgdb_key'));
        expect(textFields[3].controller?.text, equals('full_tmdb_key'));
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
