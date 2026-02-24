import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/features/settings/screens/cache_screen.dart';
import 'package:xerabora/features/settings/widgets/settings_section.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/widgets/breadcrumb_scope.dart';

void main() {
  group('CacheScreen', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'image_cache_enabled': false,
      });
      prefs = await SharedPreferences.getInstance();
    });

    Widget createWidget() {
      return ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: BreadcrumbScope(
            label: 'Settings',
            child: CacheScreen(),
          ),
        ),
      );
    }

    testWidgets('Показывает хлебные крошки Settings и Cache',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Cache'), findsOneWidget);
    });

    testWidgets('Показывает заголовок секции Image Cache',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Image Cache'), findsOneWidget);
      expect(find.byType(SettingsSection), findsOneWidget);
    });

    testWidgets('Показывает переключатель Offline mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Offline mode'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('Показывает метку Cache folder',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Cache folder'), findsOneWidget);
    });

    testWidgets('Показывает метку Cache size',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Cache size'), findsOneWidget);
    });

    testWidgets('Переключатель Offline mode имеет начальное значение false',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final Finder switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      final Switch switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, false);
    });

    testWidgets('Показывает иконки', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.folder), findsOneWidget);
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('Offline mode показывает subtitle',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Save images locally for offline use'),
        findsOneWidget,
      );
    });

    testWidgets('Показывает статистику кэша 0 files',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('0 files'), findsOneWidget);
    });
  });
}
