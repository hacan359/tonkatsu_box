import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/discord_rpc_service.dart';
import '../../core/services/kodi_sync_service.dart';
import '../../features/settings/providers/kodi_settings_provider.dart';
import '../../shared/constants/platform_features.dart';

class ServiceStatus {
  const ServiceStatus({
    this.kodiConfigured = false,
    this.kodiRunning = false,
    this.kodiSyncing = false,
    this.discordEnabled = false,
    this.discordConnected = false,
    this.discordRaSyncActive = false,
  });

  /// Host and target collection are set, so the badge is visible.
  final bool kodiConfigured;

  /// The sync timer is ticking, so the badge is coloured.
  final bool kodiRunning;

  /// A sync cycle is running right now, so the badge pulses.
  final bool kodiSyncing;

  /// Platform supports Discord RPC; the badge always shows on desktop.
  final bool discordEnabled;

  /// Connected to the Discord IPC socket, so the badge is coloured.
  final bool discordConnected;

  final bool discordRaSyncActive;

  bool get hasActiveServices => kodiConfigured || discordEnabled;
}

/// Polls every 2s through `ref.read`, not `ref.watch`: watching
/// `kodiSettingsProvider` would invalidate the stream and make badges flicker.
final AutoDisposeStreamProvider<ServiceStatus> serviceStatusProvider =
    StreamProvider.autoDispose<ServiceStatus>((Ref ref) {
  final KodiSyncService kodiSync = ref.read(kodiSyncServiceProvider);
  final DiscordRpcService discord = ref.read(discordRpcServiceProvider);

  ServiceStatus snapshot() {
    final KodiSettingsState kodiSettings = ref.read(kodiSettingsProvider);

    return ServiceStatus(
      kodiConfigured: kodiSettings.hasConnection &&
          kodiSettings.targetCollectionId != null,
      kodiRunning: kodiSync.isRunning,
      kodiSyncing: kodiSync.isSyncing,
      discordEnabled: kDiscordRpcAvailable,
      discordConnected: discord.isConnected,
      discordRaSyncActive: discord.isRaSyncActive,
    );
  }

  // ignore: close_sinks
  final StreamController<ServiceStatus> controller =
      StreamController<ServiceStatus>();

  controller.add(snapshot());

  final Timer timer = Timer.periodic(
    const Duration(seconds: 2),
    (_) {
      if (!controller.isClosed) {
        controller.add(snapshot());
      }
    },
  );

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
