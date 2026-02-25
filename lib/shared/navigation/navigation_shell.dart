// Адаптивная оболочка навигации приложения.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/collections/screens/home_screen.dart';
import '../../features/home/screens/all_items_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/wishlist/providers/wishlist_provider.dart';
import '../../features/wishlist/screens/wishlist_screen.dart';
import '../gamepad/gamepad_action.dart';
import '../gamepad/widgets/gamepad_listener.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../widgets/breadcrumb_scope.dart';
import '../widgets/update_banner.dart';
import '../../l10n/app_localizations.dart';

/// Порог ширины для переключения NavigationRail ↔ BottomNavigationBar.
const double navigationBreakpoint = 800;

/// Количество основных табов.
const int _tabCount = 5;

/// Индексы вкладок навигации.
enum NavTab {
  /// Домашний экран (все элементы).
  home,

  /// Коллекции.
  collections,

  /// Вишлист (заметки для поиска).
  wishlist,

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
  ///
  /// [initialTab] позволяет открыть приложение на конкретном табе
  /// (например, Settings после Welcome Wizard).
  const NavigationShell({this.initialTab, super.key});

  /// Начальный таб при открытии. Если null — [NavTab.home].
  final NavTab? initialTab;

  @override
  ConsumerState<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends ConsumerState<NavigationShell> {
  late int _selectedIndex = widget.initialTab?.index ?? NavTab.home.index;

  /// Табы, которые уже были посещены и инициализированы.
  ///
  /// HomeScreen строится сразу, остальные — при первом переключении.
  /// Это предотвращает тяжёлую инициализацию SearchScreen (4 DB-запроса,
  /// загрузка платформ) и SettingsScreen при старте приложения.
  late final Set<int> _initializedTabs = <int>{
    NavTab.home.index,
    if (widget.initialTab != null) widget.initialTab!.index,
  };

  /// Ключи Navigator для каждого таба (nested navigation).
  ///
  /// Каждый таб имеет свой Navigator — push/pop происходит внутри таба,
  /// а NavigationShell (Rail/BottomBar) остаётся видимым.
  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List<GlobalKey<NavigatorState>>.generate(
    _tabCount,
    (_) => GlobalKey<NavigatorState>(),
  );

  /// Кэшированные Navigator-виджеты для каждого таба.
  ///
  /// При смене локали MaterialApp перестраивает всё дерево.
  /// Без кэша каждый вызов [_buildTabNavigator] создаёт новый
  /// экземпляр Navigator, что может привести к потере истории
  /// маршрутов (`_history.isNotEmpty` assertion).
  /// Кэширование гарантирует, что Flutter получает тот же widget instance
  /// и не трогает NavigatorState.
  final List<Widget?> _navigatorWidgets =
      List<Widget?>.filled(_tabCount, null);

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
          body: useRail
              ? _buildRailLayout()
              : Column(
                  children: <Widget>[
                    Expanded(child: _buildContent()),
                    const UpdateBanner(),
                  ],
                ),
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
                indicatorColor: AppColors.brand.withAlpha(30),
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
                destinations: <NavigationRailDestination>[
                  NavigationRailDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home),
                    label: Text(S.of(context).navMain),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.shelves),
                    selectedIcon: const Icon(Icons.shelves),
                    label: Text(S.of(context).navCollections),
                  ),
                  NavigationRailDestination(
                    icon: _buildWishlistIcon(Icons.bookmark_border),
                    selectedIcon: _buildWishlistIcon(Icons.bookmark),
                    label: Text(S.of(context).navWishlist),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.search_outlined),
                    selectedIcon: const Icon(Icons.search),
                    label: Text(S.of(context).navSearch),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.settings_outlined),
                    selectedIcon: const Icon(Icons.settings),
                    label: Text(S.of(context).navSettings),
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
        Expanded(
          child: Column(
            children: <Widget>[
              Expanded(child: _buildContent()),
              const UpdateBanner(),
            ],
          ),
        ),
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
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          label: S.of(context).navMain,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.shelves),
          activeIcon: const Icon(Icons.shelves),
          label: S.of(context).navCollections,
        ),
        BottomNavigationBarItem(
          icon: _buildWishlistIcon(Icons.bookmark_border),
          activeIcon: _buildWishlistIcon(Icons.bookmark),
          label: S.of(context).navWishlist,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.search_outlined),
          activeIcon: const Icon(Icons.search),
          label: S.of(context).navSearch,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings_outlined),
          activeIcon: const Icon(Icons.settings),
          label: S.of(context).navSettings,
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
    final String tabLabel = switch (NavTab.values[tabIndex]) {
      NavTab.home => S.of(context).navMain,
      NavTab.collections => S.of(context).navCollections,
      NavTab.wishlist => S.of(context).navWishlist,
      NavTab.search => S.of(context).navSearch,
      NavTab.settings => S.of(context).navSettings,
    };

    // Кэшируем Navigator — тот же widget instance при rebuild
    // гарантирует, что Flutter не пересоздаёт NavigatorState
    // и не теряет историю маршрутов.
    _navigatorWidgets[tabIndex] ??= Navigator(
      key: _navigatorKeys[tabIndex],
      onGenerateRoute: (RouteSettings settings) {
        final Widget screen = switch (NavTab.values[tabIndex]) {
          NavTab.home => const AllItemsScreen(),
          NavTab.collections => const HomeScreen(),
          NavTab.wishlist => const WishlistScreen(),
          NavTab.search => const SearchScreen(),
          NavTab.settings => const SettingsScreen(),
        };
        return MaterialPageRoute<void>(
          builder: (BuildContext context) => screen,
        );
      },
    );

    return BreadcrumbScope(
      label: tabLabel,
      child: _navigatorWidgets[tabIndex]!,
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

  Widget _buildWishlistIcon(IconData icon) {
    final int count = ref.watch(activeWishlistCountProvider);
    if (count == 0) {
      return Icon(icon);
    }
    return Badge(
      label: Text('$count'),
      child: Icon(icon),
    );
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
