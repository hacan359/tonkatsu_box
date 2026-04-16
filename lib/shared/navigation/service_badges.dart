// Шилдики фоновых сервисов (Kodi sync, Discord RPC) для шапки.
//
// Отображаются только на десктопе. Логотип цветной — сервис активен,
// серый — неактивен. Клик включает/выключает сервис.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/services/discord_rpc_service.dart';
import '../../core/services/kodi_sync_service.dart';
import '../../features/collections/providers/canvas_provider.dart';
import '../../features/collections/providers/collection_covers_provider.dart';
import '../../features/collections/providers/collections_provider.dart';
import '../../features/home/providers/all_items_provider.dart';
import '../../features/settings/providers/kodi_settings_provider.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../constants/platform_features.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'service_status_provider.dart';

/// Брендовый цвет Discord (Blurple).
const Color _kDiscordColor = Color(0xFF5865F2);

/// Брендовый цвет Kodi.
const Color _kKodiColor = Color(0xFF17B2E7);

/// Строка шилдиков активных фоновых сервисов.
///
/// На мобильных платформах возвращает [SizedBox.shrink].
/// Логотип цветной = сервис работает, серый = остановлен.
/// Клик toggle'ит сервис.
class ServiceBadges extends ConsumerWidget {
  /// Создаёт [ServiceBadges].
  const ServiceBadges({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsMobile) return const SizedBox.shrink();

    final ServiceStatus status =
        ref.watch(serviceStatusProvider).valueOrNull ?? const ServiceStatus();

    if (!status.hasActiveServices) return const SizedBox.shrink();

    final List<Widget> badges = <Widget>[];

    if (status.kodiConfigured) {
      final bool isActive = status.kodiRunning;
      final String tooltip = status.kodiSyncing
          ? 'Kodi sync: syncing…'
          : isActive
              ? 'Kodi sync: running'
              : 'Kodi sync: stopped';
      badges.add(
        _ServiceIcon(
          asset: AppAssets.iconKodi,
          activeColor: _kKodiColor,
          isActive: isActive,
          pulsing: status.kodiSyncing,
          tooltip: tooltip,
          onTap: () => _toggleKodi(ref, isRunning: isActive),
        ),
      );
    }

    if (status.discordEnabled) {
      final bool isActive = status.discordConnected;
      final String tooltip = status.discordRaSyncActive
          ? 'Discord RPC: connected (RA sync)'
          : isActive
              ? 'Discord RPC: connected'
              : 'Discord RPC: disconnected';
      badges.add(
        _ServiceIcon(
          asset: AppAssets.iconDiscord,
          activeColor: _kDiscordColor,
          isActive: isActive,
          pulsing: false,
          tooltip: tooltip,
          onTap: () => _toggleDiscord(ref, isConnected: isActive),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < badges.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          badges[i],
        ],
      ],
    );
  }

  void _toggleKodi(WidgetRef ref, {required bool isRunning}) {
    final KodiSyncService sync = ref.read(kodiSyncServiceProvider);

    if (isRunning) {
      ref.read(kodiSettingsProvider.notifier).setEnabled(enabled: false);
      sync.stop();
      return;
    }

    final KodiSettingsState settings = ref.read(kodiSettingsProvider);
    if (settings.targetCollectionId == null) return;

    ref.read(kodiSettingsProvider.notifier).setEnabled(enabled: true);
    sync.start(
      intervalSeconds: settings.syncIntervalSeconds,
      targetCollectionId: settings.targetCollectionId!,
      importRatings: settings.importRatings,
      createSubCollections: settings.createSubCollections,
      onSyncTimestamp: (String timestamp) {
        ref.read(kodiSettingsProvider.notifier).setLastSyncTimestamp(timestamp);
      },
      onResult: (KodiSyncResult result) {
        if (result.hasChanges) {
          ref.invalidate(collectionsProvider);
          ref.invalidate(allItemsNotifierProvider);
          for (final int collId in result.affectedCollectionIds) {
            ref.invalidate(collectionStatsProvider(collId));
            ref.invalidate(collectionCoversProvider(collId));
            ref.invalidate(collectionItemsNotifierProvider(collId));
            ref.invalidate(canvasNotifierProvider(collId));
          }
        }
      },
      onTargetNotFound: () {
        ref.read(kodiSettingsProvider.notifier).setEnabled(enabled: false);
        ref.read(kodiSettingsProvider.notifier).setTargetCollectionId(null);
      },
    );
  }

  void _toggleDiscord(WidgetRef ref, {required bool isConnected}) {
    final DiscordRpcService rpc = ref.read(discordRpcServiceProvider);

    if (isConnected) {
      ref
          .read(settingsNotifierProvider.notifier)
          .setDiscordRpcEnabled(enabled: false);
      rpc.disableRaSync();
      rpc.disable();
    } else {
      ref
          .read(settingsNotifierProvider.notifier)
          .setDiscordRpcEnabled(enabled: true);
      rpc.enable();
    }
  }
}

/// Иконка одного сервиса: SVG логотип с цветным/серым состоянием.
class _ServiceIcon extends StatefulWidget {
  const _ServiceIcon({
    required this.asset,
    required this.activeColor,
    required this.isActive,
    required this.pulsing,
    required this.tooltip,
    required this.onTap,
  });

  final String asset;
  final Color activeColor;
  final bool isActive;
  final bool pulsing;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_ServiceIcon> createState() => _ServiceIconState();
}

class _ServiceIconState extends State<_ServiceIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color color = widget.isActive
        ? widget.activeColor
        : AppColors.textTertiary;

    Widget icon = SvgPicture.asset(
      widget.asset,
      width: 18,
      height: 18,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );

    if (widget.pulsing) {
      icon = _PulsingWrap(child: icon);
    }

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: _hovered
                  ? color.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: icon,
          ),
        ),
      ),
    );
  }
}

/// Пульсирующая обёртка (opacity fade) для иконки во время sync.
class _PulsingWrap extends StatefulWidget {
  const _PulsingWrap({required this.child});

  final Widget child;

  @override
  State<_PulsingWrap> createState() => _PulsingWrapState();
}

class _PulsingWrapState extends State<_PulsingWrap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 1.0).animate(
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
        return Opacity(opacity: _animation.value, child: child);
      },
      child: widget.child,
    );
  }
}
