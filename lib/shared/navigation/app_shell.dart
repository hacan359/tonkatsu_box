// Основная оболочка приложения: боковое меню + вложенная навигация.

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
import '../../features/wishlist/screens/wishlist_screen.dart';
import '../constants/platform_features.dart';
import '../gamepad/gamepad_action.dart';
import '../gamepad/widgets/gamepad_listener.dart';
import '../keyboard/keyboard_shortcuts.dart';
import '../keyboard/keyboard_shortcuts_dialog.dart';
import 'app_bottom_bar.dart';
import 'app_sidebar.dart';
import 'app_top_bar.dart';
import 'nav_tab.dart';
import 'search_providers.dart';

/// Количество основных табов.
const int _tabCount = 6;

/// Главная оболочка приложения.
///
/// Единая для всех платформ (Windows, Android): слева — [AppSidebar] шириной
/// [kAppSidebarWidth], справа — вложенная навигация каждого таба через
/// [IndexedStack] + кэшированные [Navigator].
///
/// Поддержка геймпада:
/// - D-pad — перемещение фокуса (DirectionalFocusIntent)
/// - A — активация фокусированного виджета (ActivateIntent)
/// - LB/RB — переключение между табами
/// - B — назад (pop внутри таба или переключение на Home)
class AppShell extends ConsumerStatefulWidget {
  /// Создаёт [AppShell].
  ///
  /// [initialTab] позволяет открыть приложение на конкретном табе
  /// (например, Settings после Welcome Wizard).
  const AppShell({this.initialTab, super.key});

  /// Начальный таб. Если null — [NavTab.home].
  final NavTab? initialTab;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late int _selectedIndex = widget.initialTab?.index ?? NavTab.home.index;

  /// FocusScopeNode для каждого таба.
  final List<FocusScopeNode> _tabFocusScopeNodes = List<FocusScopeNode>.generate(
    _tabCount,
    (int i) => FocusScopeNode(debugLabel: 'tab-$i-scope'),
  );

  /// Табы, которые уже были инициализированы (ленивая инициализация).
  late final Set<int> _initializedTabs = <int>{
    NavTab.home.index,
    if (widget.initialTab != null) widget.initialTab!.index,
  };

  /// Ключи Navigator для каждого таба.
  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List<GlobalKey<NavigatorState>>.generate(
    _tabCount,
    (_) => GlobalKey<NavigatorState>(),
  );

  /// Кэшированные Navigator-виджеты.
  ///
  /// При смене локали [MaterialApp] перестраивает всё дерево. Без кэша
  /// каждый ребилд создавал бы новый Navigator и терял историю маршрутов.
  final List<Widget?> _navigatorWidgets =
      List<Widget?>.filled(_tabCount, null);

  @override
  void dispose() {
    for (final FocusScopeNode node in _tabFocusScopeNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
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
            onKeyEvent: _handleTypeToSearch,
            child: GamepadListener(
              onTabSwitch: _onGamepadTabSwitch,
              onNavigate: _onGamepadNavigate,
              onConfirm: _onGamepadConfirm,
              onContextMenu: _onGamepadContextMenu,
              onScroll: _onGamepadScroll,
              onBack: () {
                _handleBack();
              },
              child: _buildScaffold(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final bool compact = isCompactScreen(context);
    final NavTab activeTab = NavTab.values[_selectedIndex];
    final PreferredSizeWidget topBar = PreferredSize(
      preferredSize: Size.fromHeight(
        kAppTopBarHeight + MediaQuery.paddingOf(context).top,
      ),
      child: AppTopBar(
        activeTab: activeTab,
        onSettingsTap: () => _onDestinationSelected(NavTab.settings.index),
      ),
    );

    void onTabSelected(NavTab tab) => _onDestinationSelected(tab.index);

    if (compact) {
      return Scaffold(
        appBar: topBar,
        body: _buildContent(),
        bottomNavigationBar: AppBottomBar(
          selectedTab: activeTab,
          onDestinationSelected: onTabSelected,
        ),
      );
    }
    return Scaffold(
      appBar: topBar,
      body: Row(
        children: <Widget>[
          AppSidebar(
            selectedTab: activeTab,
            onDestinationSelected: onTabSelected,
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  /// Перехватывает печатные символы с глобального Focus и перенаправляет
  /// их в поле поиска [AppTopBar] (type-to-search).
  ///
  /// Срабатывает только на десктопе, только если текущий таб поддерживает
  /// поиск и фокус не находится внутри другого [EditableText].
  KeyEventResult _handleTypeToSearch(FocusNode node, KeyEvent event) {
    if (kIsMobile) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final SearchContext? ctx = searchContextFor(
      NavTab.values[_selectedIndex],
      context,
    );
    if (ctx == null) return KeyEventResult.ignored;

    if (_isAnyEditableTextFocused()) return KeyEventResult.ignored;

    final String? char = event.character;
    if (char == null || char.isEmpty || char.codeUnitAt(0) < 32) {
      return KeyEventResult.ignored;
    }

    final String current = ref.read(ctx.queryProvider);
    ref.read(ctx.queryProvider.notifier).state = current + char;

    final FocusNode searchFocus = ref.read(appTopBarFocusProvider);
    searchFocus.requestFocus();
    return KeyEventResult.handled;
  }

  /// Проверяет, находится ли фокус во внешнем [EditableText].
  bool _isAnyEditableTextFocused() {
    final FocusNode? focus = FocusManager.instance.primaryFocus;
    final BuildContext? ctx = focus?.context;
    if (ctx == null) return false;
    bool editable = false;
    ctx.visitAncestorElements((Element element) {
      if (element.widget is EditableText) {
        editable = true;
        return false;
      }
      return true;
    });
    return editable;
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
      // Повторное нажатие — вернуться к корню таба.
      _navigatorKeys[index]
          .currentState
          ?.popUntil((Route<dynamic> route) => route.isFirst);
      return;
    }
    _initializedTabs.add(index);
    setState(() => _selectedIndex = index);
    // Явно фокусируем контент нового таба для геймпада.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final FocusScopeNode scope = _tabFocusScopeNodes[index];
      scope.requestFocus();
      scope.nextFocus();
    });
  }

  /// Обработка кнопки «назад» (Android back, Gamepad B).
  ///
  /// Возвращает `true`, если навигация обработана; `false`, если нужно выйти.
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

  /// F5 — обновить текущий таб (pop до корня).
  void _onRefresh() {
    final NavigatorState? tabNav =
        _navigatorKeys[_selectedIndex].currentState;
    if (tabNav == null) return;
    tabNav.popUntil((Route<dynamic> route) => route.isFirst);
  }

  void _onGamepadTabSwitch(GamepadAction action) {
    final int newIndex = action == GamepadAction.nextTab
        ? (_selectedIndex + 1) % _tabCount
        : (_selectedIndex - 1 + _tabCount) % _tabCount;
    _onDestinationSelected(newIndex);
  }

  /// D-pad → перемещение фокуса через DirectionalFocusIntent.
  void _onGamepadNavigate(GamepadAction action) {
    final FocusNode? primaryFocus = FocusManager.instance.primaryFocus;
    final BuildContext? focusContext = primaryFocus?.context;

    if (focusContext == null) {
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

  /// A кнопка → активация фокусированного виджета.
  void _onGamepadConfirm() {
    final BuildContext? focusContext =
        FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) return;

    Actions.maybeInvoke(focusContext, const ActivateIntent());
  }

  /// Y кнопка → контекстное меню (аналог ПКМ / long press).
  void _onGamepadContextMenu() {
    final FocusNode? primaryFocus = FocusManager.instance.primaryFocus;
    final BuildContext? focusContext = primaryFocus?.context;
    if (focusContext == null) return;

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
