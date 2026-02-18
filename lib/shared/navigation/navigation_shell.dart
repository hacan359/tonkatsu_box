// Адаптивная оболочка навигации приложения.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/collections/screens/home_screen.dart';
import '../../features/home/screens/all_items_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../gamepad/gamepad_action.dart';
import '../gamepad/widgets/gamepad_listener.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';

/// Порог ширины для переключения NavigationRail ↔ BottomNavigationBar.
const double navigationBreakpoint = 800;

/// Количество основных табов.
const int _tabCount = 4;

/// Индексы вкладок навигации.
enum NavTab {
  /// Домашний экран (все элементы).
  home,

  /// Коллекции.
  collections,

  /// Поиск.
  search,

  /// Настройки.
  settings,
}

/// Адаптивная оболочка навигации.
///
/// - `width >= 800`: NavigationRail слева (десктоп)
/// - `width < 800`: BottomNavigationBar снизу (мобильный)
///
/// Каждая вкладка имеет свой [Navigator] (nested navigation) — маршруты
/// пушатся ВНУТРИ таба, а Rail/BottomBar остаётся видимым.
/// Состояние каждого таба сохраняется через [IndexedStack].
///
/// Поддержка геймпада:
/// - D-pad — навигация фокуса между виджетами (DirectionalFocusIntent)
/// - A — активация фокусированного виджета (ActivateIntent)
/// - LB/RB — переключение между табами
/// - B — назад (pop внутри таба или переключение на Home)
class NavigationShell extends ConsumerStatefulWidget {
  /// Создаёт [NavigationShell].
  const NavigationShell({super.key});

  @override
  ConsumerState<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends ConsumerState<NavigationShell> {
  int _selectedIndex = NavTab.home.index;

  /// Табы, которые уже были посещены и инициализированы.
  ///
  /// HomeScreen строится сразу, остальные — при первом переключении.
  /// Это предотвращает тяжёлую инициализацию SearchScreen (4 DB-запроса,
  /// загрузка платформ) и SettingsScreen при старте приложения.
  final Set<int> _initializedTabs = <int>{NavTab.home.index};

  /// Ключи Navigator для каждого таба (nested navigation).
  ///
  /// Каждый таб имеет свой Navigator — push/pop происходит внутри таба,
  /// а NavigationShell (Rail/BottomBar) остаётся видимым.
  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List<GlobalKey<NavigatorState>>.generate(
    _tabCount,
    (_) => GlobalKey<NavigatorState>(),
  );

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool useRail = width >= navigationBreakpoint;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        // Android back: pop внутри таба → переключить на Home → выйти
        if (!_handleBack()) {
          SystemNavigator.pop();
        }
      },
      child: GamepadListener(
        onTabSwitch: _onGamepadTabSwitch,
        onNavigate: _onGamepadNavigate,
        onConfirm: _onGamepadConfirm,
        onScroll: _onGamepadScroll,
        onBack: () {
          _handleBack();
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: useRail ? _buildRailLayout() : _buildContent(),
          bottomNavigationBar: useRail ? null : _buildBottomNav(),
        ),
      ),
    );
  }

  Widget _buildRailLayout() {
    return Row(
      children: <Widget>[
        ColoredBox(
          color: AppColors.surface,
          child: Column(
            children: <Widget>[
              // Логотип выше NavigationRail — всегда виден
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Image.asset(
                  AppAssets.logo,
                  width: 48,
                  height: 48,
                ),
              ),
              Expanded(
                child: NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onDestinationSelected,
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
                destinations: const <NavigationRailDestination>[
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: Text('Main'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.collections_bookmark_outlined),
                    selectedIcon: Icon(Icons.collections_bookmark),
                    label: Text('Collections'),
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
            ),
          ],
          ),
        ),
        const VerticalDivider(
          thickness: 1,
          width: 1,
          color: AppColors.surfaceBorder,
        ),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onDestinationSelected,
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.textPrimary,
      unselectedItemColor: AppColors.textTertiary,
      type: BottomNavigationBarType.fixed,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Main',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.collections_bookmark_outlined),
          activeIcon: Icon(Icons.collections_bookmark),
          label: 'Collections',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          activeIcon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  Widget _buildContent() {
    return IndexedStack(
      index: _selectedIndex,
      children: List<Widget>.generate(_tabCount, (int index) {
        if (!_initializedTabs.contains(index)) {
          return const SizedBox.shrink();
        }
        return _buildTabNavigator(index);
      }),
    );
  }

  Widget _buildTabNavigator(int tabIndex) {
    final Widget screen = switch (NavTab.values[tabIndex]) {
      NavTab.home => const AllItemsScreen(),
      NavTab.collections => const HomeScreen(),
      NavTab.search => const SearchScreen(),
      NavTab.settings => const SettingsScreen(),
    };

    return Navigator(
      key: _navigatorKeys[tabIndex],
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute<void>(
          builder: (BuildContext context) => screen,
        );
      },
    );
  }

  void _onDestinationSelected(int index) {
    if (index == _selectedIndex) {
      // Повторное нажатие — вернуться к корню таба
      _navigatorKeys[index]
          .currentState
          ?.popUntil((Route<dynamic> route) => route.isFirst);
      return;
    }
    _initializedTabs.add(index);
    setState(() => _selectedIndex = index);
  }

  /// Обработка кнопки «назад» (Android back, Gamepad B).
  ///
  /// Возвращает `true`, если навигация обработана (pop в табе или
  /// переключение на Home). Возвращает `false`, если нужно выйти.
  bool _handleBack() {
    final NavigatorState? tabNav =
        _navigatorKeys[_selectedIndex].currentState;
    if (tabNav != null && tabNav.canPop()) {
      tabNav.pop();
      return true;
    }
    if (_selectedIndex != NavTab.home.index) {
      _onDestinationSelected(NavTab.home.index);
      return true;
    }
    return false;
  }

  void _onGamepadTabSwitch(GamepadAction action) {
    final int newIndex = action == GamepadAction.nextTab
        ? (_selectedIndex + 1) % _tabCount
        : (_selectedIndex - 1 + _tabCount) % _tabCount;
    _onDestinationSelected(newIndex);
  }

  /// D-pad → перемещение фокуса через DirectionalFocusIntent.
  ///
  /// Если ни один виджет ещё не в фокусе — фокусирует первый доступный.
  void _onGamepadNavigate(GamepadAction action) {
    final FocusNode? primaryFocus = FocusManager.instance.primaryFocus;
    final BuildContext? focusContext = primaryFocus?.context;

    if (focusContext == null) {
      // Ничего не сфокусировано — перейти к первому виджету
      FocusScope.of(context).nextFocus();
      return;
    }

    final TraversalDirection direction = switch (action) {
      GamepadAction.navigateUp => TraversalDirection.up,
      GamepadAction.navigateDown => TraversalDirection.down,
      GamepadAction.navigateLeft => TraversalDirection.left,
      GamepadAction.navigateRight => TraversalDirection.right,
      _ => TraversalDirection.down,
    };

    Actions.maybeInvoke(focusContext, DirectionalFocusIntent(direction));
  }

  /// A кнопка → активация фокусированного виджета (ActivateIntent).
  ///
  /// Для InkWell это вызовет onTap. Для Focus + Actions — зарегистрированный callback.
  void _onGamepadConfirm() {
    final BuildContext? focusContext =
        FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) return;

    Actions.maybeInvoke(focusContext, const ActivateIntent());
  }

  /// Left Stick → скролл через синтетический PointerScrollEvent.
  ///
  /// Работает как колесо мыши — не требует фокуса на виджете.
  /// Событие отправляется в центр экрана, Flutter направляет его
  /// к Scrollable под этой точкой.
  void _onGamepadScroll(GamepadAction action) {
    const double scrollAmount = 80.0;

    final double dy = switch (action) {
      GamepadAction.scrollUp => -scrollAmount,
      GamepadAction.scrollDown => scrollAmount,
      _ => 0.0,
    };
    final double dx = switch (action) {
      GamepadAction.scrollLeft => -scrollAmount,
      GamepadAction.scrollRight => scrollAmount,
      _ => 0.0,
    };

    if (dx == 0.0 && dy == 0.0) return;

    final Size size = MediaQuery.sizeOf(context);
    GestureBinding.instance.handlePointerEvent(
      PointerScrollEvent(
        position: Offset(size.width / 2, size.height / 2),
        scrollDelta: Offset(dx, dy),
      ),
    );
  }
}
