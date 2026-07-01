import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/services/db_sync_service.dart';
import '../../../core/services/lan_sync_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/models/sync_manifest.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/utils/storage_access.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/sub_screen_title_bar.dart';

/// Direct device-to-device transfer screen.
///
/// While open, this device is discoverable on the local network and can
/// serve its data; tapping a discovered peer pulls that peer's data after
/// confirmations on both sides. The server stops when the screen closes.
class LanSyncScreen extends ConsumerStatefulWidget {
  /// Creates a [LanSyncScreen].
  const LanSyncScreen({super.key});

  @override
  ConsumerState<LanSyncScreen> createState() => _LanSyncScreenState();
}

class _LanSyncScreenState extends ConsumerState<LanSyncScreen> {
  static final Logger _log = Logger('LanSyncScreen');

  // Captured in initState: ref is not usable from dispose().
  late final LanSyncService _lan;

  String? _deviceName;
  bool _busy = false;

  // Live text for the single progress dialog, updated between the database
  // and the image transfer phases.
  final ValueNotifier<String> _progressText = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _lan = ref.read(lanSyncServiceProvider);
    _start();
  }

  @override
  void dispose() {
    _lan.stop();
    _progressText.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final SyncDeviceMeta meta =
        await ref.read(dbSyncServiceProvider).deviceMeta();
    if (!mounted) return;
    setState(() => _deviceName = meta.deviceName);
    await _lan.start(
      deviceName: meta.deviceName,
      onSnapshotRequest: _onIncomingRequest,
    );
  }

  Future<bool> _onIncomingRequest(String requesterName) async {
    if (!mounted) return false;
    final S l10n = S.of(context);
    return ConfirmDialog.show(
      context,
      title: l10n.lanSyncIncomingTitle,
      message: l10n.lanSyncIncomingMessage(requesterName),
      confirmLabel: l10n.lanSyncAllow,
      destructive: false,
    );
  }

  /// Receive confirmation with an optional "also transfer settings" toggle.
  /// The toggle only appears when the peer is new enough to serve its config;
  /// it is all-or-nothing (settings + API keys together) and on by default.
  Future<_ReceiveChoice?> _askReceiveOptions(SyncManifest manifest) async {
    final S l10n = S.of(context);
    final bool canTransferSettings = manifest.supportsSettingsTransfer;
    bool includeSettings = true;
    return showDialog<_ReceiveChoice>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setLocal) {
            return AlertDialog(
              title: Text(l10n.lanSyncReceiveTitle),
              scrollable: true,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l10n.lanSyncReceiveMessage(
                    manifest.deviceName,
                    _formatDate(manifest.createdAt),
                    manifest.collections,
                    manifest.items,
                  )),
                  if (canTransferSettings) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    CheckboxListTile(
                      value: includeSettings,
                      onChanged: (bool? value) =>
                          setLocal(() => includeSettings = value ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(l10n.lanSyncImportConfig),
                      subtitle: Text(l10n.lanSyncImportConfigSubtitle),
                    ),
                  ],
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(
                    _ReceiveChoice(
                      includeSettings: canTransferSettings && includeSettings,
                    ),
                  ),
                  child: Text(l10n.lanSyncReplace),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final S l10n = S.of(context);
    final LanSyncService lan = ref.watch(lanSyncServiceProvider);

    return Column(
      children: <Widget>[
        SubScreenTitleBar(title: l10n.lanSyncTitle),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.lanSyncVisibleAs(_deviceName ?? '...'),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (!kIsMobile) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.lanSyncFirewallNote,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<List<LanPeer>>(
            valueListenable: lan.peers,
            builder: (
              BuildContext context,
              List<LanPeer> peers,
              Widget? child,
            ) {
              if (peers.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.lanSyncNoDevices,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                itemCount: peers.length,
                itemBuilder: (BuildContext context, int index) {
                  final LanPeer peer = peers[index];
                  return ListTile(
                    leading: const Icon(Icons.devices),
                    title: Text(peer.name),
                    subtitle: Text(l10n.lanSyncPull),
                    enabled: !_busy,
                    onTap: () => _pull(peer),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _pull(LanPeer peer) async {
    final S l10n = S.of(context);
    final LanSyncService lan = ref.read(lanSyncServiceProvider);
    final DbSyncService dbSync = ref.read(dbSyncServiceProvider);

    setState(() => _busy = true);
    try {
      final SyncManifest? manifest = await lan.fetchManifest(peer);
      if (!mounted) return;
      if (manifest == null) {
        context.showSnack(l10n.lanSyncManifestError, type: SnackType.error);
        return;
      }

      final _ReceiveChoice? choice = await _askReceiveOptions(manifest);
      if (choice == null || !mounted) return;

      bool imagesFailed = false;
      _showProgress(l10n.lanSyncWaiting(peer.name));
      final Directory tmpDir =
          await Directory.systemTemp.createTemp('tonkatsu_box_lan_in');
      try {
        await lan.downloadSnapshot(
          peer,
          tmpDir.path,
          requesterName: _deviceName ?? '',
        );

        final SyncSnapshotInfo info =
            await dbSync.inspectSnapshot(tmpDir.path);
        if (info.tooNew) {
          _finish(l10n.lanSyncTooNew, error: true);
          return;
        }
        if (!info.receivable) {
          _finish(l10n.lanSyncCorrupted, error: true);
          return;
        }

        await dbSync.receiveSnapshot(tmpDir.path);

        // Settings + API keys ride along when opted in. All-or-nothing and
        // best-effort: written straight to prefs and picked up on the
        // restart that the received database requires anyway, so a failure
        // here is logged, not surfaced as a hard error.
        if (choice.includeSettings) {
          _updateProgress(l10n.lanSyncReceivingSettings);
          try {
            await lan.downloadConfig(peer);
          } on Exception catch (e) {
            _log.warning('LAN config pull failed (database received)', e);
          }
        }

        // Step 2: user images. The database is already swapped in, so a
        // failure here is a warning, not a rollback.
        _updateProgress(l10n.lanSyncReceivingImages);
        try {
          await lan.downloadUserImages(peer);
        } on Exception catch (e) {
          _log.warning('LAN image pull failed (database already received)', e);
          imagesFailed = true;
        }
      } on StateError catch (e) {
        _log.warning('LAN pull failed', e);
        _finish(
          e.message == LanSyncService.deniedMessage
              ? l10n.lanSyncDenied
              : l10n.lanSyncReceiveError,
          error: true,
        );
        return;
      } on Exception catch (e) {
        _log.warning('LAN pull failed', e);
        _finish(l10n.lanSyncReceiveError, error: true);
        return;
      } finally {
        if (tmpDir.existsSync()) {
          await tmpDir.delete(recursive: true);
        }
      }

      _finish(
        imagesFailed ? l10n.lanSyncImagesWarning : l10n.lanSyncReceived,
        type: imagesFailed ? SnackType.info : SnackType.success,
      );
      if (!mounted) return;
      await offerAppRestart(
        context,
        ref,
        title: l10n.storageLocationRestartTitle,
        message: l10n.lanSyncRestartMessage,
        laterMessage: l10n.storageLocationRestartLater,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showProgress(String message) {
    _progressText.value = message;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        content: Row(
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: _progressText,
                builder: (BuildContext context, String text, Widget? _) =>
                    Text(text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateProgress(String message) => _progressText.value = message;

  /// Closes the progress dialog and shows the outcome.
  void _finish(String message, {bool error = false, SnackType? type}) {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    context.showSnack(
      message,
      type: type ?? (error ? SnackType.error : SnackType.success),
    );
  }

  String _formatDate(DateTime date) {
    final DateTime local = date.toLocal();
    final MaterialLocalizations material = MaterialLocalizations.of(context);
    return '${material.formatCompactDate(local)} '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }
}

/// Outcome of the receive confirmation dialog.
class _ReceiveChoice {
  const _ReceiveChoice({required this.includeSettings});

  /// Whether to also pull the peer's settings + API keys after the database.
  final bool includeSettings;
}
