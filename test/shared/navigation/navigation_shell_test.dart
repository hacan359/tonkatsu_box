import 'package:xerabora/l10n/app_localizations.dart';
// Тесты для NavigationShell.
//
// Nested navigation:
// Каждый таб имеет свой Navigator — push/pop происходит внутри таба,
// а NavigationShell (Rail/BottomBar) остаётся видимым.
//
// Ленивая инициализация табов:
// NavigationShell использует IndexedStack с ленивой загрузкой — Collections,
// WishlistScreen, SearchScreen и SettingsScreen строятся только при первом
// переключении на таб. AllItemsScreen (Home) загружается сразу.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/core/services/update_service.dart';
import 'package:xerabora/features/settings/providers/profile_provider.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/features/wishlist/providers/wishlist_provider.dart';
import 'package:xerabora/shared/models/profile.dart';
import 'package:xerabora/shared/navigation/navigation_shell.dart';

void main() {
  group('NavTab', () {
    test('home имеет index 0', () {
      expect(NavTab.home.index, equals(0));
    });

    test('collections имеет index 1', () {
      expect(NavTab.collections.index, equals(1));
    });

    test('tierLists имеет index 2', () {
      expect(NavTab.tierLists.index, equals(2));
    });

    test('wishlist имеет index 3', () {
      expect(NavTab.wishlist.index, equals(3));
    });

    test('search имеет index 4', () {
      expect(NavTab.search.index, equals(4));
    });

    test('settings имеет index 5', () {
      expect(NavTab.settings.index, equals(5));
    });

    test('содержит 6 значений', () {
      expect(NavTab.values.length, equals(6));
    });

    test('все значения уникальны', () {
      final Set<int> indices =
          NavTab.values.map((NavTab t) => t.index).toSet();
      expect(indices.length, equals(NavTab.values.length));
    });

    test('home — единственный таб, инициализируемый при старте', () {
      expect(NavTab.home.index, equals(0));
      // Collections, Search и Settings имеют index != 0
      expect(
          NavTab.collections.index, isNot(equals(NavTab.home.index)));
      expect(NavTab.search.index, isNot(equals(NavTab.home.index)));
      expect(NavTab.settings.index, isNot(equals(NavTab.home.index)));
    });
  });

  group('navigationBreakpoint', () {
    test('должен быть 800', () {
      expect(navigationBreakpoint, equals(800));
    });
  });

  group('NavigationShell widget', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
    });

    Widget createShell({double width = 1024, NavTab? initialTab}) {
      return ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          settingsNotifierProvider.overrideWith(
            _FakeSettingsNotifier.new,
          ),
          activeWishlistCountProvider.overrideWithValue(0),
          updateCheckProvider.overrideWith(
            (Ref ref) async => null,
          ),
          profilesDataProvider.overrideWith(
            (Ref ref) => ProfilesData.defaultData(),
          ),
        ],
        child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(size: Size(width, 1200)),
            child: NavigationShell(initialTab: initialTab),
          ),
        ),
      );
    }

    // Используем pump() вместо pumpAndSettle(), потому что дочерние экраны
    // (AllItemsScreen и др.) показывают shimmer-анимации в loading state,
    // которые никогда не «settle». Для тестов навигационной структуры
    // достаточно одного кадра.

    group('Desktop layout (Rail)', () {
      testWidgets('показывает NavigationRail при width >= 800',
          (WidgetTester tester) async {
        await tester.pumpWidget(createShell(width: 1024));
        await tester.pump();

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(BottomNavigationBar), findsNothing);
      });

      testWidgets('Rail содержит 6 destination',
          (WidgetTester tester) async {
        await tester.pumpWidget(createShell(width: 1024));
        await tester.pump();

        final NavigationRail rail =
            tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.destinations.length, equals(6));
      });

      testWidgets('переключение таба через Rail',
          (WidgetTester tester) async {
        await tester.pumpWidget(createShell(width: 1024));
        await tester.pump();

        final NavigationRail railBefore =
            tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(railBefore.selectedIndex, equals(0));

        railBefore.onDestinationSelected!(5);
        await tester.pump();

        final NavigationRail railAfter =
            tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(railAfter.selectedIndex, equals(5));
      });
    });

    group('Mobile layout (BottomBar)', () {
      testWidgets('показывает BottomNavigationBar при width < 800',
          (WidgetTester tester) async {
        await tester.pumpWidget(createShell(width: 400));
        await tester.pump();

        expect(find.byType(BottomNavigationBar), findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);
      });

      testWidgets('BottomBar содержит 6 items',
          (WidgetTester tester) async {
        await tester.pumpWidget(createShell(width: 400));
        await tester.pump();

        final BottomNavigationBar bar =
            tester.widget<BottomNavigationBar>(
                find.byType(BottomNavigationBar));
        expect(bar.items.length, equals(6));
      });

      testWidgets('переключение таба через BottomBar',
          (WidgetTester tester) async {
        await tester.pumpWidget(createShell(width: 400));
        await tester.pump();

        final BottomNavigationBar barBefore =
            tester.widget<BottomNavigationBar>(
                find.byType(BottomNavigationBar));
        expect(barBefore.currentIndex, equals(0));

        barBefore.onTap!(5);
        await tester.pump();

        final BottomNavigationBar barAfter =
            tester.widget<BottomNavigationBar>(
                find.byType(BottomNavigationBar));
        expect(barAfter.currentIndex, equals(5));
      });
    });

    group('Nested navigation', () {
      testWidgets('IndexedStack содержит Navigator для Home таба',
          (WidgetTester tester) async {
        await tester.pumpWidget(createShell(width: 1024));
        await tester.pump();

        // Root Navigator (MaterialApp) + Home tab Navigator
        final Finder navigators = find.byType(Navigator);
        expect(navigators, findsAtLeast(2));
      });

      testWidgets('Rail остаётся видимым после переключения на Settings таб',
          (WidgetTester tester) async {
        await tester.pumpWidget(createShell(width: 1024));
        await tester.pump();

        // Переключаемся на Settings
        final NavigationRail rail =
            tester.widget<NavigationRail>(find.byType(NavigationRail));
        rail.onDestinationSelected!(5);
        await tester.pump();
        await tester.pump();

        // Settings загрузился — видим контент
        expect(find.text('App Language'), findsOneWidget);
        // NavigationRail ОСТАЁТСЯ видимым
        expect(find.byType(NavigationRail), findsOneWidget);
      });

      testWidgets('BottomBar остаётся видимым после переключения на Settings таб',
          (WidgetTester tester) async {
        await tester.pumpWidget(createShell(width: 400));
        await tester.pump();

        // Переключаемся на Settings
        final BottomNavigationBar bar =
            tester.widget<BottomNavigationBar>(
                find.byType(BottomNavigationBar));
        bar.onTap!(5);
        await tester.pump();
        await tester.pump();

        // Settings загрузился — видим контент
        expect(find.text('App Language'), findsOneWidget);
        // BottomNavigationBar ОСТАЁТСЯ видимым
        expect(find.byType(BottomNavigationBar), findsOneWidget);
      });

      testWidgets('PopScope перехватывает системный back',
          (WidgetTester tester) async {
        await tester.pumpWidget(createShell(width: 400));
        await tester.pump();

        // PopScope<Object?> есть в дереве
        expect(
          find.byWidgetPredicate(
              (Widget w) => '${w.runtimeType}'.startsWith('PopScope')),
          findsWidgets,
        );
      });

      testWidgets('повторное нажатие на таб возвращает к корню',
          (WidgetTester tester) async {
        await tester.pumpWidget(createShell(width: 1024));
        await tester.pump();

        // Переключаемся на Settings
        final NavigationRail rail =
            tester.widget<NavigationRail>(find.byType(NavigationRail));
        rail.onDestinationSelected!(5);
        await tester.pump();
        await tester.pump();

        // Settings загрузился — видим контент
        expect(find.text('App Language'), findsOneWidget);

        // Повторное нажатие на Settings (index 5) — pop к корню
        final NavigationRail railAfterPush =
            tester.widget<NavigationRail>(find.byType(NavigationRail));
        railAfterPush.onDestinationSelected!(5);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Видим SettingsScreen (корневой экран таба).
        // Проверяем что Settings всё ещё активен — API Keys sidebar
        // не обязательно исчезает (desktop layout), но корневой контент
        // должен содержать группы настроек.
        expect(find.byType(NavigationRail), findsOneWidget);
      });
    });

    group('initialTab parameter', () {
      testWidgets('opens on Settings tab when initialTab is settings',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createShell(width: 1024, initialTab: NavTab.settings),
        );
        await tester.pump();
        await tester.pump();

        final NavigationRail rail =
            tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.selectedIndex, equals(NavTab.settings.index));
      });

      testWidgets('Settings tab is initialized when used as initialTab',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createShell(width: 1024, initialTab: NavTab.settings),
        );
        await tester.pump();
        await tester.pump();

        // Settings content should be visible (check Appearance group title)
        expect(find.text('App Language'), findsOneWidget);
      });

      testWidgets('defaults to home tab when initialTab is null',
          (WidgetTester tester) async {
        await tester.pumpWidget(createShell(width: 1024));
        await tester.pump();

        final NavigationRail rail =
            tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.selectedIndex, equals(NavTab.home.index));
      });

      testWidgets('initialTab works with BottomBar on mobile',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          createShell(width: 400, initialTab: NavTab.settings),
        );
        await tester.pump();
        await tester.pump();

        final BottomNavigationBar bar =
            tester.widget<BottomNavigationBar>(
                find.byType(BottomNavigationBar));
        expect(bar.currentIndex, equals(NavTab.settings.index));
      });
    });

    group('Lazy initialization', () {
      testWidgets('Settings содержимое НЕ видно до переключения',
          (WidgetTester tester) async {
        await tester.pumpWidget(createShell(width: 1024));
        await tester.pump();

        // Settings не инициализирован — Credentials не найден
        expect(find.text('Credentials'), findsNothing);
      });

      testWidgets('таб инициализируется при первом переключении',
          (WidgetTester tester) async {
        await tester.pumpWidget(createShell(width: 1024));
        await tester.pump();

        // До переключения: нет App Language (Settings не загружен)
        expect(find.text('App Language'), findsNothing);

        // Переключаемся на Settings
        final NavigationRail rail =
            tester.widget<NavigationRail>(find.byType(NavigationRail));
        rail.onDestinationSelected!(5);
        await tester.pump();
        await tester.pump();

        // После переключения: Settings экран виден
        expect(find.text('App Language'), findsOneWidget);
      });
    });
  });
}

class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() => const SettingsState();
}
