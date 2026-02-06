import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/features/settings/screens/settings_screen.dart';

void main() {
  group('SettingsScreen', () {
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
          home: SettingsScreen(isInitialSetup: isInitialSetup),
        ),
      );
    }

    testWidgets('должен показывать заголовок', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('IGDB API Setup'), findsOneWidget);
    });

    testWidgets('должен показывать поля ввода credentials',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Client ID'), findsOneWidget);
      expect(find.text('Client Secret'), findsOneWidget);
    });

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

    testWidgets('должен показывать секцию статуса', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Connection Status'), findsOneWidget);
      expect(find.text('Not Connected'), findsOneWidget);
    });

    testWidgets('должен показывать Welcome секцию при isInitialSetup=true',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget(isInitialSetup: true));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to xeRAbora!'), findsOneWidget);
    });

    testWidgets('должен скрывать Welcome секцию при isInitialSetup=false',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget(isInitialSetup: false));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to xeRAbora!'), findsNothing);
    });

    testWidgets('должен скрывать кнопку назад при isInitialSetup=true',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget(isInitialSetup: true));
      await tester.pumpAndSettle();

      expect(find.byType(BackButton), findsNothing);
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

    testWidgets('должен переключать видимость пароля',
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

    testWidgets('должен показывать количество платформ',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Platforms synced: '), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('Refresh Platforms должен быть отключен без API key',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final Finder button = find.widgetWithText(OutlinedButton, 'Refresh Platforms');
      final OutlinedButton widget = tester.widget<OutlinedButton>(button);

      expect(widget.onPressed, isNull);
    });

    testWidgets('должен загружать существующие credentials',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'igdb_client_id': 'existing_client_id',
        'igdb_client_secret': 'existing_secret',
      });
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('existing_client_id'), findsOneWidget);

      // Secret скрыт, проверяем через контроллер
      final Finder secretField =
          find.widgetWithText(TextField, 'Client Secret');
      final TextField textField = tester.widget<TextField>(secretField);
      expect(textField.controller?.text, equals('existing_secret'));
    });
  });
}
