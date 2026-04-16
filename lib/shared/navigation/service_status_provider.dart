// Провайдер реактивного состояния фоновых сервисов (Kodi sync, Discord RPC).
//
// Использует polling (ref.read) вместо ref.watch, чтобы обновления
// kodiSettingsProvider / settingsNotifierProvider не инвалидировали
// стрим и не вызывали мигание бейджей в шапке.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/discord_rpc_service.dart';
import '../../core/services/kodi_sync_service.dart';
import '../../features/settings/providers/kodi_settings_provider.dart';
import '../../shared/constants/platform_features.dart';

/// Снимок состояния фоновых сервисов.
class ServiceStatus {
  /// Создаёт [ServiceStatus].
  const ServiceStatus({
    this.kodiConfigured = false,
    this.kodiRunning = false,
    this.kodiSyncing = false,
    this.discordEnabled = false,
    this.discordConnected = false,
    this.discordRaSyncActive = false,
  });

  /// Kodi sync настроен (host + target collection) — бейдж видим.
  final bool kodiConfigured;

  /// Kodi sync таймер тикает (бейдж цветной).
  final bool kodiRunning;

  /// Kodi sync цикл идёт прямо сейчас (пульсация).
  final bool kodiSyncing;

  /// Discord RPC доступен на платформе (бейдж всегда видим на десктопе).
  final bool discordEnabled;

  /// Discord RPC подключён к IPC (бейдж цветной).
  final bool discordConnected;

  /// Discord RA Sync активен.
  final bool discordRaSyncActive;

  /// Есть ли хотя бы один сервис, для которого нужен бейдж.
  bool get hasActiveServices => kodiConfigured || discordEnabled;
}

/// Провайдер состояния фоновых сервисов.
///
/// Polling каждые 2 секунды через `ref.read` (не `ref.watch`),
/// чтобы обновления `kodiSettingsProvider.lastSyncTimestamp` и прочие
/// изменения настроек не инвалидировали стрим и не вызывали
/// мигание/исчезание бейджей.
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
