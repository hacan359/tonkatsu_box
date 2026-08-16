import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/whats_new_service.dart';
import '../../features/collections/screens/collection_screen.dart';
import '../../features/collections/screens/home_screen.dart';
import '../../features/home/screens/all_items_screen.dart';
import '../../features/personalization/screens/personalization_screen.dart';
import '../../features/collections/screens/item_detail_screen.dart';
import '../../features/releases/screens/releases_screen.dart';
import '../../features/search/providers/browse_provider.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/welcome/providers/menu_tour_provider.dart';
import '../../features/welcome/widgets/menu_tour_overlay.dart';
import '../../features/tier_lists/screens/tier_list_detail_screen.dart';
import '../../features/tier_lists/screens/tier_lists_screen.dart';
import '../../features/wishlist/screens/wishlist_screen.dart';
import '../../l10n/app_localizations.dart';
import '../constants/platform_features.dart';
import '../gamepad/gamepad_action.dart';
import '../gamepad/widgets/gamepad_listener.dart';
import '../keyboard/keyboard_shortcuts.dart';
import '../keyboard/keyboard_shortcuts_dialog.dart';
import '../widgets/whats_new_dialog.dart';
import 'app_bottom_bar.dart';
import 'app_sidebar.dart';
import 'app_top_bar.dart';
import 'nav_tab.dart';
import 'search_providers.dart';

/// Number of primary tabs.
const int _tabCount = 7;

/// Clears the Search tab's transient state on entry so it always opens empty.
/// Browse filters and the source stay — those are a deliberate setup.
@visibleForTesting
void resetSearchTabState(WidgetRef ref) {
  ref.read(searchTabQueryProvider.notifier).state = '';
  ref.read(searchTargetCollectionsProvider.notifier).state = <int>{};
  ref.read(browseProvider.notifier).clearSearch();
}

/// [AppSidebar] plus an [IndexedStack] of cached per-tab [Navigator]s. Gamepad
/// intents (D-pad focus, A, LB/RB, B) are bound here, not per screen.
class AppShell extends ConsumerStatefulWidget {
  /// [initialTab] opens the app on a specific tab (e.g. Settings right after
  /// the welcome wizard).
  const AppShell({this.initialTab, super.key});

  /// Starting tab; [NavTab.home] when null.
  final NavTab? initialTab;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late int _selectedIndex = widget.initialTab?.index ?? NavTab.home.index;

  /// FocusScopeNode per tab.
  final List<FocusScopeNode> _tabFocusScopeNodes = List<FocusScopeNode>.generate(
    _tabCount,
    (int i) => FocusScopeNode(debugLabel: 'tab-$i-scope'),
  );

  /// Tabs that have been initialized already (lazy init).
  late final Set<int> _initializedTabs = <int>{
    NavTab.home.index,
    if (widget.initialTab != null) widget.initialTab!.index,
  };

  /// Navigator keys per tab.
  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List<GlobalKey<NavigatorState>>.generate(
    _tabCount,
    (_) => GlobalKey<NavigatorState>(),
  );

  /// [MaterialApp] rebuilds the tree on locale change; without this cache each
  /// rebuild would drop a new Navigator in and lose its route history.
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
    ref.listen<SearchTabRequest?>(
      searchTabRequestProvider,
      (SearchTabRequest? previous, SearchTabRequest? request) {
        if (request == null) return;
        _openSearchTab(request);
        ref.read(searchTabRequestProvider.notifier).state = null;
      },
    );
    // Release notes after an app update, once per version. The version is
    // remembered on close, so a launch killed mid-dialog shows it again.
    ref.listen<AsyncValue<WhatsNewContent?>>(
      whatsNewProvider,
      (AsyncValue<WhatsNewContent?>? previous,
          AsyncValue<WhatsNewContent?> next) {
        final WhatsNewContent? content = next.valueOrNull;
        if (content == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          unawaited(
            showWhatsNewDialog(context, content).then((_) {
              if (!mounted) return;
              unawaited(
                ref.read(whatsNewServiceProvider).markSeen(content.version),
              );
            }),
          );
        });
      },
    );
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
            screenGroups: _currentScreenShortcutGroups(S.of(context)),
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
              child: _buildShell(context),
            ),
          ),
        ),
      ),
    );
  }

  /// The shell, with the menu-tour overlay layered on top while it is running.
  Widget _buildShell(BuildContext context) {
    final Widget scaffold = _buildScaffold(context);
    if (!ref.watch(menuTourControllerProvider)) {
      return scaffold;
    }
    return Stack(
      children: <Widget>[
        scaffold,
        const Positioned.fill(child: MenuTourOverlay()),
      ],
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
        suppressSearch: _personalizationOpen,
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
          onCenterTap: _openPreferenceCloud,
          centerActive: _personalizationOpen,
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
            onCenterTap: _openPreferenceCloud,
            centerActive: _personalizationOpen,
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  /// Whether the Personalization view is the active view (shown in the content
  /// area and highlighting the centre nav button like a selected tab).
  bool _personalizationOpen = false;

  /// A sibling of the tab navigators rather than a route on one, so switching
  /// tabs hides the cloud instead of leaving it on that tab's stack.
  void _openPreferenceCloud() {
    if (_personalizationOpen) return;
    // Drop any focus the top-bar search field holds so the mobile keyboard
    // doesn't stay up over a view that has no search of its own.
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _personalizationOpen = true);
  }

  /// Type-to-search: desktop only, and only when the tab supports search and
  /// focus is not already inside a text field.
  KeyEventResult _handleTypeToSearch(FocusNode node, KeyEvent event) {
    if (kIsMobile) return KeyEventResult.ignored;
    // Personalization has no search field; don't hijack typing for it.
    if (_personalizationOpen) return KeyEventResult.ignored;
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

  /// Whether focus is inside some other [EditableText].
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
      index: _personalizationOpen ? _tabCount : _selectedIndex,
      children: <Widget>[
        for (int index = 0; index < _tabCount; index++)
          // IndexedStack alone leaves tickers running in hidden children, so
          // the app never goes frame-idle and visible animations compete.
          TickerMode(
            enabled: !_personalizationOpen && index == _selectedIndex,
            child: _initializedTabs.contains(index)
                ? _buildTabNavigator(index)
                : const SizedBox.shrink(),
          ),
        // An extra IndexedStack child, not a tab route — switching tabs hides
        // it. Not kept alive: the subtree is heavy, providers carry the state.
        if (_personalizationOpen)
          const PersonalizationScreen()
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildTabNavigator(int tabIndex) {
    _navigatorWidgets[tabIndex] ??= Navigator(
      key: _navigatorKeys[tabIndex],
      onGenerateRoute: (RouteSettings settings) {
        final Widget screen = switch (NavTab.values[tabIndex]) {
          NavTab.home => const AllItemsScreen(),
          NavTab.releases => const ReleasesScreen(),
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
    if (index == _selectedIndex && !_personalizationOpen) {
      // Pressing again returns to the tab root, but not while Personalization
      // is open — that tap must close the cloud, not pop a hidden tab.
      _navigatorKeys[index]
          .currentState
          ?.popUntil((Route<dynamic> route) => route.isFirst);
      return;
    }
    if (NavTab.values[index] == NavTab.search) {
      _resetSearchTab();
    }
    _initializedTabs.add(index);
    setState(() {
      _selectedIndex = index;
      // Switching to a real tab moves the selection highlight off the centre
      // button.
      _personalizationOpen = false;
    });
    // Explicitly focus the new tab's content for the gamepad.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final FocusScopeNode scope = _tabFocusScopeNodes[index];
      scope.requestFocus();
      scope.nextFocus();
    });
  }

  void _resetSearchTab() => resetSearchTabState(ref);

  /// Reuses the Search tab instead of pushing a separate screen, so the shell
  /// keeps a single top-bar search field.
  void _openSearchTab(SearchTabRequest request) {
    // Start from a clean Search tab (also clears any stale target collection).
    resetSearchTabState(ref);

    final int index = NavTab.search.index;
    // Personalization open over the Search tab still needs a switch, or the
    // request is swallowed by the overlay.
    if (_selectedIndex != index || _personalizationOpen) {
      _initializedTabs.add(index);
      setState(() {
        _selectedIndex = index;
        _personalizationOpen = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final FocusScopeNode scope = _tabFocusScopeNodes[index];
        scope.requestFocus();
        scope.nextFocus();
      });
    }

    final int? collectionId = request.collectionId;
    if (collectionId != null) {
      ref.read(searchTargetCollectionsProvider.notifier).state = <int>{
        collectionId,
      };
    }
    if (request.sourceId != null) {
      ref.read(browseProvider.notifier).setSource(request.sourceId!);
    } else if (request.mediaType != null) {
      ref.read(browseProvider.notifier).setMediaType(request.mediaType!);
    }
    final String query = request.query?.trim() ?? '';
    if (query.isNotEmpty) {
      ref.read(searchTabQueryProvider.notifier).state = query;
      ref.read(browseProvider.notifier).search(query);
    }
  }

  /// Handles the back button (Android back, Gamepad B).
  ///
  /// Returns `true` if navigation was handled; `false` if the app should exit.
  bool _handleBack() {
    if (_personalizationOpen) {
      setState(() => _personalizationOpen = false);
      return true;
    }
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

  /// Shortcut groups for the current tab (for the F1 dialog).
  List<ShortcutGroup> _currentScreenShortcutGroups(S l) {
    return switch (NavTab.values[_selectedIndex]) {
      NavTab.home => const <ShortcutGroup>[],
      NavTab.releases => const <ShortcutGroup>[],
      NavTab.collections => <ShortcutGroup>[
          HomeScreen.shortcutGroup(l),
          CollectionScreen.shortcutGroup(l),
          ItemDetailScreen.shortcutGroup(l),
        ],
      NavTab.tierLists => <ShortcutGroup>[
          TierListsScreen.shortcutGroup(l),
          TierListDetailScreen.shortcutGroup(l),
        ],
      NavTab.wishlist => <ShortcutGroup>[WishlistScreen.shortcutGroup(l)],
      NavTab.search => <ShortcutGroup>[SearchScreen.shortcutGroup(l)],
      NavTab.settings => const <ShortcutGroup>[],
    };
  }

  /// F5 — refresh the current tab (pop to its root).
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

  /// D-pad → move focus via DirectionalFocusIntent.
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

  /// A button → activate the focused widget.
  void _onGamepadConfirm() {
    final BuildContext? focusContext =
        FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) return;

    Actions.maybeInvoke(focusContext, const ActivateIntent());
  }

  /// Y button → context menu (like right-click / long press).
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

  /// Left stick → scroll via a synthetic PointerScrollEvent.
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
