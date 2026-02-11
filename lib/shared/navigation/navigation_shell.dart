// Оболочка навигации приложения с NavigationRail.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/collections/screens/home_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../theme/app_colors.dart';

/// Индексы вкладок навигации.
enum NavTab {
  /// Домашний экран (коллекции).
  home,

  /// Поиск.
  search,

  /// Настройки.
  settings,
}

/// Оболочка навигации с NavigationRail.
///
/// Содержит боковую панель навигации (Home, Search, Settings)
/// и область контента. Каждая вкладка сохраняет своё состояние
/// через [IndexedStack].
class NavigationShell extends ConsumerStatefulWidget {
  /// Создаёт [NavigationShell].
  const NavigationShell({super.key});

  @override
  ConsumerState<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends ConsumerState<NavigationShell> {
  int _selectedIndex = NavTab.home.index;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: <Widget>[
          // Боковая навигация
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() => _selectedIndex = index);
            },
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.gameAccent.withAlpha(30),
            selectedIconTheme: const IconThemeData(
              color: AppColors.textPrimary,
            ),
            unselectedIconTheme: const IconThemeData(
              color: AppColors.textTertiary,
            ),
            selectedLabelTextStyle: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 16),
              child: Text(
                'xR',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: Text('Search'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          // Разделитель
          const VerticalDivider(
            thickness: 1,
            width: 1,
            color: AppColors.surfaceBorder,
          ),
          // Контент
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const <Widget>[
                HomeScreen(),
                SearchScreen(),
                SettingsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
