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

  @override
  void initState() {
    super.initState();
    _lan = ref.read(lanSyncServiceProvider);
    _start();
  }

  @override
  void dispose() {
    _lan.stop();
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

      final bool confirm = await ConfirmDialog.show(
        context,
        title: l10n.lanSyncReceiveTitle,
        message: l10n.lanSyncReceiveMessage(
          manifest.deviceName,
          _formatDate(manifest.createdAt),
          manifest.collections,
          manifest.items,
        ),
        confirmLabel: l10n.lanSyncReplace,
      );
      if (!confirm || !mounted) return;

      _showProgress(l10n.lanSyncWaiting(peer.name));
      final Directory tmpDir =
          await Directory.systemTemp.createTemp('xerabora_lan_in');
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

      _finish(l10n.lanSyncReceived);
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
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        content: Row(
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  /// Closes the progress dialog and shows the outcome.
  void _finish(String message, {bool error = false}) {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    context.showSnack(
      message,
      type: error ? SnackType.error : SnackType.success,
    );
  }

  String _formatDate(DateTime date) {
    final DateTime local = date.toLocal();
    final MaterialLocalizations material = MaterialLocalizations.of(context);
    return '${material.formatCompactDate(local)} '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }
}
