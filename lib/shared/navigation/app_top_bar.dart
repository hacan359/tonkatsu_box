import 'package:core/utils/meta_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/update_service.dart';
import '../../features/welcome/providers/menu_tour_provider.dart';
import '../../l10n/app_localizations.dart';
import '../constants/platform_features.dart';
import '../constants/search_mode_ui.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'frame_chrome.dart';
import 'nav_tab.dart';
import 'nav_tour_keys.dart';
import 'search_providers.dart';
import 'service_badges.dart';
import '../widgets/glass_popup_menu.dart';
import 'frame_metrics.dart';
import 'zone_icon_button.dart';

const double kAppTopBarHeight = 56;

/// The frame's top panel: back + title, the always-open search, actions.
class AppTopBar extends ConsumerStatefulWidget {
  const AppTopBar({
    required this.activeTab,
    required this.onSettingsTap,
    this.personalizationOpen = false,
    super.key,
  });

  /// Decides which provider the search field writes to.
  final NavTab activeTab;

  /// With the hub open the field serves the likes page or nothing at all; a
  /// disabled field drops focus, which on mobile also hides the keyboard.
  final bool personalizationOpen;

  final VoidCallback onSettingsTap;

  @override
  ConsumerState<AppTopBar> createState() => _AppTopBarState();
}

class _AppTopBarState extends ConsumerState<AppTopBar> {
  final TextEditingController _controller = TextEditingController();
  ProviderSubscription<String>? _querySub;
  StateProvider<String>? _subscribedProvider;
  FocusNode? _watchedFocusNode;

  @override
  void dispose() {
    _watchedFocusNode?.removeListener(_onFocusChanged);
    _querySub?.close();
    _controller.dispose();
    super.dispose();
  }

  /// Re-subscribes when the tab changed and syncs the controller with the
  /// provider's value.
  void _syncSubscription(SearchContext? ctx) {
    if (ctx?.queryProvider == _subscribedProvider) return;

    _querySub?.close();
    _subscribedProvider = ctx?.queryProvider;

    if (ctx == null) {
      _controller.text = '';
      return;
    }

    final String initial = ref.read(ctx.queryProvider);
    if (_controller.text != initial) {
      _controller.text = initial;
    }

    _querySub = ref.listenManual<String>(ctx.queryProvider, (
      String? previous,
      String next,
    ) {
      if (_controller.text != next) {
        _controller.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    });
  }

  /// Rebuilds on focus change — the empty field narrows and widens with it.
  void _syncFocusListener(FocusNode node) {
    if (_watchedFocusNode == node) return;
    _watchedFocusNode?.removeListener(_onFocusChanged);
    _watchedFocusNode = node;
    node.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() {});
    // On focus (type-to-search) the caret goes to the end so the next letter
    // appends instead of replacing.
    if (_watchedFocusNode?.hasFocus ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final int end = _controller.text.length;
        _controller.selection = TextSelection.collapsed(offset: end);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final SearchContext? ctx = activeSearchContext(
      tab: widget.activeTab,
      personalizationOpen: widget.personalizationOpen,
      likesSearchActive: ref.watch(likesSearchActiveProvider),
      context: context,
    );
    _syncSubscription(ctx);

    final FocusNode focusNode = ref.watch(appTopBarFocusProvider);
    _syncFocusListener(focusNode);

    final bool enabled = ctx != null;
    final bool hasUpdate =
        ref.watch(updateCheckProvider).valueOrNull?.hasUpdate ?? false;
    final bool settingsActive = widget.activeTab == NavTab.settings;

    final bool metaSearchAvailable = ctx?.supportsMetaSearch ?? false;
    final SearchMode mode = metaSearchAvailable
        ? ref.watch(searchModeProvider)
        : SearchMode.title;
    final String hint = mode == SearchMode.meta
        ? S.of(context).appBarMetaSearchHint
        : ctx?.hint ?? '';
    final FrameChrome? chrome = FrameChromeScope.watch(context)?.current;
    final VoidCallback? onBack = chrome?.onBack;
    final String? title = chrome?.title;
    final NavTourKeys tourKeys = ref.watch(navTourKeysProvider);
    final bool tourActive = ref.watch(menuTourControllerProvider);

    final Widget searchField = _SearchField(
      controller: _controller,
      focusNode: focusNode,
      enabled: enabled,
      hint: hint,
      mode: mode,
      onModeChanged: metaSearchAvailable
          ? (SearchMode value) =>
                ref.read(searchModeProvider.notifier).state = value
          : null,
      onChanged: (String value) {
        if (ctx == null) return;
        ref.read(ctx.queryProvider.notifier).state = value;
      },
      onClear: () {
        if (ctx == null) return;
        _controller.clear();
        ref.read(ctx.queryProvider.notifier).state = '';
        focusNode.unfocus();
      },
    );

    // One row in the top panel: back + title, the open search, then the
    // sub-screen's actions, service badges and settings.
    return Row(
      children: <Widget>[
        if (onBack != null)
          ZoneIconButton(icon: Icons.arrow_back, onTap: onBack),
        if (title != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kFrameTitleMaxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                0,
                AppSpacing.md,
                0,
              ),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        Expanded(
          child: Container(
            height: kFrameSearchFieldHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.background.withAlpha(110),
              borderRadius: BorderRadius.circular(kFrameSearchFieldHeight / 2),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: searchField,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        ...?chrome?.actions,
        const ServiceBadges(),
        ZoneIconButton(
          // Tour key only while the menu tour runs — otherwise two shells
          // alive at once (DB-reset `pushReplacement`) reuse it and crash.
          key: tourActive ? tourKeys.keyFor(NavTab.settings) : null,
          icon: settingsActive ? Icons.settings : Icons.settings_outlined,
          color: settingsActive ? AppColors.brand : AppColors.textTertiary,
          badge: hasUpdate,
          onTap: widget.onSettingsTap,
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.hint,
    required this.mode,
    required this.onModeChanged,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final String hint;
  final SearchMode mode;

  /// Null hides the mode menu: the tab has no metadata to search.
  final ValueChanged<SearchMode>? onModeChanged;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = enabled
        ? AppColors.textTertiary
        : AppColors.textTertiary.withAlpha(120);
    final bool compact = isCompactScreen(context);
    final double textSize = compact ? 12 : 13;
    final double searchIconSize = compact ? 16 : 18;
    final double clearIconSize = compact ? 14 : 16;
    final double clearButtonSize = compact ? 24 : 28;

    final Widget searchIcon = Icon(
      mode == SearchMode.meta ? Icons.manage_search : Icons.search,
      size: searchIconSize,
      color: iconColor,
    );

    return Row(
      children: <Widget>[
        if (onModeChanged != null && enabled)
          _SearchModeMenu(
            mode: mode,
            icon: searchIcon,
            onSelected: onModeChanged!,
          )
        else
          searchIcon,
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            style: AppTypography.body.copyWith(
              fontSize: textSize,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.body.copyWith(
                fontSize: textSize,
                color: AppColors.textTertiary,
              ),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                vertical: compact ? AppSpacing.xs : AppSpacing.sm,
              ),
            ),
            onChanged: onChanged,
          ),
        ),
        if (enabled && controller.text.isNotEmpty)
          SizedBox(
            width: clearButtonSize,
            height: clearButtonSize,
            child: IconButton(
              icon: Icon(Icons.close, size: clearIconSize),
              color: AppColors.textTertiary,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: clearButtonSize,
                minHeight: clearButtonSize,
              ),
              onPressed: onClear,
            ),
          ),
      ],
    );
  }
}

/// Title / metadata switch in front of the field; the arrow is the only hint
/// the icon is a menu, so it stays visible even when the field is idle.
class _SearchModeMenu extends StatelessWidget {
  const _SearchModeMenu({
    required this.mode,
    required this.icon,
    required this.onSelected,
  });

  final SearchMode mode;
  final Widget icon;
  final ValueChanged<SearchMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return GlassPopupMenuButton<SearchMode>(
      tooltip: l.searchModeTooltip,
      offset: const Offset(0, AppSpacing.xl),
      onSelected: onSelected,
      rows: (BuildContext _) => <Widget>[
        for (final SearchMode value in SearchMode.values)
          GlassMenuRow<SearchMode>(
            value: value,
            label: value.localizedLabel(l),
            checked: value == mode,
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          icon,
          Icon(
            Icons.arrow_drop_down,
            size: AppSpacing.md,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
