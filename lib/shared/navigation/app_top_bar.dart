import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/update_service.dart';
import '../../features/welcome/providers/menu_tour_provider.dart';
import '../constants/platform_features.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'nav_icon_button.dart';
import 'nav_tab.dart';
import 'nav_tour_keys.dart';
import 'search_providers.dart';
import 'service_badges.dart';

const double kAppTopBarHeight = 56;

const double _kIdleSearchMaxWidth = 280;

  /// Wrap in [PreferredSize] with `kAppTopBarHeight + MediaQuery.paddingOf(context).top`
  /// so Scaffold reserves room for the Android status bar.
class AppTopBar extends ConsumerStatefulWidget {
  const AppTopBar({
    required this.activeTab,
    required this.onSettingsTap,
    this.suppressSearch = false,
    super.key,
  });

  /// Decides which provider the search field writes to.
  final NavTab activeTab;

  /// A disabled field drops focus, which on mobile hides the keyboard that would
  /// otherwise pop up when personalization opens.
  final bool suppressSearch;

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

    _querySub = ref.listenManual<String>(
      ctx.queryProvider,
      (String? previous, String next) {
        if (_controller.text != next) {
          _controller.value = TextEditingValue(
            text: next,
            selection: TextSelection.collapsed(offset: next.length),
          );
        }
      },
    );
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
    final SearchContext? ctx = widget.suppressSearch
        ? null
        : searchContextFor(widget.activeTab, context);
    _syncSubscription(ctx);

    final FocusNode focusNode = ref.watch(appTopBarFocusProvider);
    _syncFocusListener(focusNode);

    final bool enabled = ctx != null;
    final bool hasUpdate =
        ref.watch(updateCheckProvider).valueOrNull?.hasUpdate ?? false;
    final bool settingsActive = widget.activeTab == NavTab.settings;

    final bool isIdle =
        !focusNode.hasFocus && _controller.text.isEmpty;
    final double statusBarHeight = MediaQuery.paddingOf(context).top;

    return Container(
      height: kAppTopBarHeight + statusBarHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm + statusBarHeight,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isIdle ? _kIdleSearchMaxWidth : double.infinity,
                ),
                child: _SearchField(
                  controller: _controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  hint: ctx?.hint ?? '',
                  onChanged: (String value) {
                    if (ctx == null) return;
                    ref.read(ctx.queryProvider.notifier).state = value;
                  },
                  onClear: () {
                    if (ctx == null) return;
                    _controller.clear();
                    ref.read(ctx.queryProvider.notifier).state = '';
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const ServiceBadges(),
          const SizedBox(width: AppSpacing.sm),
          _SettingsButton(
            // Tour key only while the menu tour runs — otherwise two shells
            // alive at once (DB-reset `pushReplacement`) reuse it and crash.
            key: ref.watch(menuTourControllerProvider)
                ? ref.watch(navTourKeysProvider).keyFor(NavTab.settings)
                : null,
            active: settingsActive,
            pulsing: hasUpdate,
            onTap: widget.onSettingsTap,
          ),
        ],
      ),
    );
  }
}

/// Gear icon with an optional pulsing badge when an update is available.
class _SettingsButton extends StatelessWidget {
  const _SettingsButton({
    required this.active,
    required this.pulsing,
    required this.onTap,
    super.key,
  });

  final bool active;
  final bool pulsing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = active ? AppColors.brand : AppColors.textTertiary;

    Widget icon = Icon(
      active ? Icons.settings : Icons.settings_outlined,
      size: kTopBarIconSize,
      color: color,
    );

    if (pulsing) {
      icon = NavPulsingBadge(child: icon);
    }

    return SizedBox(
      width: 40,
      height: 40,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        containedInkWell: false,
        highlightShape: BoxShape.circle,
        child: Center(child: icon),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final Color iconColor =
        enabled ? AppColors.textTertiary : AppColors.textTertiary.withAlpha(120);
    final bool compact = isCompactScreen(context);
    final double textSize = compact ? 12 : 13;
    final double searchIconSize = compact ? 16 : 18;
    final double clearIconSize = compact ? 14 : 16;
    final double clearButtonSize = compact ? 24 : 28;

    return Row(
      children: <Widget>[
        Icon(Icons.search, size: searchIconSize, color: iconColor),
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
