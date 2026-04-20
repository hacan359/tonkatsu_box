// Глобальная шапка приложения для [AppShell].
//
// Содержит логотип слева, контекстное поле поиска и аватар профиля справа.
// Поле поиска меняет hint и пишет query в провайдер, соответствующий
// активному табу. Если таб не поддерживает поиск — поле отключено.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/update_service.dart';
import '../constants/platform_features.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'nav_icon_button.dart';
import 'nav_tab.dart';
import 'search_providers.dart';
import 'service_badges.dart';

/// Высота шапки.
const double kAppTopBarHeight = 56;

/// Ограничение ширины поля поиска, пока оно пустое и не в фокусе.
const double _kIdleSearchMaxWidth = 280;

/// Глобальная шапка приложения.
///
/// Оборачивать в [PreferredSize] с динамической высотой
/// (`kAppTopBarHeight + MediaQuery.paddingOf(context).top`), чтобы Scaffold
/// выделил правильное место под статусбар на Android.
class AppTopBar extends ConsumerStatefulWidget {
  /// Создаёт [AppTopBar].
  const AppTopBar({
    required this.activeTab,
    required this.onSettingsTap,
    super.key,
  });

  /// Активный таб (определяет контекст поиска).
  final NavTab activeTab;

  /// Колбэк при тапе по шестерёнке — переход в Settings.
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

  /// Подписывается на провайдер текущего таба (если он поменялся)
  /// и синхронизирует контроллер с внешним значением.
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

  /// Подписывается на focus node, чтобы ребилдить виджет при смене фокуса
  /// (нужно для сужения/расширения «пустого» поля).
  void _syncFocusListener(FocusNode node) {
    if (_watchedFocusNode == node) return;
    _watchedFocusNode?.removeListener(_onFocusChanged);
    _watchedFocusNode = node;
    node.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() {});
    // При получении фокуса (type-to-search) ставим курсор в конец,
    // чтобы следующая буква не затирала текст.
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
    final SearchContext? ctx = searchContextFor(widget.activeTab, context);
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
      decoration: const BoxDecoration(
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
          Image.asset(
            AppAssets.logo,
            width: 40,
            height: 40,
          ),
          SizedBox(
            width: MediaQuery.sizeOf(context).width < 700 ? 12 : 56,
          ),
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
            active: settingsActive,
            pulsing: hasUpdate,
            onTap: widget.onSettingsTap,
          ),
        ],
      ),
    );
  }
}

/// Иконка шестерёнки с опциональным пульсирующим бейджем (update available).
class _SettingsButton extends StatelessWidget {
  const _SettingsButton({
    required this.active,
    required this.pulsing,
    required this.onTap,
  });

  final bool active;
  final bool pulsing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = active ? AppColors.brand : AppColors.textTertiary;

    Widget icon = Icon(
      active ? Icons.settings : Icons.settings_outlined,
      size: 22,
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
