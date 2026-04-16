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
import '../../features/settings/providers/settings_provider.dart';
import '../../shared/constants/platform_features.dart';

/// Снимок состояния фоновых сервисов.
class ServiceStatus {
  /// Создаёт [ServiceStatus].
  const ServiceStatus({
    this.kodiEnabled = false,
    this.kodiRunning = false,
    this.kodiSyncing = false,
    this.discordEnabled = false,
    this.discordConnected = false,
    this.discordRaSyncActive = false,
  });

  /// Kodi sync включён в настройках (бейдж видим).
  final bool kodiEnabled;

  /// Kodi sync таймер тикает (бейдж цветной).
  final bool kodiRunning;

  /// Kodi sync цикл идёт прямо сейчас (пульсация).
  final bool kodiSyncing;

  /// Discord RPC включён в настройках (бейдж видим).
  final bool discordEnabled;

  /// Discord RPC подключён к IPC (бейдж цветной).
  final bool discordConnected;

  /// Discord RA Sync активен.
  final bool discordRaSyncActive;

  /// Есть ли хотя бы один сервис, для которого нужен бейдж.
  bool get hasActiveServices => kodiEnabled || discordEnabled;
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
    // Читаем настройки каждый poll — ref.read не создаёт подписку,
    // так что стрим НЕ инвалидируется при изменении настроек.
    final KodiSettingsState kodiSettings = ref.read(kodiSettingsProvider);
    final SettingsState settings = ref.read(settingsNotifierProvider);

    return ServiceStatus(
      kodiEnabled: kodiSettings.enabled &&
          kodiSettings.hasConnection &&
          kodiSettings.targetCollectionId != null,
      kodiRunning: kodiSync.isRunning,
      kodiSyncing: kodiSync.isSyncing,
      discordEnabled: kDiscordRpcAvailable && settings.discordRpcEnabled,
      discordConnected: discord.isConnected,
      discordRaSyncActive: discord.isRaSyncActive,
    );
  }

  // ignore: close_sinks
  final StreamController<ServiceStatus> controller =
      StreamController<ServiceStatus>();

  // Первый снимок сразу.
  controller.add(snapshot());

  // Polling каждые 2 секунды для обновления runtime-состояния.
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
