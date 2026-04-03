// Адаптивная оболочка навигации приложения.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/collections/screens/collection_screen.dart';
import '../../features/collections/screens/home_screen.dart';
import '../../features/home/screens/all_items_screen.dart';
import '../../features/collections/screens/item_detail_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/tier_lists/screens/tier_list_detail_screen.dart';
import '../../features/tier_lists/screens/tier_lists_screen.dart';
import '../../features/settings/providers/profile_provider.dart';
import '../../features/wishlist/providers/wishlist_provider.dart';
import '../../features/wishlist/screens/wishlist_screen.dart';
import '../gamepad/gamepad_action.dart';
import '../gamepad/widgets/gamepad_listener.dart';
import '../keyboard/keyboard_shortcuts.dart';
import '../keyboard/keyboard_shortcuts_dialog.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../core/services/update_service.dart';
import '../../l10n/app_localizations.dart';

/// Порог ширины для переключения NavigationRail ↔ BottomNavigationBar.
const double navigationBreakpoint = 800;

/// Количество основных табов.
const int _tabCount = 6;

/// Индексы вкладок навигации.
enum NavTab {
  /// Домашний экран (все элементы).
  home,

  /// Коллекции.
  collections,

  /// Тир-листы.
  tierLists,

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

  @override
  void dispose() {
    for (final FocusScopeNode node in _tabFocusScopeNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// FocusScopeNode для каждого таба — при фокусе на scope
  /// он автоматически перенаправляет фокус на autofocus-потомка.
  final List<FocusScopeNode> _tabFocusScopeNodes = List<FocusScopeNode>.generate(
    _tabCount,
    (int i) => FocusScopeNode(debugLabel: 'tab-$i-scope'),
  );

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
      child: CallbackShortcuts(
        bindings: buildGlobalShortcuts(
          onSwitchTab: _onDestinationSelected,
          onNextTab: () => _onDestinationSelected(
            (_selectedIndex + 1) % _tabCount,
          ),
          onPreviousTab: () => _onDestinationSelected(
            (_selectedIndex - 1 + _tabCount) % _tabCount,
          ),
          onBack: () => _handleBack(),
          onSearch: () => _onDestinationSelected(NavTab.search.index),
          onRefresh: _onRefresh,
          onShowHelp: () => KeyboardShortcutsDialog.show(
            context,
            screenGroups: _currentScreenShortcutGroups(),
          ),
        ),
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: Focus(
            autofocus: true,
            child: GamepadListener(
              onTabSwitch: _onGamepadTabSwitch,
              onNavigate: _onGamepadNavigate,
              onConfirm: _onGamepadConfirm,
              onContextMenu: _onGamepadContextMenu,
              onScroll: _onGamepadScroll,
              onBack: () {
                _handleBack();
              },
              child: Scaffold(
                body: useRail
                    ? _buildRailLayout()
                    : _buildContent(),
                bottomNavigationBar: useRail ? null : _buildBottomNav(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRailLayout() {
    return Row(
      children: <Widget>[
        ColoredBox(
          color: AppColors.surface,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // Если высоки недостаточно — скрываем labels чтобы избежать overflow
              final bool compact = constraints.maxHeight < 480;
              return Column(
                children: <Widget>[
                  // Логотип выше NavigationRail — всегда виден
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
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
                indicatorColor: AppColors.brand.withAlpha(40),
                indicatorShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
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
                labelType: compact
                    ? NavigationRailLabelType.selected
                    : NavigationRailLabelType.all,
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
                    icon: const Icon(Icons.leaderboard_outlined),
                    selectedIcon: const Icon(Icons.leaderboard),
                    label: Text(S.of(context).navTierLists),
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
                    icon: _buildSettingsIcon(Icons.settings_outlined),
                    selectedIcon: _buildSettingsIcon(Icons.settings),
                    label: Text(S.of(context).navSettings),
                  ),
                ],
              ),
            ),
          ],
          );
        },
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
      showSelectedLabels: false,
      showUnselectedLabels: false,
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
          icon: const Icon(Icons.leaderboard_outlined),
          activeIcon: const Icon(Icons.leaderboard),
          label: S.of(context).navTierLists,
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
          icon: _buildSettingsIcon(Icons.settings_outlined),
          activeIcon: _buildSettingsIcon(Icons.settings),
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
    // Кэшируем Navigator — тот же widget instance при rebuild
    // гарантирует, что Flutter не пересоздаёт NavigatorState
    // и не теряет историю маршрутов.
    _navigatorWidgets[tabIndex] ??= Navigator(
      key: _navigatorKeys[tabIndex],
      onGenerateRoute: (RouteSettings settings) {
        final Widget screen = switch (NavTab.values[tabIndex]) {
          NavTab.home => const AllItemsScreen(),
          NavTab.collections => const HomeScreen(),
          NavTab.tierLists => const TierListsScreen(),
          NavTab.wishlist => const WishlistScreen(),
          NavTab.search => const SearchScreen(),
          NavTab.settings => const SettingsScreen(),
        };
        return MaterialPageRoute<void>(
          builder: (BuildContext context) => screen,
        );
      },
    );

    return FocusScope(
      node: _tabFocusScopeNodes[tabIndex],
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
    // Явно фокусируем контент нового таба — ноды TTF/CallbackShortcuts
    // внутри таба являются потомками этого Focus и получат key events.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final FocusScopeNode scope = _tabFocusScopeNodes[index];
      scope.requestFocus();
      // Фокус сразу на первый элемент контента (для геймпада)
      scope.nextFocus();
    });
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

  Widget _buildSettingsIcon(IconData icon) {
    final Color profileColor = ref.watch(currentProfileProvider).colorValue;
    final bool hasUpdate =
        ref.watch(updateCheckProvider).valueOrNull?.hasUpdate ?? false;

    final Widget iconWidget = Icon(icon, color: profileColor);

    if (!hasUpdate) return iconWidget;

    return _PulsingBadge(child: iconWidget);
  }

  /// Возвращает группы хоткеев для текущего таба (для F1 диалога).
  List<ShortcutGroup> _currentScreenShortcutGroups() {
    return switch (NavTab.values[_selectedIndex]) {
      NavTab.home => const <ShortcutGroup>[],
      NavTab.collections => const <ShortcutGroup>[
          HomeScreen.shortcutGroup,
          CollectionScreen.shortcutGroup,
          ItemDetailScreen.shortcutGroup,
        ],
      NavTab.tierLists => const <ShortcutGroup>[
          TierListsScreen.shortcutGroup,
          TierListDetailScreen.shortcutGroup,
        ],
      NavTab.wishlist => const <ShortcutGroup>[WishlistScreen.shortcutGroup],
      NavTab.search => const <ShortcutGroup>[SearchScreen.shortcutGroup],
      NavTab.settings => const <ShortcutGroup>[],
    };
  }

  /// F5 — обновить текущий таб (pop до корня и пересоздать).
  void _onRefresh() {
    final NavigatorState? tabNav =
        _navigatorKeys[_selectedIndex].currentState;
    if (tabNav == null) return;
    tabNav.popUntil((Route<dynamic> route) => route.isFirst);
    // Инвалидация произойдёт через Riverpod провайдеры на экранах
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

  /// Y кнопка → контекстное меню (аналог ПКМ / long press).
  ///
  /// Находит фокусированный виджет, ищет ближайший [InkWell] с onLongPress
  /// и вызывает его. Если InkWell не найден — ничего не делает.
  void _onGamepadContextMenu() {
    final FocusNode? primaryFocus = FocusManager.instance.primaryFocus;
    final BuildContext? focusContext = primaryFocus?.context;
    if (focusContext == null) return;

    // Ищем InkWell в поддереве фокусированного элемента или его предках
    InkWell? inkWell;
    focusContext.visitAncestorElements((Element element) {
      if (element.widget is InkWell) {
        inkWell = element.widget as InkWell;
        return false;
      }
      return true;
    });

    if (inkWell?.onLongPress != null) {
      inkWell!.onLongPress!();
      return;
    }

    // Fallback: ищем в потомках
    focusContext.visitChildElements((Element element) {
      void visit(Element el) {
        if (inkWell != null) return;
        if (el.widget is InkWell) {
          final InkWell candidate = el.widget as InkWell;
          if (candidate.onLongPress != null) {
            inkWell = candidate;
            return;
          }
        }
        el.visitChildElements(visit);
      }
      visit(element);
    });

    inkWell?.onLongPress?.call();
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

/// Badge с пульсирующей анимацией для индикации обновления.
class _PulsingBadge extends StatefulWidget {
  const _PulsingBadge({required this.child});

  final Widget child;

  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? child) {
        return Badge(
          backgroundColor: AppColors.statusInProgress.withAlpha(
            (_animation.value * 255).round(),
          ),
          smallSize: 8,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
